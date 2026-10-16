import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';
import '../core/sync_issue.dart';
import '../core/sync_issue_codec.dart';

/// What started a run.
enum SyncTrigger { quick, calendar, range, background }

/// docs/implementation_plan.md §4 "Outcomes".
enum FieldOutcomeKind { written, unchanged, missing, skippedFormula, failed }

@immutable
class FieldOutcome {
  final FieldOutcomeKind kind;
  final num? value;
  final SyncIssue? issue;

  const FieldOutcome(this.kind, {this.value, this.issue});

  bool get succeeded =>
      kind == FieldOutcomeKind.written || kind == FieldOutcomeKind.unchanged;

  Map<String, Object?> toJson() => {
    'k': kind.name,
    if (value != null) 'v': value,
    if (issue != null) 'i': SyncIssueCodec.encode(issue!),
  };

  static FieldOutcome fromJson(Map<String, Object?> j) => FieldOutcome(
    FieldOutcomeKind.values.firstWhere(
      (k) => k.name == j['k'],
      orElse: () => FieldOutcomeKind.failed,
    ),
    value: j['v'] as num?,
    issue: j['i'] == null
        ? null
        : SyncIssueCodec.decode((j['i'] as Map).cast<String, Object?>()),
  );
}

enum DayStatus { ok, partial, noData, failed }

/// Result for one date.
@immutable
class DayResult {
  final LocalDate date;
  final DayStatus status;

  /// Per field that this run was supposed to handle for the date.
  final Map<SheetColumn, FieldOutcome> fields;

  /// Blocking issue for the whole date (not in sheet, duplicate, layout…).
  final SyncIssue? issue;

  /// Informational notes (e.g. [NoData]).
  final List<SyncIssue> notes;

  const DayResult({
    required this.date,
    required this.status,
    required this.fields,
    this.issue,
    this.notes = const [],
  });

  /// Per-date rule from plan §4: `missing` alone never makes a day partial.
  static DayStatus statusOf(
    Map<SheetColumn, FieldOutcome> fields,
    SyncIssue? issue,
  ) {
    if (issue != null) return DayStatus.failed;
    final kinds = fields.values.map((f) => f.kind).toList();
    final ok = kinds.where(
      (k) => k == FieldOutcomeKind.written || k == FieldOutcomeKind.unchanged,
    );
    final bad = kinds.where(
      (k) =>
          k == FieldOutcomeKind.failed || k == FieldOutcomeKind.skippedFormula,
    );
    if (bad.isNotEmpty) {
      return ok.isEmpty ? DayStatus.failed : DayStatus.partial;
    }
    if (ok.isEmpty) return DayStatus.noData;
    return DayStatus.ok;
  }

  Iterable<SheetColumn> fieldsWhere(bool Function(FieldOutcome) test) =>
      fields.entries.where((e) => test(e.value)).map((e) => e.key);

  Map<String, Object?> toJson() => {
    'd': date.isoKey,
    's': status.name,
    'f': {for (final e in fields.entries) e.key.name: e.value.toJson()},
    if (issue != null) 'i': SyncIssueCodec.encode(issue!),
    if (notes.isNotEmpty)
      'n': [for (final n in notes) SyncIssueCodec.encode(n)],
  };

  static DayResult fromJson(Map<String, Object?> j) => DayResult(
    date: LocalDate.tryParseIso(j['d'] as String) ?? LocalDate(2000, 1, 1),
    status: DayStatus.values.firstWhere(
      (s) => s.name == j['s'],
      orElse: () => DayStatus.failed,
    ),
    fields: {
      for (final e in ((j['f'] as Map?) ?? const {}).entries)
        for (final c in SheetColumn.values)
          if (c.name == e.key)
            c: FieldOutcome.fromJson((e.value as Map).cast()),
    },
    issue: j['i'] == null
        ? null
        : SyncIssueCodec.decode((j['i'] as Map).cast()),
    notes: [
      for (final n in (j['n'] as List? ?? const []))
        SyncIssueCodec.decode((n as Map).cast()),
    ],
  );
}

enum RunStatus { success, noData, partial, failed }

/// Result of one sync run.
@immutable
class RunResult {
  final SyncTrigger trigger;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<DayResult> days;

  /// Run-level / per-source issues (deduplicated), e.g. a missing KT login.
  final List<SyncIssue> issues;

  const RunResult({
    required this.trigger,
    required this.startedAt,
    required this.finishedAt,
    required this.days,
    this.issues = const [],
  });

  /// Per-run rule from plan §4.
  RunStatus get status {
    if (days.isEmpty) return RunStatus.failed;
    final statuses = days.map((d) => d.status).toSet();
    final anyOk = statuses.contains(DayStatus.ok);
    final anyBad =
        statuses.contains(DayStatus.partial) ||
        statuses.contains(DayStatus.failed);
    final anyWritten = days.any((d) => d.fields.values.any((f) => f.succeeded));
    if (!anyBad) return anyOk ? RunStatus.success : RunStatus.noData;
    return anyWritten ? RunStatus.partial : RunStatus.failed;
  }

  /// True when at least one cell was written or confirmed and nothing failed
  /// (plan §7 `lastSuccessAt`).
  bool get countsAsSuccess =>
      days.any((d) => d.fields.values.any((f) => f.succeeded)) &&
      !days.any(
        (d) =>
            d.issue != null ||
            d.fields.values.any((f) => f.kind == FieldOutcomeKind.failed),
      );

  int get cellsWritten => days.fold(
    0,
    (n, d) =>
        n +
        d.fields.values.where((f) => f.kind == FieldOutcomeKind.written).length,
  );

  Map<String, Object?> toJson() => {
    't': trigger.name,
    'a': startedAt.toIso8601String(),
    'b': finishedAt.toIso8601String(),
    'd': [for (final d in days) d.toJson()],
    if (issues.isNotEmpty)
      'i': [for (final i in issues) SyncIssueCodec.encode(i)],
  };

  static RunResult fromJson(Map<String, Object?> j) => RunResult(
    trigger: SyncTrigger.values.firstWhere(
      (t) => t.name == j['t'],
      orElse: () => SyncTrigger.quick,
    ),
    startedAt: DateTime.parse(j['a'] as String),
    finishedAt: DateTime.parse(j['b'] as String),
    days: [
      for (final d in (j['d'] as List? ?? const []))
        DayResult.fromJson((d as Map).cast()),
    ],
    issues: [
      for (final i in (j['i'] as List? ?? const []))
        SyncIssueCodec.decode((i as Map).cast()),
    ],
  );
}

/// Progress of a running sync, for the Home card.
@immutable
class SyncProgress {
  final int done;
  final int total;
  final LocalDate? current;
  const SyncProgress(this.done, this.total, [this.current]);

  double get fraction => total == 0 ? 0 : done / total;
}
