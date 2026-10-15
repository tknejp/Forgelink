import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../core/sync_issue.dart';
import '../../sheets/google_auth.dart';
import '../../sync/integration_status.dart';

/// State of Settings → Google účet.
class GoogleController extends ChangeNotifier {
  GoogleController(this._auth, this._statusStore);

  final GoogleAuth _auth;
  final IntegrationStatusStore _statusStore;

  String? email;
  SyncIssue? lastIssue;
  bool busy = false;

  IntegrationStatus get status => email == null
      ? const IntegrationStatus(
          IntegrationState.notConfigured, GoogleNotConnected())
      : IntegrationStatus.configured;

  Future<void> load() async {
    email = await _auth.accountEmail();
    notifyListeners();
  }

  Future<void> connect() async {
    if (busy) return;
    busy = true;
    lastIssue = null;
    notifyListeners();
    try {
      final connected = await _auth.connect();
      // A new account invalidates whatever was proven for the sheet.
      if (connected != null) await _statusStore.clear(Integration.googleSheets);
    } on SyncIssueException catch (e) {
      lastIssue = e.issue;
    } catch (e, st) {
      AppLog.auth.error('Google connect failed', err: e, stackTrace: st);
      lastIssue = const UnexpectedIssue();
    } finally {
      busy = false;
      await load();
    }
  }

  Future<void> disconnect() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await _auth.disconnect();
      await _statusStore.clear(Integration.googleSheets);
    } finally {
      busy = false;
      lastIssue = null;
      await load();
    }
  }
}
