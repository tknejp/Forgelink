import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';

/// Supplies access tokens for the Sheets API. Phase 6 may add a
/// refresh-token implementation (Strategy B) behind the same interface.
abstract interface class TokenProvider {
  /// The pinned account's email, or null when no account is connected.
  Future<String?> accountEmail();

  /// Access token for the `spreadsheets` scope. [interactive] allows UI
  /// (foreground only). Throws [SyncIssueException] with
  /// [GoogleNotConnected] / [GoogleReauthRequired] / [UnexpectedIssue].
  Future<String> accessToken({required bool interactive});

  /// Drops [token] from Play services' cache (after a 401 invalid_token).
  Future<void> invalidate(String token);
}

/// Google account handling (plan §11 connect flow, §4 step 3).
///
/// The account is pinned at connect time and every later token request names
/// it explicitly, so a multi-account phone can never hand back a token for a
/// different account.
class GoogleAuth implements TokenProvider {
  GoogleAuth(this._prefs, {GoogleSignIn? signIn}) : _signIn = signIn;

  final PrefsStore _prefs;
  final GoogleSignIn? _signIn;
  Future<void>? _init;

  GoogleSignIn get _gsi => _signIn ?? GoogleSignIn.instance;

  static const _scopes = [AppConfig.sheetsScope];

  /// Must run once per isolate before any other call.
  Future<void> initialize() => _init ??= _gsi.initialize(
        serverClientId: AppConfig.googleWebClientId.isEmpty
            ? null
            : AppConfig.googleWebClientId,
      );

  @override
  Future<String?> accountEmail() async => (await _prefs.googleAccount())?.email;

  /// Interactive connect: account picker, pin the account, grant the scope.
  /// Returns the email, or null when the user cancelled.
  Future<String?> connect() async {
    await initialize();
    try {
      final account = await _gsi.authenticate();
      await account.authorizationClient.authorizeScopes(_scopes);
      await _prefs.setGoogleAccount(email: account.email, userId: account.id);
      AppLog.auth.success('Google account connected: ${maskEmail(account.email)}');
      return account.email;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLog.auth.info('Google connect cancelled by user');
        return null;
      }
      AppLog.auth.error('Google connect failed',
          payload: '${e.code}: ${e.description}', err: e);
      throw SyncIssueException(const UnexpectedIssue(), e);
    }
  }

  /// Revokes the grant and forgets the pinned account.
  Future<void> disconnect() async {
    await initialize();
    try {
      await _gsi.disconnect();
    } catch (e) {
      // Still forget the account locally; the user asked to disconnect.
      AppLog.auth.warn('Google disconnect failed', payload: '$e');
    }
    await _prefs.clearGoogleAccount();
  }

  @override
  Future<String> accessToken({required bool interactive}) async {
    await initialize();
    final account = await _prefs.googleAccount();
    if (account == null) {
      throw const SyncIssueException(GoogleNotConnected());
    }

    Future<ClientAuthorizationTokenData?> request(bool prompt) =>
        GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters(
            request: AuthorizationRequestDetails(
              scopes: _scopes,
              userId: account.userId,
              email: account.email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );

    try {
      var tokens = await request(false);
      if (tokens == null && interactive) tokens = await request(true);
      if (tokens == null) {
        AppLog.auth.warn('No token for ${maskEmail(account.email)} '
            '(interactive=$interactive)');
        throw const SyncIssueException(GoogleReauthRequired());
      }
      return tokens.accessToken;
    } on GoogleSignInException catch (e) {
      final issue = switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.uiUnavailable ||
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.interrupted =>
          const GoogleReauthRequired(),
        _ => const UnexpectedIssue(),
      };
      AppLog.auth.error('Token request failed → ${issue.code}',
          payload: '${e.code}: ${e.description}');
      throw SyncIssueException(issue, e);
    }
  }

  @override
  Future<void> invalidate(String token) =>
      GoogleSignInPlatform.instance.clearAuthorizationToken(
        ClearAuthorizationTokenParams(accessToken: token),
      );
}
