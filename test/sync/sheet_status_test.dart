import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sync/sheet_status.dart';
import 'package:forgelink/sync/sync_models.dart';
import 'package:forgelink/ui/day_view.dart';

final _today = LocalDate(2026, 10, 16);

IndexedRow _row(Map<SheetColumn, Object?> current) => IndexedRow(
  row: 10,
  table: 'T',
  columns: {for (final c in SheetColumn.values) c: c.index + 1},
  current: {for (final c in SheetColumn.values) c: current[c]},
);

Map<SheetColumn, Object?> _all({Set<SheetColumn> except = const {}}) => {
  for (final c in SheetColumn.values)
    if (!except.contains(c)) c: 100,
};

SheetSnapshot _snap(Map<LocalDate, Map<SheetColumn, Object?>> rows) =>
    SheetSnapshot.fromIndex(
      TrackerIndex(
        rows: {for (final e in rows.entries) e.key: _row(e.value)},
        duplicateRows: {
          LocalDate(2026, 10, 1): [3, 4],
        },
        layoutBroken: const {},
        weekTables: 1,
        incompleteTables: const [],
      ),
      DateTime(2026, 10, 16, 18),
    );

void main() {
  final d14 = LocalDate(2026, 10, 14);
  final d15 = LocalDate(2026, 10, 15);

  test('fill states: steps are optional, today needs only weight', () {
    final s = _snap({
      LocalDate(2026, 10, 10): _all(),
      LocalDate(2026, 10, 11): _all(except: {SheetColumn.steps}),
      LocalDate(2026, 10, 12): _all(except: {SheetColumn.kcal}),
      LocalDate(2026, 10, 13): {SheetColumn.weight: ''},
      _today: {SheetColumn.weight: 84.6},
    });
    expect(s.fillOf(LocalDate(2026, 10, 10), _today), SheetFill.full);
    expect(s.fillOf(LocalDate(2026, 10, 11), _today), SheetFill.full);
    expect(s.fillOf(LocalDate(2026, 10, 12), _today), SheetFill.partial);
    expect(s.fillOf(LocalDate(2026, 10, 13), _today), SheetFill.empty);
    expect(s.fillOf(_today, _today), SheetFill.full);
    expect(s.fillOf(LocalDate(2026, 10, 1), _today), SheetFill.problem);
    expect(s.fillOf(LocalDate(2026, 11, 1), _today), isNull);
  });

  test('json round trip keeps values and problems', () {
    final s = _snap({
      d15: {SheetColumn.weight: 84.6, SheetColumn.kcal: 'x'},
    });
    final back = SheetSnapshot.fromJson(s.toJson());
    expect(back.at, s.at);
    expect(back.days[d15]!.filled, {SheetColumn.weight, SheetColumn.kcal});
    expect(back.days[d15]!.values, {SheetColumn.weight: 84.6});
    expect(back.problems, {LocalDate(2026, 10, 1)});
  });

  group('calendarStatus', () {
    DayResult failed(LocalDate d) =>
        DayResult(date: d, status: DayStatus.failed, fields: const {});

    test('the sheet wins when it is full, even after a failed run', () {
      final s = _snap({d15: _all()});
      expect(
        calendarStatus(d15, _today, day: failed(d15), sheet: s),
        DayStatus.ok,
      );
    });

    test('a failed run stays red while the sheet is not full', () {
      final s = _snap({
        d15: _all(except: {SheetColumn.kcal}),
      });
      expect(
        calendarStatus(d15, _today, day: failed(d15), sheet: s),
        DayStatus.failed,
      );
    });

    test('partial / empty from the sheet; history when not in it', () {
      final s = _snap({
        d14: {SheetColumn.weight: 80},
        d15: {},
      });
      expect(calendarStatus(d14, _today, sheet: s), DayStatus.partial);
      expect(calendarStatus(d15, _today, sheet: s), DayStatus.noData);
      expect(calendarStatus(LocalDate(2026, 11, 2), _today, sheet: s), isNull);
    });

    test('without a snapshot the last run decides', () {
      expect(calendarStatus(d15, _today), isNull);
      expect(calendarStatus(d15, _today, day: failed(d15)), DayStatus.failed);
    });
  });

  test('a cell filled in the sheet is "in sheet"; emptied → to write', () {
    final sheetDay = _snap({
      d15: {SheetColumn.weight: 84.6},
    }).days[d15]!;
    final run = DayResult(
      date: d15,
      status: DayStatus.ok,
      fields: {
        SheetColumn.kcal: const FieldOutcome(
          FieldOutcomeKind.written,
          value: 3000,
        ),
      },
    );
    expect(
      cellStateWithSheet(run, sheetDay, SheetColumn.weight, isToday: false),
      CellState.inSheet,
    );
    expect(
      cellStateWithSheet(run, sheetDay, SheetColumn.kcal, isToday: false),
      CellState.toWrite,
    );
    expect(cellValue(run, sheetDay, SheetColumn.weight), 84.6);
  });
}
