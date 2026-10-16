import 'dart:convert';

import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';
import '../core/sync_issue_codec.dart';
import 'integration_status.dart';
import 'sync_models.dart';

/// Which part of the system an issue belongs to — used to clear open issues
/// once a later run proves that part works again.
enum IssueArea { kt, healthConnect, sheets, general, date }

IssueArea areaOf(SyncIssue i) => switch (i) {
  KtCredentialsMissing() || KtAuthRejected() || KtUnavailable() => IssueArea.kt,
  HcNotAvailable() ||
  HcPermissionMissing() ||
  HcHistoryPermissionMissing() ||
  HcBackgroundPermissionMissing() ||
  HcReadFailed() => IssueArea.healthConnect,
  GoogleNotConnected() ||
  GoogleReauthRequired() ||
  SheetNotConfigured() ||
  SheetNotFound() ||
  SheetNoEditAccess() ||
  SheetsApiDisabled() ||
  SheetTabMissing() ||
  SheetLayoutChanged() ||
  SheetsUnavailable() => IssueArea.sheets,
  Offline() || UnexpectedIssue() => IssueArea.general,
  DateNotInSheet() ||
  DateDuplicated() ||
  CellHasFormula() ||
  NoData() => IssueArea.date,
};

@immutable
class LastSuccess {
  final DateTime at;
  final SyncTrigger trigger;
  const LastSuccess(this.at, this.trigger);
}

/// Persisted sync state: run log, per-date status, open issues, last success
/// (docs/implementation_plan.md §5 storage, §6 open issues, §7).
class SyncHistory {
  SyncHistory(this._prefs, this._statusStore);

  final PrefsStore _prefs;
  final IntegrationStatusStore _statusStore;

  static const _kRuns = 'history.runs';
  static const _kDays = 'history.days';
  static const _kOpen = 'history.open_issues';
  static const _kLastSuccess = 'history.last_success';
  static const maxRuns = 50;
  static const maxDays = 400;

  // ─── Reads ──────────────────────────────────────────────────────────────

  Future<List<RunResult>> runs() async {
    final raw = await _prefs.rawString(_kRuns);
    if (raw == null) return const [];
    try {
      return [
        for (final r in jsonDecode(raw) as List)
          RunResult.fromJson((r as Map).cast()),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<Map<LocalDate, DayResult>> days() async {
    final raw = await _prefs.rawString(_kDays);
    if (raw == null) return const {};
    try {
      final map = (jsonDecode(raw) as Map).cast<String, Object?>();
      return {
        for (final e in map.entries)
          ?LocalDate.tryParseIso(e.key): DayResult.fromJson(
            (e.value as Map).cast(),
          ),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<List<SyncIssue>> openIssues() async {
    final raw = await _prefs.rawString(_kOpen);
    if (raw == null) return const [];
    try {
      return [
        for (final i in jsonDecode(raw) as List)
          SyncIssueCodec.decode((i as Map).cast()),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<LastSuccess?> lastSuccess() async {
    final raw = await _prefs.rawString(_kLastSuccess);
    if (raw == null) return null;
    final parts = raw.split('|');
    final at = DateTime.tryParse(parts.first);
    if (at == null) return null;
    final trigger =
        SyncTrigger.values
            .where((t) => parts.length > 1 && t.name == parts[1])
            .firstOrNull ??
        SyncTrigger.quick;
    return LastSuccess(at, trigger);
  }

  // ─── Record a run ───────────────────────────────────────────────────────

  Future<void> record(RunResult run) async {
    final runs = [run, ...await this.runs()].take(maxRuns).toList();
    await _prefs.setRawString(
      _kRuns,
      jsonEncode([for (final r in runs) r.toJson()]),
    );

    final days = Map.of(await this.days());
    for (final d in run.days) {
      days[d.date] = d;
    }
    final keep = (days.keys.toList()..sort()).reversed.take(maxDays).toSet();
    days.removeWhere((k, _) => !keep.contains(k));
    await _prefs.setRawString(
      _kDays,
      jsonEncode({
        for (final e in days.entries) e.key.isoKey: e.value.toJson(),
      }),
    );

    if (run.countsAsSuccess) {
      await _prefs.setRawString(
        _kLastSuccess,
        '${run.finishedAt.toIso8601String()}|${run.trigger.name}',
      );
    }

    await _updateOpenIssues(run);
    await _updateIntegrationStatus(run);
  }

  Future<void> dismiss(SyncIssue issue) async {
    final open = (await openIssues())
        .where((i) => i.code != issue.code)
        .toList();
    await _saveOpen(open);
  }

  /// Areas proven healthy by [run]: some field of that source succeeded
  /// (KT / HC), or anything was written/confirmed (sheets, general).
  static Set<IssueArea> provenAreas(RunResult run) {
    final proven = <IssueArea>{};
    for (final d in run.days) {
      for (final e in d.fields.entries) {
        if (!e.value.succeeded) continue;
        proven.add(IssueArea.sheets);
        proven.add(IssueArea.general);
        if (e.key == SheetColumn.weight || e.key == SheetColumn.steps) {
          proven.add(IssueArea.healthConnect);
        } else {
          proven.add(IssueArea.kt);
        }
      }
    }
    return proven;
  }

  Future<void> _updateOpenIssues(RunResult run) async {
    final proven = provenAreas(run);
    final open = (await openIssues())
        .where((i) => !proven.contains(areaOf(i)))
        .toList();
    for (final i in run.issues) {
      if (areaOf(i) == IssueArea.date) continue;
      if (open.any((o) => o.code == i.code)) {
        open.removeWhere((o) => o.code == i.code);
      }
      open.add(i);
    }
    await _saveOpen(open);
  }

  Future<void> _saveOpen(List<SyncIssue> open) => _prefs.setRawString(
    _kOpen,
    jsonEncode([for (final i in open) SyncIssueCodec.encode(i)]),
  );

  Future<void> _updateIntegrationStatus(RunResult run) async {
    final proven = provenAreas(run);
    final written = run.days.any(
      (d) => d.fields.values.any((f) => f.kind == FieldOutcomeKind.written),
    );

    if (written) {
      await _statusStore.save(
        Integration.googleSheets,
        IntegrationStatus.verified,
      );
    }
    if (proven.contains(IssueArea.kt)) {
      await _statusStore.save(Integration.kt, IntegrationStatus.verified);
    }

    for (final i in run.issues) {
      switch (areaOf(i)) {
        case IssueArea.sheets when i is! SheetsUnavailable:
          await _statusStore.save(
            Integration.googleSheets,
            IntegrationStatus(IntegrationState.error, i),
          );
        case IssueArea.kt when i is KtAuthRejected:
          await _statusStore.save(
            Integration.kt,
            IntegrationStatus(IntegrationState.error, i),
          );
        default:
          break;
      }
    }
  }
}
