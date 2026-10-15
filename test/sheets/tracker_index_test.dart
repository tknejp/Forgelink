import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sheets/tracker_sheet.dart';

import 'tracker_fixture.dart';

void main() {
  final mon = LocalDate(2026, 10, 12);
  final sun = LocalDate(2026, 10, 18);

  test('serial dates inside the week table → rows 883..889', () {
    final index =
        TrackerIndex.build(tables: [weekTable()], values: trackerValues());
    expect(index.weekTables, 1);
    expect(index.layoutOk, isTrue);
    expect(index.rows[mon], 883);
    expect(index.rows[sun], 889);
    expect(index.rows, hasLength(7));
    expect(index.firstDate, mon);
    expect(index.lastDate, sun);
  });

  test('text dates (12.10.2026) are accepted too', () {
    final index = TrackerIndex.build(
        tables: [weekTable()], values: trackerValues(textDates: true));
    expect(index.rows[mon], 883);
    expect(index.rows, hasLength(7));
  });

  test('CÍLE, header and footer rows are never targets', () {
    final index =
        TrackerIndex.build(tables: [weekTable()], values: trackerValues());
    expect(index.rows.values, everyElement(inInclusiveRange(883, 889)));
  });

  test('a date outside any week table is ignored', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(extraRows: {
        5: [LocalDate(2026, 10, 20).toSheetSerial()],
      }),
    );
    expect(index.rows.containsKey(LocalDate(2026, 10, 20)), isFalse);
  });

  test('a date written in the footer row is ignored', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(extraRows: {
        890: [LocalDate(2026, 10, 19).toSheetSerial()],
      }),
    );
    expect(index.rows.containsKey(LocalDate(2026, 10, 19)), isFalse);
  });

  test('duplicate dates are reported, never resolved', () {
    final second = weekTable(name: 'Tabulka64', headerRow: 892);
    final index = TrackerIndex.build(
      tables: [weekTable(), second],
      values: trackerValues(extraRows: {
        893: [mon.toSheetSerial()],
      }),
    );
    expect(index.duplicates, {mon});
  });

  test('without Tables any date row on the tab counts', () {
    final index = TrackerIndex.build(
      tables: const [],
      values: trackerValues(extraRows: {
        5: [LocalDate(2026, 10, 20).toSheetSerial()],
      }),
    );
    expect(index.weekTables, 0);
    expect(index.rows[LocalDate(2026, 10, 20)], 5);
    expect(index.rows, hasLength(8));
  });

  test('renamed weekly column → layout mismatch', () {
    final broken = weekTable(columnNames: const {
      0: 'DATUM',
      1: 'VÁHA',
      2: 'KALORIE',
      3: 'BÍLKOVINY',
      4: 'SACHARIDY',
      5: 'TUKY',
      6: 'VLÁKNINA',
      7: 'KROKY',
    });
    final index =
        TrackerIndex.build(tables: [broken], values: trackerValues());
    expect(index.layoutOk, isFalse);
    expect(index.mismatchedTables, ['Tabulka63']);
  });

  test('headers are compared trimmed and case-insensitive', () {
    final messy = weekTable(columnNames: const {
      0: ' Datum ',
      1: 'váha',
      2: 'Kcal',
      3: 'Bílkoviny',
      4: 'sacharidy',
      5: 'Tuky',
      6: 'vláknina',
      7: 'Kroky',
    });
    final index =
        TrackerIndex.build(tables: [messy], values: trackerValues());
    expect(index.layoutOk, isTrue);
    expect(index.weekTables, 1);
  });

  test('tables not starting with DATUM in column A are not weekly tables', () {
    const other = TableInfo(
      name: 'Goals',
      startRow: 0,
      endRow: 5,
      startColumn: 5,
      hasFooter: false,
      columnNames: {0: 'KCAL'},
    );
    final index = TrackerIndex.build(
        tables: [other, weekTable()], values: trackerValues());
    expect(index.weekTables, 1);
    expect(index.layoutOk, isTrue);
  });

  test('current B..H values are captured per row', () {
    final index = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(extraRows: {
        883: [mon.toSheetSerial(), 106.3, 2700, 216],
      }),
    );
    expect(index.currentValues[883], [106.3, 2700, 216]);
  });

  test('valuesStartRow offsets row numbers', () {
    final values = [
      [mon.toSheetSerial()],
    ];
    final index = TrackerIndex.build(
        tables: const [], values: values, valuesStartRow: 883);
    expect(index.rows[mon], 883);
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
      expect(startRowOfRange("tracker!A1:H904"), 1);
      expect(startRowOfRange("'my tab'!A883:H889"), 883);
      expect(startRowOfRange(null), 1);
    });

    test('quoteSheetName escapes quotes', () {
      expect(quoteSheetName('tracker'), "'tracker'");
      expect(quoteSheetName("it's"), "'it''s'");
    });

    test('parseSpreadsheetId', () {
      expect(
        parseSpreadsheetId('https://docs.google.com/spreadsheets/d/'
            '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv/edit#gid=0'),
        '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv',
      );
      expect(parseSpreadsheetId(' 1ExampleSpreadsheetId_abcdefghijklmnopqrstuv '),
          '1ExampleSpreadsheetId_abcdefghijklmnopqrstuv');
      expect(parseSpreadsheetId('not a sheet'), isNull);
      expect(parseSpreadsheetId('https://example.com/x'), isNull);
    });
  });
}
