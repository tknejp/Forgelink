import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../core/app_config.dart';
import '../../core/app_log.dart';
import '../../core/local_date.dart';

// Ported from Forgetrack lib/features/nutrition/data/kaloricke_tabulky_service.dart
// (+ part files). Trimmed to login/session + the one-request-per-day summary
// endpoint; every macro is nullable so an absent value is never written as 0.

part 'kt_session_client.dart';
part 'kt_summary_parser.dart';
part 'kt_formatter.dart';

const _ktEmailKey = 'kt_email';
const _ktPasswordHashKey = 'kt_pwd_hash';
const _requestTimeout = Duration(seconds: 20);

/// KT rejected the credentials or the session is no longer valid.
class KtAuthException implements Exception {
  final String message;
  const KtAuthException(this.message);

  @override
  String toString() => 'KtAuthException: $message';
}

/// KT returned an error, an unexpected status or unparsable JSON.
class KtApiException implements Exception {
  final String message;
  const KtApiException(this.message);

  @override
  String toString() => 'KtApiException: $message';
}

/// The request never reached KT (socket, DNS, TLS, timeout). Surfaces as
/// "offline" rather than "KT is down".
class KtNetworkException extends KtApiException {
  const KtNetworkException(super.message);

  @override
  String toString() => 'KtNetworkException: $message';
}

/// One day of nutrition from the KT diary summary. A `null` field means KT
/// did not report that value — it must never be written as 0.
@immutable
class KtDayNutrition {
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;

  const KtDayNutrition({
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  /// False for an empty day (nothing logged): skip all KT columns.
  bool get hasData => (kcal ?? 0) > 0 || (protein ?? 0) > 0;

  @override
  String toString() =>
      'KtDayNutrition(kcal=$kcal, P=$protein, C=$carbs, '
      'F=$fat, fiber=$fiber, hasData=$hasData)';
}

class KtClient {
  KtClient({required FlutterSecureStorage storage, http.Client? client})
    : _session = _KtSessionClient(storage: storage, client: client);

  final _KtSessionClient _session;
  final _parser = const _KtSummaryParser();

  bool get isLoggedIn => _session.isLoggedIn;

  /// Logs in and, only on success, stores email + MD5 hash.
  Future<void> login(String email, String password) =>
      _session.login(email, password);

  /// Logs in with stored credentials. False when none are stored.
  Future<bool> restoreSession() => _session.restoreSession();

  /// Re-runs login with the stored hash (KT's only refresh mechanism).
  Future<bool> refreshSession() => _session.refreshSession();

  Future<String?> storedEmail() => _session.storedEmail();

  Future<bool> hasStoredCredentials() => _session.hasStoredCredentials();

  /// Clears the session and the stored credentials. Only ever called on an
  /// explicit user action — never automatically on an auth failure.
  Future<void> logout() => _session.logout();

  /// GET /user/diary/summary/{dd.MM.yyyy}/get — kcal + protein, carbs, fat,
  /// fiber in one request.
  Future<KtDayNutrition> fetchDaySummary(LocalDate date) async {
    _session.assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    final response = await _session.get(
      '${AppConfig.ktBaseUrl}/user/diary/summary/$dateString/get?format=json',
    );

    final body = _session.decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    if (code != 0 && code != null) {
      AppLog.ktApi.error(
        'Day summary failed for $dateString',
        payload: 'code=$code, message=$message',
      );
      throw KtApiException(
        'KT diary summary failed: code=$code'
        '${message.isNotEmpty ? ', message=$message' : ''}',
      );
    }

    final data = body['data'];
    // Sanity check (plan §3): a "success" without any of the expected keys
    // looks like an expired session, not an empty day.
    if (data is! Map<String, dynamic> ||
        (!data.containsKey('foodstuffEnergyTotal') &&
            !data.containsKey('items') &&
            !data.containsKey('itemsDynamic'))) {
      AppLog.ktApi.warn(
        'Day summary for $dateString has no expected keys — treating as invalid session',
        payload: data is Map ? 'keys=${_previewKeys(data.keys)}' : 'data=$data',
      );
      _session.invalidateSession();
      throw const KtAuthException('Summary response without data');
    }

    final parsed = _parser.parse(data);
    AppLog.ktApi.success(
      'Day summary loaded for $dateString',
      payload: parsed.toString(),
    );
    return parsed;
  }
}
