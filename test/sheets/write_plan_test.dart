import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sheets/write_plan.dart';

import 'tracker_fixture.dart';

void main() {
  final mon = LocalDate(2026, 10, 12);
  final tue = LocalDate(2026, 10, 13);

  TrackerIndex index({Map<int, List<Object?>> extraRows = const {}}) =>
      TrackerIndex.build(
          tables: [weekTable()], values: trackerValues(extraRows: extraRows));

  const full = {
    SheetColumn.weight: 106.3,
    SheetColumn.kcal: 2700,
    SheetColumn.protein: 216,
    SheetColumn.carbs: 308,
    SheetColumn.fat: 61,
    SheetColumn.fiber: 27,
    SheetColumn.steps: 8432,
  };

  List<String> rangesOf(WritePlan p) => [for (final r in p.ranges) r.range!];

  test('full day → one B..H range with numbers', () {
    final plan = buildWritePlan(
        tab: 'tracker', index: index(), values: {mon: full});
    expect(rangesOf(plan), ["'tracker'!B883:H883"]);
    expect(plan.ranges.single.values, [
      [106.3, 2700, 216, 308, 61, 27, 8432]
    ]);
    expect(plan.cellsToWrite, 7);
  });

  test('missing values are never sent; adjacent writes are grouped', () {
    final plan = buildWritePlan(tab: 'tracker', index: index(), values: {
      tue: {
        SheetColumn.weight: null,
        SheetColumn.kcal: 1720,
        SheetColumn.protein: 132,
        SheetColumn.carbs: 170,
        SheetColumn.fat: 55,
        SheetColumn.fiber: 31,
        SheetColumn.steps: 10234,
      },
    });
    expect(rangesOf(plan), ["'tracker'!C884:H884"]);
    expect(plan.days.single.fields[SheetColumn.weight]!.outcome,
        PlannedOutcome.missing);
  });

  test('a gap splits the row into separate ranges', () {
    final plan = buildWritePlan(tab: 'tracker', index: index(), values: {
      mon: {
        SheetColumn.weight: 106.3,
        SheetColumn.kcal: 2700,
        SheetColumn.steps: 8432,
      },
    });
    expect(rangesOf(plan), ["'tracker'!B883:C883", "'tracker'!H883"]);
  });

  test('old-layout week: KCAL→G, macros→C..F, KROKY→K; manual H..J untouched',
      () {
    final oldMon = LocalDate(2025, 11, 10);
    final idx = TrackerIndex.build(
      tables: [weekTable(name: 'Tabulka32', headerRow: 448, columnNames: oldLayout)],
      values: trackerValues(weeks: {448: oldMon}),
    );
    final plan =
        buildWritePlan(tab: 'tracker', index: idx, values: {oldMon: full});
    expect(rangesOf(plan),
        ["'tracker'!B449:G449", "'tracker'!K449"]);
    expect(plan.ranges.first.values, [
      [106.3, 216, 308, 61, 27, 2700]
    ]);
    expect(plan.ranges.last.values, [
      [8432]
    ]);
  });

  test('layout-broken table date → SheetLayoutChanged, nothing written', () {
    final broken = Map.of(newLayout)..[7] = 'KROKŮ';
    final idx = TrackerIndex.build(
      tables: [weekTable(columnNames: broken)],
      values: trackerValues(),
    );
    final plan = buildWritePlan(tab: 'tracker', index: idx, values: {mon: full});
    expect(plan.days.single.issue, isA<SheetLayoutChanged>());
    expect(plan.hasWrites, isFalse);
  });

  test('nothing ever lands in A or I..L, and no empty strings are written',
      () {
    final plan = buildWritePlan(
        tab: 'tracker', index: index(), values: {mon: full, tue: full});
    for (final r in plan.ranges) {
      final cells = r.range!.split('!').last;
      expect(cells, matches(RegExp(r'^[B-H]\d+(:[B-H]\d+)?$')));
      for (final row in r.values!) {
        for (final v in row) {
          expect(v, isA<num>());
        }
      }
    }
  });

  test('unchanged values are skipped (weight within 0.05)', () {
    final plan = buildWritePlan(
      tab: 'tracker',
      index: index(extraRows: {
        883: [mon.toSheetSerial(), 106.32, 2700, 216, 308, 61, 27, 8432],
      }),
      values: {mon: full},
    );
    expect(plan.hasWrites, isFalse);
    expect(plan.days.single.fields.values.map((f) => f.outcome),
        everyElement(PlannedOutcome.unchanged));
  });

  test('a changed value is rewritten; text in an owned cell is replaced', () {
    final plan = buildWritePlan(
      tab: 'tracker',
      index: index(extraRows: {
        883: [mon.toSheetSerial(), 106.3, 2500, '216', 308, 61, 27, 8432],
      }),
      values: {mon: full},
    );
    expect(rangesOf(plan), ["'tracker'!C883:D883"]);
  });

  test('formula cells are never overwritten', () {
    final plan = buildWritePlan(
      tab: 'tracker',
      index: index(),
      values: {mon: full},
      formulas: {
        883: [null, null, '=C882*2'], // from column A: C883
      },
    );
    expect(plan.days.single.fields[SheetColumn.kcal]!.outcome,
        PlannedOutcome.skippedFormula);
    expect(rangesOf(plan), ["'tracker'!B883", "'tracker'!D883:H883"]);
  });

  test('date not in sheet → DateNotInSheet, nothing written for it', () {
    final missing = LocalDate(2026, 11, 1);
    final plan = buildWritePlan(
        tab: 'tracker', index: index(), values: {missing: full});
    expect(plan.days.single.issue, isA<DateNotInSheet>());
    expect(plan.hasWrites, isFalse);
  });

  test('duplicate date → DateDuplicated, nothing written for it', () {
    final idx = TrackerIndex.build(
      tables: [weekTable(), weekTable(name: 'Tabulka64', headerRow: 892)],
      values: trackerValues(weeks: {892: mon}),
    );
    final plan = buildWritePlan(tab: 'tracker', index: idx, values: {mon: full});
    expect(plan.days.single.issue, isA<DateDuplicated>());
    expect(plan.hasWrites, isFalse);
  });

  test('a real zero is written', () {
    final plan = buildWritePlan(tab: 'tracker', index: index(), values: {
      mon: {SheetColumn.fiber: 0},
    });
    expect(rangesOf(plan), ["'tracker'!G883"]);
    expect(plan.ranges.single.values, [
      [0]
    ]);
  });

  test('days come out sorted by date', () {
    final plan = buildWritePlan(
        tab: 'tracker', index: index(), values: {tue: full, mon: full});
    expect(plan.days.map((d) => d.date), [mon, tue]);
  });
}
