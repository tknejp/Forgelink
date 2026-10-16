import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sync/sync_models.dart';
import 'package:forgelink/ui/day_view.dart';

DayResult _day(Map<SheetColumn, FieldOutcomeKind> kinds) {
  final fields = {
    for (final e in kinds.entries) e.key: FieldOutcome(e.value, value: 1),
  };
  return DayResult(
    date: LocalDate(2026, 10, 15),
    status: DayResult.statusOf(fields, null),
    fields: fields,
  );
}

void main() {
  test('never synced → to write; today non-weight waits for midnight', () {
    expect(
      cellState(null, SheetColumn.kcal, isToday: false),
      CellState.toWrite,
    );
    expect(
      cellState(null, SheetColumn.kcal, isToday: true),
      CellState.afterMidnight,
    );
    expect(
      cellState(null, SheetColumn.weight, isToday: true),
      CellState.toWrite,
    );
  });

  test('outcomes map to cell states', () {
    final day = _day({
      SheetColumn.weight: FieldOutcomeKind.written,
      SheetColumn.steps: FieldOutcomeKind.unchanged,
      SheetColumn.kcal: FieldOutcomeKind.missing,
      SheetColumn.protein: FieldOutcomeKind.skippedFormula,
      SheetColumn.fat: FieldOutcomeKind.failed,
    });
    CellState s(SheetColumn c) => cellState(day, c, isToday: false);
    expect(s(SheetColumn.weight), CellState.inSheet);
    expect(s(SheetColumn.steps), CellState.inSheet);
    expect(s(SheetColumn.kcal), CellState.missing);
    expect(s(SheetColumn.protein), CellState.formula);
    expect(s(SheetColumn.fat), CellState.failed);
  });

  test('nutrition missing only when every KT field had no data', () {
    expect(
      nutritionMissing(
        _day({
          SheetColumn.steps: FieldOutcomeKind.written,
          for (final c in ktColumns) c: FieldOutcomeKind.missing,
        }),
      ),
      isTrue,
    );
    expect(
      nutritionMissing(
        _day({
          for (final c in ktColumns) c: FieldOutcomeKind.missing,
          SheetColumn.kcal: FieldOutcomeKind.written,
        }),
      ),
      isFalse,
    );
    expect(
      nutritionMissing(_day({SheetColumn.weight: FieldOutcomeKind.written})),
      isFalse,
    );
  });
}
