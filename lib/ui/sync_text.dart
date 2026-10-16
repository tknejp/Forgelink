import 'package:intl/intl.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';
import '../l10n/app_localizations.dart';
import '../sync/sync_models.dart';
import 'issue_presenter.dart';

/// Czech wording for sync results (run summary, per-day lines, labels).
class SyncText {
  SyncText(this.l10n) : presenter = IssuePresenter(l10n);

  final AppLocalizations l10n;
  final IssuePresenter presenter;

  static final _time = DateFormat('H:mm', 'cs');
  static final _dayMonth = DateFormat('d. M.', 'cs');

  String date(LocalDate d) => presenter.formatDate(d);

  /// "15. 10." (no year), for compact captions.
  String dayMonth(LocalDate d) => _dayMonth.format(d.startOfDay);

  /// "12. 10. 2026" or "12. 10. – 18. 10. 2026".
  String dates(List<LocalDate> list) {
    if (list.isEmpty) return '';
    final sorted = [...list]..sort();
    if (sorted.length == 1) return date(sorted.first);
    final first = sorted.first;
    final last = sorted.last;
    return first.year == last.year
        ? '${_dayMonth.format(first.startOfDay)} – ${date(last)}'
        : '${date(first)} – ${date(last)}';
  }

  String when(DateTime at, {required DateTime now}) {
    final day = LocalDate.fromDateTime(at);
    final today = LocalDate.fromDateTime(now);
    final t = _time.format(at);
    if (day == today) return l10n.whenToday(t);
    if (day == today.addDays(-1)) return l10n.whenYesterday(t);
    return '${date(day)} $t';
  }

  String triggerShort(SyncTrigger t) => t == SyncTrigger.background
      ? l10n.triggerBackgroundShort
      : l10n.triggerManualShort;

  String trigger(SyncTrigger t) => switch (t) {
        SyncTrigger.quick => l10n.triggerQuick,
        SyncTrigger.calendar => l10n.triggerCalendar,
        SyncTrigger.range => l10n.triggerRange,
        SyncTrigger.background => l10n.triggerBackground,
      };

  String runStatus(RunStatus s) => switch (s) {
        RunStatus.success => l10n.runStatusSuccess,
        RunStatus.noData => l10n.runStatusNoData,
        RunStatus.partial => l10n.runStatusPartial,
        RunStatus.failed => l10n.runStatusFailed,
      };

  /// One-line summary of a run (plan §6 run messages).
  String runSummary(RunResult r) {
    final ds = dates([for (final d in r.days) d.date]);
    return switch (r.status) {
      RunStatus.success => l10n.runSuccess(ds),
      RunStatus.noData => l10n.runNothingToWrite(ds),
      RunStatus.partial => l10n.runPartial(ds),
      RunStatus.failed => l10n.runFailed(ds),
    };
  }

  String field(SheetColumn c) => switch (c) {
        SheetColumn.weight => l10n.fieldWeight,
        SheetColumn.kcal => l10n.fieldKcal,
        SheetColumn.protein => l10n.fieldProtein,
        SheetColumn.carbs => l10n.fieldCarbs,
        SheetColumn.fat => l10n.fieldFat,
        SheetColumn.fiber => l10n.fieldFiber,
        SheetColumn.steps => l10n.fieldSteps,
      };

  String outcome(FieldOutcomeKind k) => switch (k) {
        FieldOutcomeKind.written => l10n.outcomeWritten,
        FieldOutcomeKind.unchanged => l10n.outcomeUnchanged,
        FieldOutcomeKind.missing => l10n.outcomeMissing,
        FieldOutcomeKind.skippedFormula => l10n.outcomeSkippedFormula,
        FieldOutcomeKind.failed => l10n.outcomeFailed,
      };

  String _fields(Iterable<SheetColumn> cols) => cols.map(field).join(', ');

  /// "12. 10. 2026: zapsáno váha, kcal; bez dat kroky; nezapsáno … – reason"
  String dayLine(DayResult d) {
    if (d.issue != null) {
      return '${date(d.date)}: ${presenter.message(d.issue!)}';
    }
    final parts = <String>[];
    final written = d.fieldsWhere((f) => f.kind == FieldOutcomeKind.written);
    final unchanged = d.fieldsWhere((f) => f.kind == FieldOutcomeKind.unchanged);
    final missing = d.fieldsWhere((f) => f.kind == FieldOutcomeKind.missing);
    final failed = d.fieldsWhere((f) =>
        f.kind == FieldOutcomeKind.failed ||
        f.kind == FieldOutcomeKind.skippedFormula);
    if (written.isNotEmpty) parts.add(l10n.runDayWritten(_fields(written)));
    if (unchanged.isNotEmpty) {
      parts.add(l10n.runDayUnchanged(_fields(unchanged)));
    }
    if (missing.isNotEmpty) parts.add(l10n.runDayMissing(_fields(missing)));
    if (failed.isNotEmpty) {
      final reasons = {
        for (final c in failed)
          if (d.fields[c]!.issue case final i?) presenter.message(i),
      };
      parts.add('${l10n.runDayFailed(_fields(failed))}'
          '${reasons.isEmpty ? '' : ' – ${reasons.join(' ')}'}');
    }
    return '${date(d.date)}: ${parts.join('; ')}';
  }

  /// Field value for display: weight with one decimal (Czech comma).
  String value(SheetColumn c, num v) => c == SheetColumn.weight
      ? NumberFormat('0.0', 'cs').format(v)
      : NumberFormat.decimalPattern('cs').format(v);
}
