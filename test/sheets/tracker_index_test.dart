import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sheets/tracker_sheet.dart';
import 'package:googleapis/sheets/v4.dart';

import 'tracker_fixture.dart';

void main() {
  final mon = LocalDate(2026, 10, 12);
  final sun = LocalDate(2026, 10, 18);

  test('serial dates inside the week table → rows 883..889', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(),
    );
    expect(index.weekTables, 1);
    expect(index.incompleteTables, isEmpty);
    expect(index.rows[mon]!.row, 883);
    expect(index.rows[sun]!.row, 889);
    expect(index.rows, hasLength(7));
    expect(index.firstDate, mon);
    expect(index.lastDate, sun);
  });

  test('text dates (12.10.2026) are accepted too', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(textDates: true),
    );
    expect(index.rows[mon]!.row, 883);
    expect(index.rows, hasLength(7));
  });

  test('columns come from the row\'s own table headers', () {
    final index = TrackerIndex.build(
      tables: [
        weekTable(),
        weekTable(name: 'Tabulka32', headerRow: 448, columnNames: oldLayout),
      ],
      values: trackerValues(weeks: {448: LocalDate(2025, 11, 10)}),
    );
    final newRow = index.rows[mon]!;
    expect(newRow.columns[SheetColumn.kcal], 2); // C
    expect(newRow.columns[SheetColumn.steps], 7); // H

    final oldRow = index.rows[LocalDate(2025, 11, 10)]!;
    expect(oldRow.table, 'Tabulka32');
    expect(oldRow.columns[SheetColumn.weight], 1); // B
    expect(oldRow.columns[SheetColumn.protein], 2); // C
    expect(oldRow.columns[SheetColumn.kcal], 6); // G
    expect(oldRow.columns[SheetColumn.steps], 10); // K
  });

  test('CÍLE, header and footer rows are never targets', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(),
    );
    expect(
      index.rows.values.map((r) => r.row),
      everyElement(inInclusiveRange(883, 889)),
    );
  });

  test('a date outside every weekly table is ignored', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(
        extraRows: {
          5: [LocalDate(2026, 10, 20).toSheetSerial()],
        },
      ),
    );
    expect(index.rows.containsKey(LocalDate(2026, 10, 20)), isFalse);
  });

  test(
    'footer not flagged by the API: a dateless last row is still skipped',
    () {
      final index = TrackerIndex.build(
        tables: [weekTable(hasFooter: false)],
        values: trackerValues(),
      );
      expect(index.rows, hasLength(7));
    },
  );

  test('duplicate dates are reported, never resolved', () {
    final index = TrackerIndex.build(
      tables: [
        weekTable(),
        weekTable(name: 'Tabulka64', headerRow: 892),
      ],
      values: trackerValues(weeks: {892: mon}),
    );
    expect(index.duplicates, containsAll([mon, sun]));
  });

  test('a table missing an owned header blocks only its own dates', () {
    final broken = Map.of(newLayout)..[2] = 'KALORIE';
    final index = TrackerIndex.build(
      tables: [
        weekTable(),
        weekTable(name: 'Broken', headerRow: 892, columnNames: broken),
      ],
      values: trackerValues(weeks: {892: LocalDate(2026, 10, 19)}),
    );
    expect(index.incompleteTables, ['Broken']);
    expect(index.layoutBroken, contains(LocalDate(2026, 10, 19)));
    expect(index.rows[mon], isNotNull);
    expect(index.rows.containsKey(LocalDate(2026, 10, 19)), isFalse);
  });

  test('headers are compared trimmed and case-insensitive', () {
    final messy = {
      for (final e in newLayout.entries) e.key: ' ${e.value.toLowerCase()} ',
    };
    final index = TrackerIndex.build(
      tables: [weekTable(columnNames: messy)],
      values: trackerValues(),
    );
    expect(index.incompleteTables, isEmpty);
    expect(index.rows, hasLength(7));
  });

  test('tables without a DATUM column are not weekly tables', () {
    const goals = TableInfo(
      name: 'Goals',
      startRow: 0,
      endRow: 5,
      startColumn: 5,
      hasFooter: false,
      columnNames: {0: 'KCAL'},
    );
    final index = TrackerIndex.build(
      tables: [goals, weekTable()],
      values: trackerValues(),
    );
    expect(index.weekTables, 1);
  });

  test('no tables at all → nothing indexed', () {
    final index = TrackerIndex.build(tables: const [], values: trackerValues());
    expect(index.weekTables, 0);
    expect(index.rows, isEmpty);
  });

  test('current values are captured per field from the right columns', () {
    final index = TrackerIndex.build(
      tables: [weekTable(name: 'Old', headerRow: 448, columnNames: oldLayout)],
      values: trackerValues(
        weeks: {448: LocalDate(2025, 11, 10)},
        extraRows: {
          449: [
            LocalDate(2025, 11, 10).toSheetSerial(),
            106.3, 216, 308, 61, 27, 2700, 'Nízký hlad', 'Hydratovaný', //
            true, 8432,
          ],
        },
      ),
    );
    final r = index.rows[LocalDate(2025, 11, 10)]!;
    expect(r.current[SheetColumn.kcal], 2700);
    expect(r.current[SheetColumn.steps], 8432);
    expect(r.current[SheetColumn.protein], 216);
  });

  test('valuesStartRow offsets row numbers', () {
    final values = [
      ['DATUM'],
      for (var i = 0; i < 7; i++) [mon.addDays(i).toSheetSerial()],
    ];
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: values,
      valuesStartRow: 882,
    );
    expect(index.rows[mon]!.row, 883);
  });

  test('tableInfoOf: an omitted columnIndex means column 0', () {
    final t = Table(
      name: 'Tabulka32',
      range: GridRange(startRowIndex: 447, endRowIndex: 456),
      columnProperties: [
        TableColumnProperties(columnName: 'DATUM'),
        TableColumnProperties(columnIndex: 1, columnName: 'VÁHA'),
      ],
    );
    final info = tableInfoOf(t);
    expect(info.dateColumn, 0);
    expect(info.startColumn, 0);
    expect(info.columnOf('VÁHA'), 1);
  });

  group('parseDateCell', () {
    test('rejects implausible serials and non-dates', () {
      expect(TrackerIndex.parseDateCell(5), isNull);
      expect(TrackerIndex.parseDateCell(106.3), isNull);
      expect(TrackerIndex.parseDateCell('DATUM'), isNull);
      expect(TrackerIndex.parseDateCell(null), isNull);
      expect(TrackerIndex.parseDateCell(true), isNull);
    });
  });

  group('helpers', () {
    test('startRowOfRange', () {
      expect(startRowOfRange("tracker!A1:L904"), 1);
      expect(startRowOfRange("'my tab'!A883:L889"), 883);
      expect(startRowOfRange(null), 1);
    });

    test('columnLetter', () {
      expect(columnLetter(0), 'A');
      expect(columnLetter(10), 'K');
      expect(columnLetter(25), 'Z');
      expect(columnLetter(26), 'AA');
    });

    test('quoteSheetName escapes quotes', () {
      expect(quoteSheetName('tracker'), "'tracker'");
      expect(quoteSheetName("it's"), "'it''s'");
    });

    test('parseSpreadsheetId', () {
      expect(
        parseSpreadsheetId(
          'https://docs.google.com/spreadsheets/d/'
          '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv/edit#gid=0',
        ),
        '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv',
      );
      expect(
        parseSpreadsheetId(' 1ExampleSpreadsheetId_abcdefghijklmnopqrstuv '),
        '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv',
      );
      expect(parseSpreadsheetId('not a sheet'), isNull);
      expect(parseSpreadsheetId('https://example.com/x'), isNull);
    });
  });
}
