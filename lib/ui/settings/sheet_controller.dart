import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../core/local_date.dart';
import '../../core/prefs_store.dart';
import '../../core/sync_issue.dart';
import '../../sheets/google_auth.dart';
import '../../sheets/tracker_sheet.dart';
import '../../sync/integration_status.dart';

/// Result of "Ověřit" — read access only (plan §7).
typedef SheetVerification = ({
  int weekTables,
  int days,
  LocalDate? first,
  LocalDate? last,
  Map<LocalDate, List<int>> duplicates,
});

/// State of Settings → Tabulka.
class SheetController extends ChangeNotifier {
  SheetController(this._prefs, this._sheet, this._tokens, this._statusStore);

  final PrefsStore _prefs;
  final TrackerSheet _sheet;
  final TokenProvider _tokens;
  final IntegrationStatusStore _statusStore;

  String? spreadsheetId;

  /// File name, known after a successful check.
  String? title;
  String tab = '';
  bool googleConnected = false;
  IntegrationStatus? _stored;
  SheetVerification? verification;
  SyncIssue? lastIssue;
  bool invalidInput = false;
  bool busy = false;

  IntegrationStatus get status {
    if (spreadsheetId == null) {
      return const IntegrationStatus(
        IntegrationState.notConfigured,
        SheetNotConfigured(),
      );
    }
    if (!googleConnected) {
      return const IntegrationStatus(
        IntegrationState.notConfigured,
        GoogleNotConnected(),
      );
    }
    return _stored ?? IntegrationStatus.configured;
  }

  Future<void> load() async {
    spreadsheetId = await _prefs.spreadsheetId();
    title = await _prefs.spreadsheetTitle();
    tab = await _prefs.sheetTab();
    googleConnected = await _tokens.accountEmail() != null;
    _stored = await _statusStore.load(Integration.googleSheets);
    notifyListeners();
  }

  /// Saves the destination (URL or bare ID + tab) and verifies read access.
  Future<void> saveAndVerify(String input, String tabInput) async {
    final id = parseSpreadsheetId(input);
    if (id == null) {
      invalidInput = true;
      notifyListeners();
      return;
    }
    invalidInput = false;
    final changed = id != spreadsheetId || tabInput.trim() != tab;
    await _prefs.setSpreadsheetId(id);
    await _prefs.setSheetTab(tabInput);
    if (changed) {
      await _statusStore.clear(Integration.googleSheets);
      await _prefs.setSpreadsheetTitle(null);
      verification = null;
    }
    await load();
    await verify();
  }

  Future<void> verify() async {
    final id = spreadsheetId;
    if (id == null || !googleConnected || busy) return;
    busy = true;
    lastIssue = null;
    notifyListeners();
    try {
      final index = await _sheet.loadIndex(id, tab);
      await _prefs.setSpreadsheetTitle(index.title);
      verification = (
        weekTables: index.weekTables,
        days: index.rows.length,
        first: index.firstDate,
        last: index.lastDate,
        duplicates: index.duplicateRows,
      );
      // Keep a proven write ("verified") — a read check can't downgrade it.
      if (_stored?.state != IntegrationState.verified) {
        await _statusStore.save(
          Integration.googleSheets,
          const IntegrationStatus(IntegrationState.readVerified),
        );
      }
    } on SyncIssueException catch (e) {
      lastIssue = e.issue;
      verification = null;
      await _statusStore.save(
        Integration.googleSheets,
        IntegrationStatus(IntegrationState.error, e.issue),
      );
    } catch (e, st) {
      AppLog.sheets.error('Sheet verify failed', err: e, stackTrace: st);
      lastIssue = const UnexpectedIssue();
    } finally {
      busy = false;
      await load();
    }
  }
}
