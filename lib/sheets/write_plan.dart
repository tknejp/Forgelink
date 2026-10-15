import 'package:googleapis/sheets/v4.dart' show ValueRange;
import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';
import '../core/sync_issue.dart';
import 'tracker_index.dart';

enum PlannedOutcome { write, unchanged, missing, skippedFormula }

@immutable
class PlannedField {
  final PlannedOutcome outcome;
  final num? value;
  const PlannedField(this.outcome, [this.value]);

  @override
  String toString() => '$outcome($value)';
}

/// What will happen to one date.
@immutable
class PlannedDay {
  final LocalDate date;

  /// 1-based sheet row; null when the date can't be written ([issue] set).
  final int? row;

  /// Per owned column. Empty when [issue] is set.
  final Map<SheetColumn, PlannedField> fields;

  /// Blocking issue for the whole date ([DateNotInSheet] / [DateDuplicated]).
  final SyncIssue? issue;

  const PlannedDay({
    required this.date,
    required this.fields,
    this.row,
    this.issue,
  });
}

@immutable
class WritePlan {
  final List<PlannedDay> days;

  /// One `ValueRange` per run of adjacent cells to write; empty when nothing
  /// changes (then no write request is sent at all).
  final List<ValueRange> ranges;

  const WritePlan(this.days, this.ranges);

  bool get hasWrites => ranges.isNotEmpty;

  int get cellsToWrite => days.fold(
      0,
      (n, d) =>
          n + d.fields.values.where((f) => f.outcome == PlannedOutcome.write).length);
}

/// Builds the values-only write plan (docs/implementation_plan.md §4 step 8).
/// Pure.
///
/// [values]: per date, the new value per column; a missing key or `null`
/// means "missing" — never sent. [formulas]: 1-based row → B..H as read with
/// `valueRenderOption: FORMULA`.
WritePlan buildWritePlan({
  required String tab,
  required TrackerIndex index,
  required Map<LocalDate, Map<SheetColumn, num?>> values,
  Map<int, List<Object?>> formulas = const {},
}) {
  final days = <PlannedDay>[];
  final ranges = <ValueRange>[];
  final sheet = quoteSheetName(tab);

  final dates = values.keys.toList()..sort();
  for (final date in dates) {
    if (index.duplicates.contains(date)) {
      days.add(PlannedDay(date: date, fields: const {}, issue: DateDuplicated(date)));
      continue;
    }
    final row = index.rows[date];
    if (row == null) {
      days.add(PlannedDay(date: date, fields: const {}, issue: DateNotInSheet(date)));
      continue;
    }

    final newValues = values[date]!;
    final current = index.currentValues[row] ?? const [];
    final rowFormulas = formulas[row] ?? const [];
    final fields = <SheetColumn, PlannedField>{};

    for (final col in ownedColumns) {
      final offset = col.sheetColumnIndex - 1; // B = 0 in the B..H lists
      final value = newValues[col];
      if (value == null) {
        fields[col] = const PlannedField(PlannedOutcome.missing);
      } else if (_isFormula(_at(rowFormulas, offset))) {
        fields[col] = PlannedField(PlannedOutcome.skippedFormula, value);
      } else if (_sameValue(col, _at(current, offset), value)) {
        fields[col] = PlannedField(PlannedOutcome.unchanged, value);
      } else {
        fields[col] = PlannedField(PlannedOutcome.write, value);
      }
    }
    days.add(PlannedDay(date: date, row: row, fields: fields));

    // Group adjacent writes into one range each, e.g. 'tracker'!C884:G884.
    List<num>? run;
    SheetColumn? runStart;
    SheetColumn? runEnd;
    void flush() {
      if (run == null) return;
      final a1 = runStart == runEnd
          ? '$sheet!${runStart!.letter}$row'
          : '$sheet!${runStart!.letter}$row:${runEnd!.letter}$row';
      ranges.add(ValueRange(range: a1, majorDimension: 'ROWS', values: [run!]));
      run = null;
    }

    for (final col in ownedColumns) {
      final f = fields[col]!;
      if (f.outcome == PlannedOutcome.write) {
        if (run == null) {
          run = <num>[];
          runStart = col;
        }
        run!.add(f.value!);
        runEnd = col;
      } else {
        flush();
      }
    }
    flush();
  }

  return WritePlan(days, ranges);
}

Object? _at(List<Object?> list, int i) => i < list.length ? list[i] : null;

bool _isFormula(Object? cell) => cell is String && cell.startsWith('=');

bool _sameValue(SheetColumn col, Object? current, num value) {
  if (current is! num) return false;
  if (col == SheetColumn.weight) return (current - value).abs() < 0.05;
  return current == value;
}
