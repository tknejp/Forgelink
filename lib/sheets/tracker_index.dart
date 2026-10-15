import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';

/// A weekly Table on the tracker tab, reduced to what the index needs.
/// Rows are 0-based grid indexes, end exclusive (as in the Sheets API).
@immutable
class TableInfo {
  final String name;
  final int startRow;
  final int endRow;
  final int startColumn;
  final bool hasFooter;

  /// Column names by table-relative index.
  final Map<int, String> columnNames;

  const TableInfo({
    required this.name,
    required this.startRow,
    required this.endRow,
    required this.startColumn,
    required this.hasFooter,
    required this.columnNames,
  });

  /// Data rows: after the header row, before the footer (0-based, end excl.).
  int get firstDataRow => startRow + 1;
  int get endDataRow => endRow - (hasFooter ? 1 : 0);

  bool containsDataRow(int gridRow) =>
      gridRow >= firstDataRow && gridRow < endDataRow;
}

/// Expected headers of a weekly table, columns A..H.
const expectedTableHeaders = [
  'DATUM',
  'VÁHA',
  'KCAL',
  'BÍLKOVINY',
  'SACHARIDY',
  'TUKY',
  'VLÁKNINA',
  'KROKY',
];

String normalizeHeader(String s) =>
    s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

/// Date → row lookup for the tracker tab (docs/implementation_plan.md §4
/// steps 4–5). Pure; built from the metadata and one `A:H` values read.
@immutable
class TrackerIndex {
  /// Date → 1-based sheet row.
  final Map<LocalDate, int> rows;

  /// Dates that appear on more than one row: never written.
  final Set<LocalDate> duplicates;

  /// 1-based row → current unformatted values of B..H (length ≤ 7).
  final Map<int, List<Object?>> currentValues;

  /// Number of weekly tables recognized (0 when the tab has no Tables).
  final int weekTables;

  /// Names of weekly tables whose headers don't match [expectedTableHeaders].
  final List<String> mismatchedTables;

  const TrackerIndex({
    required this.rows,
    required this.duplicates,
    required this.currentValues,
    required this.weekTables,
    required this.mismatchedTables,
  });

  bool get layoutOk => mismatchedTables.isEmpty;

  LocalDate? get firstDate => rows.isEmpty ? null : (rows.keys.toList()..sort()).first;
  LocalDate? get lastDate => rows.isEmpty ? null : (rows.keys.toList()..sort()).last;

  /// Builds the index.
  ///
  /// [values] is the `A:H` read with `UNFORMATTED_VALUE` + `SERIAL_NUMBER`;
  /// [valuesStartRow] is the 1-based row of `values[0]` (from the response
  /// range). A row counts only if column A parses as a date and — when weekly
  /// Tables exist — it lies inside a weekly Table's data rows.
  factory TrackerIndex.build({
    required List<TableInfo> tables,
    required List<List<Object?>> values,
    int valuesStartRow = 1,
  }) {
    // Weekly tables: start at column A and have DATUM as the first column.
    final weekly = tables
        .where((t) =>
            t.startColumn == 0 &&
            normalizeHeader(t.columnNames[0] ?? '') == expectedTableHeaders[0])
        .toList();
    final mismatched = <String>[
      for (final t in weekly)
        if (!_headersMatch(t)) t.name,
    ];

    final rows = <LocalDate, int>{};
    final duplicates = <LocalDate>{};
    final current = <int, List<Object?>>{};

    for (var i = 0; i < values.length; i++) {
      final row = values[i];
      if (row.isEmpty) continue;
      final date = parseDateCell(row[0]);
      if (date == null) continue;

      final sheetRow = valuesStartRow + i;
      final gridRow = sheetRow - 1;
      if (weekly.isNotEmpty && !weekly.any((t) => t.containsDataRow(gridRow))) {
        continue;
      }

      if (rows.containsKey(date)) {
        duplicates.add(date);
      } else {
        rows[date] = sheetRow;
      }
      current[sheetRow] = row.length > 1 ? row.sublist(1) : const [];
    }

    return TrackerIndex(
      rows: rows,
      duplicates: duplicates,
      currentValues: current,
      weekTables: weekly.length,
      mismatchedTables: mismatched,
    );
  }

  static bool _headersMatch(TableInfo t) {
    for (var i = 0; i < expectedTableHeaders.length; i++) {
      if (normalizeHeader(t.columnNames[i] ?? '') !=
          normalizeHeader(expectedTableHeaders[i])) {
        return false;
      }
    }
    return true;
  }

  /// Column A cell → date. Serial numbers (real dates) and `d.M.yyyy`
  /// strings; anything else (CÍLE:, DATUM, empty, formulas' errors) → null.
  /// Serials outside 2000–2100 are rejected as implausible.
  static LocalDate? parseDateCell(Object? cell) {
    if (cell is num) {
      if (cell < 36526 || cell > 73051) return null; // 2000-01-01..2100-01-01
      return LocalDate.fromSheetSerial(cell);
    }
    if (cell is String) return LocalDate.tryParseCz(cell);
    return null;
  }
}

/// 1-based row of the first value in a `values.get` response, parsed from its
/// A1 range (e.g. `tracker!A1:H904` or `'my tab'!A3:H10`). Defaults to 1.
int startRowOfRange(String? a1Range) {
  if (a1Range == null) return 1;
  final cells = a1Range.split('!').last;
  final m = RegExp(r'^[A-Z]+(\d+)').firstMatch(cells);
  return m == null ? 1 : int.parse(m.group(1)!);
}

/// Quoted sheet name for A1 notation: `'tracker'`, `'it''s'`.
String quoteSheetName(String tab) => "'${tab.replaceAll("'", "''")}'";

/// Columns B..H in sheet order.
const ownedColumns = SheetColumn.values;
