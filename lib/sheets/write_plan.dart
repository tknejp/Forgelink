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

  /// Per owned field. Empty when [issue] is set.
  final Map<SheetColumn, PlannedField> fields;

  /// Blocking issue for the whole date ([DateNotInSheet], [DateDuplicated],
  /// [SheetLayoutChanged]).
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
          n +
          d.fields.values.where((f) => f.outcome == PlannedOutcome.write).length);
}

/// Builds the values-only write plan (docs/implementation_plan.md §4 step 8).
/// Pure.
///
/// [values]: per date, the new value per field; a missing key or `null`
/// means "missing" — never sent. Target columns come from each row's own
/// Table headers ([IndexedRow.columns]). [formulas]: 1-based row → cells from
/// column A as read with `valueRenderOption: FORMULA`.
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
    final dupRows = index.duplicateRows[date];
    if (dupRows != null) {
      days.add(PlannedDay(
          date: date, fields: const {}, issue: DateDuplicated(date, dupRows)));
      continue;
    }
    if (index.layoutBroken.contains(date)) {
      days.add(PlannedDay(
          date: date, fields: const {}, issue: SheetLayoutChanged(tab)));
      continue;
    }
    final indexed = index.rows[date];
    if (indexed == null) {
      days.add(PlannedDay(
          date: date, fields: const {}, issue: DateNotInSheet(date)));
      continue;
    }

    final row = indexed.row;
    final newValues = values[date]!;
    final rowFormulas = formulas[row] ?? const [];
    final fields = <SheetColumn, PlannedField>{};
    final writes = <int, num>{}; // absolute column → value

    for (final field in SheetColumn.values) {
      final col = indexed.columns[field]!;
      final value = newValues[field];
      if (value == null) {
        fields[field] = const PlannedField(PlannedOutcome.missing);
      } else if (_isFormula(_at(rowFormulas, col))) {
        fields[field] = PlannedField(PlannedOutcome.skippedFormula, value);
      } else if (_sameValue(field, indexed.current[field], value)) {
        fields[field] = PlannedField(PlannedOutcome.unchanged, value);
      } else {
        fields[field] = PlannedField(PlannedOutcome.write, value);
        writes[col] = value;
      }
    }
    days.add(PlannedDay(date: date, row: row, fields: fields));

    // Group adjacent columns into one range each, e.g. 'tracker'!C884:G884.
    final cols = writes.keys.toList()..sort();
    var i = 0;
    while (i < cols.length) {
      var j = i;
      while (j + 1 < cols.length && cols[j + 1] == cols[j] + 1) {
        j++;
      }
      final from = columnLetter(cols[i]);
      final to = columnLetter(cols[j]);
      ranges.add(ValueRange(
        range: i == j ? '$sheet!$from$row' : '$sheet!$from$row:$to$row',
        majorDimension: 'ROWS',
        values: [
          [for (var k = i; k <= j; k++) writes[cols[k]]!]
        ],
      ));
      i = j + 1;
    }
  }

  return WritePlan(days, ranges);
}

Object? _at(List<Object?> list, int i) => i < list.length ? list[i] : null;

bool _isFormula(Object? cell) => cell is String && cell.startsWith('=');

bool _sameValue(SheetColumn field, Object? current, num value) {
  if (current is! num) return false;
  if (field == SheetColumn.weight) return (current - value).abs() < 0.05;
  return current == value;
}
