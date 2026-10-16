part of 'kt_client.dart';

// Ported from Forgetrack kt_session_client.dart. Changes: storage is required
// (the app's SecureStore instance, resetOnError: false), network failures throw
// KtNetworkException, every request has a timeout, emails are masked through
// core maskEmail.
class _KtSessionClient {
  http.Client _client;
  final bool _ownsClient;
  final FlutterSecureStorage _storage;

  String? _cookieHeader;
  bool _loggedIn = false;

  _KtSessionClient({required FlutterSecureStorage storage, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _storage = storage;

  /// Disposes the current keep-alive pool and creates a fresh client.
  /// No-op when the client was injected (tests) — they manage lifecycle.
  void _resetClient() {
    if (!_ownsClient) return;
    AppLog.ktApi.warn(
      'Resetting HTTP client — likely stale keep-alive socket after network change',
    );
    try {
      _client.close();
    } catch (_) {
      // Closing a client that's already disposed is fine.
    }
    _client = http.Client();
  }

  /// True for errors that typically indicate a pooled TLS socket bound to a
  /// network interface that no longer exists (Wi-Fi -> mobile data hand-off,
  /// VPN drop, sleep wake-up). The cure is to drop the pool and reconnect.
  bool _isStaleConnectionError(Object e) {
    if (e is SocketException) return true;
    if (e is HandshakeException) return true;
    if (e is http.ClientException) {
      final msg = e.message.toLowerCase();
      return msg.contains('connection closed') ||
          msg.contains('connection reset') ||
          msg.contains('connection abort') ||
          msg.contains('broken pipe');
    }
    return false;
  }

  bool get isLoggedIn => _loggedIn;

  Future<void> login(String email, String password) async {
    AppLog.ktApi.info('login() called for ${maskEmail(email)}');

    final passwordHash = md5.convert(utf8.encode(password)).toString();
    await _performLogin(email, passwordHash);

    await _storage.write(key: _ktEmailKey, value: email);
    await _storage.write(key: _ktPasswordHashKey, value: passwordHash);

    AppLog.ktApi.success('Credentials stored for ${maskEmail(email)}');
  }

  Future<bool> restoreSession() async {
    final email = await _storage.read(key: _ktEmailKey);
    final passwordHash = await _storage.read(key: _ktPasswordHashKey);

    if (email == null || passwordHash == null) {
      AppLog.ktApi.info('No stored KT credentials found');
      return false;
    }

    await _performLogin(email, passwordHash);
    return true;
  }

  /// Re-runs `/login/create` with the stored email + hash to refresh the
  /// session cookie. KT has no OAuth/JWT refresh endpoint; re-POSTing
  /// login with the stored hash IS the refresh mechanism. Returns
  /// `false` when no stored credentials exist. Throws [KtAuthException]
  /// when KT rejects the credentials and [KtNetworkException] /
  /// [KtApiException] on transport or server failure.
  Future<bool> refreshSession() async {
    final email = await _storage.read(key: _ktEmailKey);
    final passwordHash = await _storage.read(key: _ktPasswordHashKey);

    if (email == null || passwordHash == null) {
      AppLog.ktApi.warn('refreshSession() — no stored credentials');
      return false;
    }

    invalidateSession();
    await _performLogin(email, passwordHash);
    AppLog.ktApi.success('refreshSession() OK for ${maskEmail(email)}');
    return true;
  }

  Future<String?> storedEmail() => _storage.read(key: _ktEmailKey);

  Future<bool> hasStoredCredentials() async =>
      await _storage.read(key: _ktEmailKey) != null &&
      await _storage.read(key: _ktPasswordHashKey) != null;

  Future<void> logout() async {
    AppLog.ktApi.info('logout() called');

    _cookieHeader = null;
    _loggedIn = false;
    await _storage.delete(key: _ktEmailKey);
    await _storage.delete(key: _ktPasswordHashKey);
  }

  void invalidateSession() {
    _cookieHeader = null;
    _loggedIn = false;
  }

  /// Runs [send]; on a stale-socket error resets the pool and retries once.
  /// Any transport failure ends as [KtNetworkException].
  Future<http.Response> _withNetworkRetry(
    String label,
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(_requestTimeout);
    } catch (e) {
      if (_isStaleConnectionError(e)) {
        AppLog.ktApi.warn(
          '$label: network error looks like stale socket — resetting client and retrying once',
          payload: '$e',
        );
        _resetClient();
        try {
          return await send().timeout(_requestTimeout);
        } catch (e2, st2) {
          AppLog.ktApi.error(
            '$label: network error (after retry)',
            err: e2,
            stackTrace: st2,
          );
          throw KtNetworkException('Network error during $label: $e2');
        }
      }
      if (e is TimeoutException ||
          e is SocketException ||
          e is HandshakeException ||
          e is http.ClientException) {
        AppLog.ktApi.error('$label: network error', err: e);
        throw KtNetworkException('Network error during $label: $e');
      }
      rethrow;
    }
  }

  Future<void> _performLogin(String email, String passwordHash) async {
    AppLog.ktApi.debug('Performing KT login for ${maskEmail(email)}');

    final loginUri = Uri.parse(
      '${AppConfig.ktBaseUrl}/login/create?=&format=json',
    );
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final loginPayload = jsonEncode({'email': email, 'password': passwordHash});

    final response = await _withNetworkRetry(
      'login',
      () => _client.post(loginUri, headers: headers, body: loginPayload),
    );

    AppLog.ktApi.debug(
      'Login HTTP response: status=${response.statusCode}',
      payload: _shortBody(response.body),
    );

    if (response.statusCode != 200) {
      AppLog.ktApi.error('Login failed with HTTP ${response.statusCode}');
      throw KtApiException('Login failed with HTTP ${response.statusCode}');
    }

    final body = decodeJson(response.body, context: 'login');

    if (body['code'] != 0) {
      final message = (body['message'] ?? 'Invalid credentials').toString();
      AppLog.ktApi.warn('Login rejected for ${maskEmail(email)}: $message');
      throw KtAuthException(message);
    }

    _cookieHeader = _extractCookies(response);
    _loggedIn = true;

    AppLog.ktApi.success(
      'Login OK for ${maskEmail(email)}',
      payload:
          'cookiesPresent=${_cookieHeader != null && _cookieHeader!.isNotEmpty}',
    );
  }

  void assertLoggedIn() {
    if (!_loggedIn) {
      throw const KtAuthException('Not logged in');
    }
  }

  Future<http.Response> get(String url) async {
    final requestHeaders = buildGetHeaders();
    final uri = Uri.parse(url);

    final response = await _withNetworkRetry(
      'GET',
      () => _client.get(uri, headers: requestHeaders),
    );

    AppLog.ktApi.debug(
      'GET $url → ${response.statusCode}',
      payload: _shortBody(response.body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      invalidateSession();
      AppLog.ktApi.warn(
        'Session expired — HTTP ${response.statusCode} for $url',
      );
      throw const KtAuthException('Session expired');
    }

    if (response.statusCode != 200) {
      AppLog.ktApi.error('GET failed: HTTP ${response.statusCode} for $url');
      throw KtApiException('HTTP ${response.statusCode}');
    }

    return response;
  }

  Map<String, String> buildGetHeaders() {
    final headers = <String, String>{'Accept': 'application/json'};

    if (_cookieHeader != null && _cookieHeader!.isNotEmpty) {
      headers['Cookie'] = _cookieHeader!;
    }

    return headers;
  }

  Map<String, dynamic> decodeJson(String body, {required String context}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object');
      }
      return decoded;
    } catch (e, st) {
      AppLog.ktParse.error(
        'Invalid JSON from API ($context)',
        payload: 'body=${_shortBody(body)}',
        err: e,
        stackTrace: st,
      );
      throw KtApiException('Invalid JSON from API ($context)');
    }
  }

  String? _extractCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      AppLog.ktApi.warn('No set-cookie header found in login response');
      return null;
    }

    final cookies = setCookie
        .split(RegExp(r',\s*(?=[A-Za-z0-9_\-]+=)'))
        .map((cookie) => cookie.trim().split(';').first.trim())
        .where((cookie) => cookie.contains('='))
        .join('; ');

    return cookies.isNotEmpty ? cookies : null;
  }
}
