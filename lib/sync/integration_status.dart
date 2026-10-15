import 'package:meta/meta.dart';

import '../core/prefs_store.dart';
import '../core/sync_issue.dart';

/// The three integrations shown in the status strip and Settings.
enum Integration { healthConnect, kt, googleSheets }

/// docs/implementation_plan.md §7. `readVerified` is used by Google Sheets only.
enum IntegrationState { notConfigured, configured, readVerified, verified, error }

@immutable
class IntegrationStatus {
  final IntegrationState state;

  /// Set when [state] is [IntegrationState.error] (or a not-configured state
  /// with a known reason).
  final SyncIssue? issue;

  const IntegrationStatus(this.state, [this.issue]);

  static const notConfigured = IntegrationStatus(IntegrationState.notConfigured);
  static const configured = IntegrationStatus(IntegrationState.configured);
  static const verified = IntegrationStatus(IntegrationState.verified);

  @override
  bool operator ==(Object other) =>
      other is IntegrationStatus &&
      other.state == state &&
      other.issue?.code == issue?.code;

  @override
  int get hashCode => Object.hash(state, issue?.code);

  @override
  String toString() => 'IntegrationStatus($state, ${issue?.code})';
}

/// Persists the proven state of each integration (`verified` / `error`), so
/// it survives restarts and can be written by the Phase 6 worker. Live,
/// local checks (e.g. Health Connect permissions) are combined with this by
/// the callers.
class IntegrationStatusStore {
  IntegrationStatusStore(this._prefs);

  final PrefsStore _prefs;

  Future<IntegrationStatus?> load(Integration integration) async {
    final raw = await _prefs.integrationStatusRaw(integration.name);
    if (raw == null) return null;
    final parts = raw.split('|');
    final state = IntegrationState.values
        .where((s) => s.name == parts.first)
        .firstOrNull;
    if (state == null) return null;
    final issue = parts.length > 1 && parts[1].isNotEmpty
        ? SyncIssue.parameterlessFromCode(parts[1])
        : null;
    return IntegrationStatus(state, issue);
  }

  Future<void> save(Integration integration, IntegrationStatus status) =>
      _prefs.setIntegrationStatusRaw(
        integration.name,
        '${status.state.name}|${status.issue?.code ?? ''}',
      );

  Future<void> clear(Integration integration) =>
      _prefs.setIntegrationStatusRaw(integration.name, null);
}
