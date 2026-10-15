import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../core/sync_issue.dart';
import '../../sources/kt/kt_client.dart';
import '../../sync/integration_status.dart';

/// State of Settings → Kalorické tabulky.
class KtController extends ChangeNotifier {
  KtController(this._client, this._statusStore);

  final KtClient _client;
  final IntegrationStatusStore _statusStore;

  String? storedEmail;
  IntegrationStatus status = IntegrationStatus.notConfigured;

  /// Result of the last login attempt that didn't change the stored state
  /// (e.g. offline). Shown under the form, cleared on the next attempt.
  SyncIssue? lastAttemptIssue;
  bool busy = false;

  Future<void> load() async {
    storedEmail = await _client.storedEmail();
    if (storedEmail == null || !await _client.hasStoredCredentials()) {
      status = IntegrationStatus.notConfigured;
    } else {
      status = await _statusStore.load(Integration.kt) ??
          IntegrationStatus.configured;
    }
    notifyListeners();
  }

  /// Logs in and stores the credentials only when KT accepts them.
  Future<bool> login(String email, String password) async {
    if (busy) return false;
    busy = true;
    lastAttemptIssue = null;
    notifyListeners();
    try {
      await _client.login(email.trim(), password);
      await _statusStore.save(Integration.kt, IntegrationStatus.verified);
      return true;
    } on KtNetworkException {
      lastAttemptIssue = const Offline();
      return false;
    } on KtAuthException {
      lastAttemptIssue = const KtAuthRejected();
      return false;
    } on KtApiException {
      lastAttemptIssue = const KtUnavailable();
      return false;
    } catch (e, st) {
      AppLog.kt.error('KT login failed unexpectedly', err: e, stackTrace: st);
      lastAttemptIssue = const UnexpectedIssue();
      return false;
    } finally {
      busy = false;
      await load();
    }
  }

  Future<void> logout() async {
    await _client.logout();
    await _statusStore.clear(Integration.kt);
    lastAttemptIssue = null;
    await load();
  }
}
