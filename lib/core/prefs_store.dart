import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'local_date.dart';

/// Typed access to non-secret persisted state.
///
/// Uses `SharedPreferencesAsync` (no per-isolate cache), so values written by
/// the Phase 6 background worker are visible to the UI isolate on the next read.
class PrefsStore {
  PrefsStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _kSpreadsheetId = 'sheet.spreadsheet_id';
  static const _kSheetTab = 'sheet.tab';
  static const _kGoogleEmail = 'google.email';
  static const _kGoogleUserId = 'google.user_id';
  static const _kAutoSync = 'sync.auto_enabled';
  static const _kHcFirstGrantDate = 'hc.first_grant_date';
  static const _kLogLines = 'diag.log_lines';

  // ─── Destination sheet ──────────────────────────────────────────────────

  Future<String?> spreadsheetId() => _prefs.getString(_kSpreadsheetId);

  Future<void> setSpreadsheetId(String? id) => id == null || id.isEmpty
      ? _prefs.remove(_kSpreadsheetId)
      : _prefs.setString(_kSpreadsheetId, id);

  Future<String> sheetTab() async =>
      await _prefs.getString(_kSheetTab) ?? AppConfig.defaultSheetTab;

  Future<void> setSheetTab(String tab) => tab.trim().isEmpty
      ? _prefs.remove(_kSheetTab)
      : _prefs.setString(_kSheetTab, tab.trim());

  // ─── Pinned Google account ──────────────────────────────────────────────

  Future<({String email, String userId})?> googleAccount() async {
    final email = await _prefs.getString(_kGoogleEmail);
    final userId = await _prefs.getString(_kGoogleUserId);
    if (email == null || userId == null) return null;
    return (email: email, userId: userId);
  }

  Future<void> setGoogleAccount({
    required String email,
    required String userId,
  }) async {
    await _prefs.setString(_kGoogleEmail, email);
    await _prefs.setString(_kGoogleUserId, userId);
  }

  Future<void> clearGoogleAccount() async {
    await _prefs.remove(_kGoogleEmail);
    await _prefs.remove(_kGoogleUserId);
  }

  // ─── Sync settings ──────────────────────────────────────────────────────

  Future<bool> autoSync() async => await _prefs.getBool(_kAutoSync) ?? false;

  Future<void> setAutoSync(bool enabled) => _prefs.setBool(_kAutoSync, enabled);

  // ─── Health Connect history window ──────────────────────────────────────

  Future<LocalDate?> hcFirstGrantDate() async {
    final raw = await _prefs.getString(_kHcFirstGrantDate);
    return raw == null ? null : LocalDate.tryParseIso(raw);
  }

  /// Stores [date] only if no first-grant date is recorded yet.
  Future<void> recordHcFirstGrant(LocalDate date) async {
    if (await _prefs.getString(_kHcFirstGrantDate) != null) return;
    await _prefs.setString(_kHcFirstGrantDate, date.isoKey);
  }

  // ─── Integration status (raw; see sync/integration_status.dart) ─────────

  Future<String?> integrationStatusRaw(String integration) =>
      _prefs.getString('status.$integration');

  Future<void> setIntegrationStatusRaw(String integration, String? raw) =>
      raw == null
          ? _prefs.remove('status.$integration')
          : _prefs.setString('status.$integration', raw);

  // ─── Raw JSON blobs (sync/sync_history.dart) ────────────────────────────

  Future<String?> rawString(String key) => _prefs.getString(key);

  Future<void> setRawString(String key, String value) =>
      _prefs.setString(key, value);

  // ─── Diagnostics ────────────────────────────────────────────────────────

  Future<List<String>> logLines() async =>
      await _prefs.getStringList(_kLogLines) ?? const [];

  Future<void> setLogLines(List<String> lines) =>
      _prefs.setStringList(_kLogLines, lines);
}
