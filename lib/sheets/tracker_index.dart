import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/local_date.dart';

/// A Table on the tracker tab, reduced to what the index needs.
/// Rows/columns are 0-based grid indexes, end exclusive (as in the Sheets API).
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

  /// Absolute 0-based sheet column of the header [name], or null.
  int? columnOf(String name) {
    final wanted = normalizeHeader(name);
    for (final e in columnNames.entries) {
      if (normalizeHeader(e.value) == wanted) return startColumn + e.key;
    }
    return null;
  }

  /// Absolute date column (DATUM); null → not a weekly table.
  int? get dateColumn => columnOf(dateHeader);

  /// Absolute column of every owned field found by header name.
  Map<SheetColumn, int> get ownedColumns => {
    for (final c in SheetColumn.values) c: ?columnOf(c.header),
  };

  bool get isComplete => ownedColumns.length == SheetColumn.values.length;
}

const dateHeader = 'DATUM';

String normalizeHeader(String s) =>
    s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

/// One writable date row.
@immutable
class IndexedRow {
  /// 1-based sheet row.
  final int row;
  final String table;

  /// Absolute 0-based column per owned field, from this row's table headers.
  final Map<SheetColumn, int> columns;

  /// Current unformatted value per owned field.
  final Map<SheetColumn, Object?> current;

  const IndexedRow({
    required this.row,
    required this.table,
    required this.columns,
    required this.current,
  });
}

/// Date → row lookup for the tracker tab (docs/implementation_plan.md §4
/// steps 4–5). Pure; built from the Table metadata and one values read.
///
/// Older weeks in the coach's sheet use a different column order than newer
/// ones, so columns are never assumed: each row's owned columns come from the
/// header names of the weekly Table it belongs to. Rows outside weekly Tables
/// are ignored.
@immutable
class TrackerIndex {
  final Map<LocalDate, IndexedRow> rows;

  /// Dates that appear on more than one row → all their 1-based rows.
  /// Never written.
  final Map<LocalDate, List<int>> duplicateRows;

  Set<LocalDate> get duplicates => duplicateRows.keys.toSet();

  /// Dates inside a weekly Table that lacks one of the owned headers: never
  /// written (reported as a layout problem for that date only).
  final Set<LocalDate> layoutBroken;

  /// Weekly Tables recognized (have a DATUM column).
  final int weekTables;

  /// Names of weekly Tables missing one of the owned headers.
  final List<String> incompleteTables;

  const TrackerIndex({
    required this.rows,
    required this.duplicateRows,
    required this.layoutBroken,
    required this.weekTables,
    required this.incompleteTables,
  });

  /// Highest owned column used by any indexed row (for the formula read).
  int get maxColumn => rows.values.fold(
    7,
    (m, r) => r.columns.values.fold(m, (m2, c) => c > m2 ? c : m2),
  );

  LocalDate? get firstDate =>
      rows.isEmpty ? null : (rows.keys.toList()..sort()).first;
  LocalDate? get lastDate =>
      rows.isEmpty ? null : (rows.keys.toList()..sort()).last;

  /// [values] is a read of the tab starting at column A with
  /// `UNFORMATTED_VALUE` + `SERIAL_NUMBER`; [valuesStartRow] is the 1-based
  /// row of `values[0]` (from the response range).
  factory TrackerIndex.build({
    required List<TableInfo> tables,
    required List<List<Object?>> values,
    int valuesStartRow = 1,
  }) {
    final weekly = tables.where((t) => t.dateColumn != null).toList()
      ..sort((a, b) => a.startRow.compareTo(b.startRow));

    final rows = <LocalDate, IndexedRow>{};
    final duplicates = <LocalDate, List<int>>{};
    final broken = <LocalDate>{};
    final incomplete = <String>[];

    Object? cell(int gridRow, int col) {
      final i = gridRow - (valuesStartRow - 1);
      if (i < 0 || i >= values.length) return null;
      final r = values[i];
      return col < r.length ? r[col] : null;
    }

    for (final t in weekly) {
      final dateCol = t.dateColumn!;
      final columns = t.ownedColumns;
      final complete = t.isComplete;
      if (!complete) incomplete.add(t.name);

      for (var g = t.firstDataRow; g < t.endDataRow; g++) {
        final date = parseDateCell(cell(g, dateCol));
        if (date == null) continue;
        if (!complete) {
          broken.add(date);
          continue;
        }
        if (rows.containsKey(date) || duplicates.containsKey(date)) {
          duplicates.putIfAbsent(date, () => [rows[date]!.row]).add(g + 1);
          continue;
        }
        rows[date] = IndexedRow(
          row: g + 1,
          table: t.name,
          columns: columns,
          current: {for (final e in columns.entries) e.key: cell(g, e.value)},
        );
      }
    }

    duplicates.keys.forEach(rows.remove);

    return TrackerIndex(
      rows: rows,
      duplicateRows: duplicates,
      layoutBroken: broken,
      weekTables: weekly.length,
      incompleteTables: incomplete,
    );
  }

  /// Date cell → date. Serial numbers (real dates) and `d.M.yyyy` strings;
  /// anything else → null. Serials outside 2000–2100 are rejected.
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
/// A1 range (e.g. `tracker!A1:Z904` or `'my tab'!A3:Z10`). Defaults to 1.
int startRowOfRange(String? a1Range) {
  if (a1Range == null) return 1;
  final cells = a1Range.split('!').last;
  final m = RegExp(r'^[A-Z]+(\d+)').firstMatch(cells);
  return m == null ? 1 : int.parse(m.group(1)!);
}

/// Quoted sheet name for A1 notation: `'tracker'`, `'it''s'`.
String quoteSheetName(String tab) => "'${tab.replaceAll("'", "''")}'";

/// 0-based column index → A1 letters (0 → A, 25 → Z, 26 → AA).
String columnLetter(int index) {
  var n = index + 1;
  var s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}
