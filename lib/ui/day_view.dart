import '../core/app_config.dart';
import '../core/local_date.dart';
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
    FieldOutcomeKind.failed => CellState.failed,
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

/// Dates of [list] sorted, deduplicated.
List<LocalDate> sortedDates(Iterable<LocalDate> list) =>
    {...list}.toList()..sort();
