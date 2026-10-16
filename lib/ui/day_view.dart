import '../core/app_config.dart';
import '../core/local_date.dart';
import '../sync/sheet_status.dart';
import '../sync/sync_history.dart';
import '../sync/sync_models.dart';
import 'widgets/ds.dart';

/// What the last sync says about one cell of a day — shown in the day
/// detail and the Quick Sync rows. Derived from the persisted [DayResult];
/// nothing is read from the sources or the sheet for it.
enum CellState { inSheet, toWrite, missing, afterMidnight, formula, failed }

/// Nutrition fields (Kalorické tabulky).
const ktColumns = [
  SheetColumn.kcal,
  SheetColumn.protein,
  SheetColumn.carbs,
  SheetColumn.fat,
  SheetColumn.fiber,
];

/// Health Connect fields.
const hcColumns = [SheetColumn.weight, SheetColumn.steps];

CellState cellState(DayResult? day, SheetColumn c, {required bool isToday}) {
  // Today only weight is synced; the rest waits for the day to end.
  final waitsForMidnight = isToday && c != SheetColumn.weight;
  final f = day?.fields[c];
  if (f == null) {
    if (day?.issue != null) return CellState.failed;
    return waitsForMidnight ? CellState.afterMidnight : CellState.toWrite;
  }
  return switch (f.kind) {
    FieldOutcomeKind.written || FieldOutcomeKind.unchanged => CellState.inSheet,
    FieldOutcomeKind.missing =>
      waitsForMidnight ? CellState.afterMidnight : CellState.missing,
    FieldOutcomeKind.skippedFormula => CellState.formula,
    // A connection problem isn't this cell's fault: it will be retried.
    FieldOutcomeKind.failed =>
      (f.issue?.isTransient ?? false) ? CellState.toWrite : CellState.failed,
  };
}

extension CellStateTone on CellState {
  Tone get tone => switch (this) {
    CellState.inSheet => Tone.ok,
    CellState.toWrite => Tone.accent,
    CellState.missing || CellState.formula => Tone.warn,
    CellState.afterMidnight => Tone.neutral,
    CellState.failed => Tone.err,
  };
}

/// True when the last result for [day] had no nutrition at all.
bool nutritionMissing(DayResult day) {
  final kt = [for (final c in ktColumns) day.fields[c]].nonNulls.toList();
  return kt.isNotEmpty && kt.every((f) => f.kind == FieldOutcomeKind.missing);
}

/// Calendar colour of [date]: the sheet's own fill state when it has been
/// read ([sheet]), otherwise the last sync result ([day]).
///
/// Red only for problems with this particular date (duplicated / missing in
/// the sheet, formula in a cell). Account-wide problems (sign-in, login,
/// permissions) are shown once in the status card, and connection problems
/// are retried silently — neither paints days red.
DayStatus? calendarStatus(
  LocalDate date,
  LocalDate today, {
  DayResult? day,
  SheetSnapshot? sheet,
}) {
  final dateProblem =
      day != null && day.failures.any((i) => areaOf(i) == IssueArea.date);
  if (sheet != null) {
    final fill = sheet.fillOf(date, today);
    if (fill == SheetFill.full) return DayStatus.ok;
    if (dateProblem || fill == SheetFill.problem) return DayStatus.failed;
    return switch (fill) {
      SheetFill.partial => DayStatus.partial,
      SheetFill.empty => DayStatus.noData,
      // Not in the sheet (week not created yet): fall back to history.
      _ => day?.status == DayStatus.failed ? null : day?.status,
    };
  }
  if (day == null) return null;
  if (dateProblem) return DayStatus.failed;
  if (day.status == DayStatus.failed) return null;
  // Amber: some cells missing (e.g. nutrition not in KT yet).
  if (day.status == DayStatus.ok && date != today && nutritionMissing(day)) {
    return DayStatus.partial;
  }
  return day.status;
}

/// [cellState] with the sheet taking precedence: a filled cell is in the
/// sheet whatever the last run said.
CellState cellStateWithSheet(
  DayResult? day,
  SheetDay? sheetDay,
  SheetColumn c, {
  required bool isToday,
}) {
  if (sheetDay != null && sheetDay.filled.contains(c)) return CellState.inSheet;
  final fromRun = cellState(day, c, isToday: isToday);
  // The run said "in sheet" but the cell is empty now (deleted by hand).
  if (sheetDay != null && fromRun == CellState.inSheet) {
    return isToday && c != SheetColumn.weight
        ? CellState.afterMidnight
        : CellState.toWrite;
  }
  return fromRun;
}

/// Value to show for a cell: the sheet's, else the last run's.
num? cellValue(DayResult? day, SheetDay? sheetDay, SheetColumn c) =>
    sheetDay?.values[c] ?? day?.fields[c]?.value;

/// Dates of [list] sorted, deduplicated.
List<LocalDate> sortedDates(Iterable<LocalDate> list) =>
    {...list}.toList()..sort();
