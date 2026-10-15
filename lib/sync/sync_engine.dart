import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';
import '../sheets/tracker_index.dart';
import '../sheets/tracker_sheet.dart';
import '../sheets/write_plan.dart';
import '../sources/health/health_source.dart';
import '../sources/kt/kt_source.dart';
import 'sync_models.dart';

const _ktFields = [
  SheetColumn.kcal,
  SheetColumn.protein,
  SheetColumn.carbs,
  SheetColumn.fat,
  SheetColumn.fiber,
];

/// One sync run (docs/implementation_plan.md §4). No Flutter imports, so the
/// Phase 6 worker can run it too.
class SyncEngine {
  SyncEngine({
    required PrefsStore prefs,
    required HealthSource health,
    required KtSource kt,
    required TrackerSheet sheet,
    DateTime Function()? now,
  })  : _prefs = prefs,
        _health = health,
        _kt = kt,
        _sheet = sheet,
        _now = now ?? DateTime.now;

  final PrefsStore _prefs;
  final HealthSource _health;
  final KtSource _kt;
  final TrackerSheet _sheet;
  final DateTime Function() _now;

  /// Fields a date needs: today is weight-only (plan §4 modes).
  Set<SheetColumn> fieldsFor(LocalDate date, LocalDate today) =>
      date == today ? {SheetColumn.weight} : SheetColumn.values.toSet();

  Future<RunResult> run(
    SyncTrigger trigger,
    List<LocalDate> requested, {
    void Function(SyncProgress progress)? onProgress,
  }) async {
    final startedAt = _now();
    final today = LocalDate.fromDateTime(startedAt);
    final dates = (requested.toSet().where((d) => !d.isAfter(today)).toList()
      ..sort());
    AppLog.sync.info('Run ${trigger.name}: ${dates.length} dates',
        payload: dates.isEmpty ? '' : '${dates.first}..${dates.last}');

    RunResult finish(List<DayResult> days, List<SyncIssue> issues) {
      final r = RunResult(
        trigger: trigger,
        startedAt: startedAt,
        finishedAt: _now(),
        days: days,
        issues: _dedupe(issues),
      );
      AppLog.sync.success('Run ${trigger.name} → ${r.status.name}',
          payload: 'days=${days.length}, written=${r.cellsWritten}, '
              'issues=${r.issues.map((i) => i.code).join(',')}');
      return r;
    }

    List<DayResult> failAll(SyncIssue issue) => [
          for (final d in dates)
            DayResult(
              date: d,
              status: DayStatus.failed,
              fields: {
                for (final f in fieldsFor(d, today))
                  f: FieldOutcome(FieldOutcomeKind.failed, issue: issue),
              },
              issue: issue,
            ),
        ];

    // ── 1. Run-blocking preflight (local) ──────────────────────────────────
    final spreadsheetId = await _prefs.spreadsheetId();
    if (spreadsheetId == null) {
      return finish(failAll(const SheetNotConfigured()),
          const [SheetNotConfigured()]);
    }
    if (await _prefs.googleAccount() == null) {
      return finish(failAll(const GoogleNotConnected()),
          const [GoogleNotConnected()]);
    }
    final tab = await _prefs.sheetTab();

    // ── 2. Per-source preflight (local) ────────────────────────────────────
    final needed = {for (final d in dates) ...fieldsFor(d, today)};
    final runIssues = <SyncIssue>[];
    final blocked = <SheetColumn, SyncIssue>{};

    final hcTypes = {
      if (needed.contains(SheetColumn.weight)) HcDataType.weight,
      if (needed.contains(SheetColumn.steps)) HcDataType.steps,
    };
    final hcIssue = await _health.preflight(hcTypes);
    if (hcIssue != null) {
      runIssues.add(hcIssue);
      final affected = hcIssue is HcPermissionMissing ? hcIssue.types : hcTypes;
      if (affected.contains(HcDataType.weight)) {
        blocked[SheetColumn.weight] = hcIssue;
      }
      if (affected.contains(HcDataType.steps)) {
        blocked[SheetColumn.steps] = hcIssue;
      }
    }

    final needKt = _ktFields.any(needed.contains);
    _kt.beginRun();
    if (needKt && !await _kt.hasCredentials()) {
      runIssues.add(const KtCredentialsMissing());
      for (final f in _ktFields) {
        blocked[f] = const KtCredentialsMissing();
      }
    }

    if (needed.every(blocked.containsKey)) {
      return finish(
        [
          for (final d in dates)
            DayResult(
              date: d,
              status: DayStatus.failed,
              fields: {
                for (final f in fieldsFor(d, today))
                  f: FieldOutcome(FieldOutcomeKind.failed, issue: blocked[f]),
              },
            ),
        ],
        runIssues,
      );
    }

    // ── 3. Sheet index (blocking on failure) ───────────────────────────────
    final TrackerIndex index;
    final Map<int, List<Object?>> formulas;
    try {
      index = await _sheet.loadIndex(spreadsheetId, tab);
      formulas = await _sheet.loadFormulas(spreadsheetId, tab, index);
    } on SyncIssueException catch (e) {
      return finish(failAll(e.issue), [...runIssues, e.issue]);
    }

    // ── 4. Fetch sources, date by date ─────────────────────────────────────
    final values = <LocalDate, Map<SheetColumn, num?>>{};
    final failed = <LocalDate, Map<SheetColumn, SyncIssue>>{};
    final notes = <LocalDate, List<SyncIssue>>{};

    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      onProgress?.call(SyncProgress(i, dates.length, date));
      final want = fieldsFor(date, today);
      final v = <SheetColumn, num?>{};
      final f = <SheetColumn, SyncIssue>{
        for (final c in want)
          if (blocked[c] != null) c: blocked[c]!,
      };

      // Skip fetching dates the sheet can't take anyway.
      final writable = index.rows.containsKey(date);

      if (writable) {
        // Health Connect
        final hcWanted = want
            .where((c) => c == SheetColumn.weight || c == SheetColumn.steps)
            .where((c) => !f.containsKey(c))
            .toList();
        if (hcWanted.isNotEmpty) {
          final gate = await _health.historyGate(date);
          if (gate != null) {
            for (final c in hcWanted) {
              f[c] = gate;
            }
            runIssues.add(gate);
          } else {
            for (final c in hcWanted) {
              try {
                v[c] = c == SheetColumn.weight
                    ? await _health.lastWeight(date)
                    : await _health.steps(date);
              } on SyncIssueException catch (e) {
                f[c] = e.issue;
              }
            }
          }
        }

        // Kalorické tabulky
        final ktWanted =
            want.where((c) => _ktFields.contains(c) && !f.containsKey(c));
        if (ktWanted.isNotEmpty) {
          try {
            final n = await _kt.fetchDay(date);
            if (!n.hasData) {
              (notes[date] ??= []).add(NoData(DataSource.kt, date));
            } else {
              v[SheetColumn.kcal] = n.kcal?.round();
              v[SheetColumn.protein] = n.protein?.round();
              v[SheetColumn.carbs] = n.carbs?.round();
              v[SheetColumn.fat] = n.fat?.round();
              v[SheetColumn.fiber] = n.fiber?.round();
            }
          } on SyncIssueException catch (e) {
            // Don't hammer KT for the remaining dates.
            runIssues.add(e.issue);
            for (final c in _ktFields) {
              blocked[c] = e.issue;
              if (want.contains(c)) f[c] = e.issue;
            }
          }
        }
      }

      values[date] = {for (final c in want) c: f.containsKey(c) ? null : v[c]};
      failed[date] = f;
    }
    onProgress?.call(SyncProgress(dates.length, dates.length));

    // ── 5. Plan + write ────────────────────────────────────────────────────
    final plan = buildWritePlan(
        tab: tab, index: index, values: values, formulas: formulas);

    SyncIssue? writeIssue;
    if (plan.hasWrites) {
      try {
        await _sheet.write(spreadsheetId, plan);
      } on SyncIssueException catch (e) {
        writeIssue = e.issue;
        runIssues.add(e.issue);
      }
    }

    // ── 6. Outcomes ────────────────────────────────────────────────────────
    final days = <DayResult>[];
    for (final p in plan.days) {
      final want = fieldsFor(p.date, today);
      if (p.issue != null) {
        days.add(DayResult(
          date: p.date,
          status: DayStatus.failed,
          fields: const {},
          issue: p.issue,
        ));
        continue;
      }
      final f = failed[p.date] ?? const {};
      final fields = <SheetColumn, FieldOutcome>{};
      for (final c in want) {
        final planned = p.fields[c]!;
        if (f[c] != null) {
          fields[c] = FieldOutcome(FieldOutcomeKind.failed, issue: f[c]);
          continue;
        }
        fields[c] = switch (planned.outcome) {
          PlannedOutcome.missing => const FieldOutcome(FieldOutcomeKind.missing),
          PlannedOutcome.unchanged =>
            FieldOutcome(FieldOutcomeKind.unchanged, value: planned.value),
          PlannedOutcome.skippedFormula => FieldOutcome(
              FieldOutcomeKind.skippedFormula,
              value: planned.value,
              issue: CellHasFormula(
                  '${columnLetter(index.rows[p.date]!.columns[c]!)}${p.row}')),
          PlannedOutcome.write => writeIssue == null
              ? FieldOutcome(FieldOutcomeKind.written, value: planned.value)
              : FieldOutcome(FieldOutcomeKind.failed,
                  value: planned.value, issue: writeIssue),
        };
      }
      days.add(DayResult(
        date: p.date,
        status: DayResult.statusOf(fields, null),
        fields: fields,
        notes: notes[p.date] ?? const [],
      ));
    }

    return finish(days, runIssues);
  }

  static List<SyncIssue> _dedupe(List<SyncIssue> issues) {
    final seen = <String>{};
    return [
      for (final i in issues)
        if (seen.add('${i.code}|${i is HcPermissionMissing ? i.types : ''}')) i,
    ];
  }
}
