import 'package:googleapis/sheets/v4.dart';

import '../core/app_log.dart';
import '../core/sync_issue.dart';
import 'sheets_gateway.dart';
import 'tracker_index.dart';
import 'write_plan.dart';

/// The coach's tracker tab: read the date index, read formulas, write a plan.
/// Never creates tabs/rows and never sends formatting requests.
class TrackerSheet {
  TrackerSheet(this._gateway);

  final SheetsGateway _gateway;

  /// Metadata + one values read → [TrackerIndex]. Throws [SyncIssueException]
  /// with [SheetTabMissing], or [SheetLayoutChanged] when the tab has no
  /// weekly Table at all.
  Future<TrackerIndex> loadIndex(String spreadsheetId, String tab) async {
    final meta = await _gateway.metadata(spreadsheetId);
    final sheet = meta.sheets
        ?.where((s) => s.properties?.title == tab)
        .firstOrNull;
    if (sheet == null) {
      throw SyncIssueException(SheetTabMissing(tab));
    }

    final tables = [
      for (final t in sheet.tables ?? const <Table>[]) tableInfoOf(t),
    ];
    _logLayouts(tab, tables);

    final read = await _gateway.values(
      spreadsheetId,
      _readRange(tab, tables),
      valueRenderOption: 'UNFORMATTED_VALUE',
      dateTimeRenderOption: 'SERIAL_NUMBER',
    );

    final index = TrackerIndex.build(
      tables: tables,
      values: read.values ?? const [],
      valuesStartRow: startRowOfRange(read.range),
    );

    if (index.weekTables == 0) {
      AppLog.sheets.warn(
        'No weekly Table (with a $dateHeader column) on "$tab"',
      );
      throw SyncIssueException(SheetLayoutChanged(tab));
    }
    AppLog.sheets.info(
      'Index built',
      payload:
          'weekTables=${index.weekTables}, dates=${index.rows.length}, '
          'range=${index.firstDate}..${index.lastDate}, '
          'duplicates=${index.duplicateRows}, '
          'incompleteTables=${index.incompleteTables}',
    );
    return index;
  }

  /// Cells from column A with `FORMULA` rendering → 1-based row → cells.
  Future<Map<int, List<Object?>>> loadFormulas(
    String spreadsheetId,
    String tab,
    TrackerIndex index,
  ) async {
    final read = await _gateway.values(
      spreadsheetId,
      '${quoteSheetName(tab)}!A:${columnLetter(index.maxColumn)}',
      valueRenderOption: 'FORMULA',
    );
    final start = startRowOfRange(read.range);
    final rows = read.values ?? const [];
    return {
      for (var i = 0; i < rows.length; i++)
        if (rows[i].isNotEmpty) start + i: rows[i],
    };
  }

  String _readRange(String tab, List<TableInfo> tables) {
    var maxCol = 0;
    for (final t in tables) {
      for (final rel in t.columnNames.keys) {
        if (t.startColumn + rel > maxCol) maxCol = t.startColumn + rel;
      }
    }
    return '${quoteSheetName(tab)}!A:${columnLetter(maxCol < 7 ? 7 : maxCol)}';
  }

  void _logLayouts(String tab, List<TableInfo> tables) {
    final layouts = <String, int>{};
    for (final t in tables) {
      final cols = t.ownedColumns.entries
          .map((e) => '${e.key.header}=${columnLetter(e.value)}')
          .join(' ');
      final key =
          'date=${t.dateColumn == null ? '-' : columnLetter(t.dateColumn!)} $cols';
      layouts[key] = (layouts[key] ?? 0) + 1;
    }
    AppLog.sheets.info(
      'Tables on "$tab": ${tables.length}',
      payload: layouts.entries.map((e) => '${e.value}x [${e.key}]').join(' | '),
    );
  }

  /// Sends the plan's ranges in one values-only request. No-op without writes.
  Future<int> write(String spreadsheetId, WritePlan plan) async {
    if (!plan.hasWrites) return 0;
    final res = await _gateway.writeValues(spreadsheetId, plan.ranges);
    final updated = res.totalUpdatedCells ?? 0;
    AppLog.sheets.success(
      'Wrote $updated cells in ${plan.ranges.length} ranges',
    );
    return updated;
  }
}

/// Reduces a Sheets `Table` to [TableInfo].
TableInfo tableInfoOf(Table t) {
  final range = t.range;
  return TableInfo(
    name: t.name ?? t.tableId ?? '?',
    startRow: range?.startRowIndex ?? 0,
    endRow: range?.endRowIndex ?? 0,
    startColumn: range?.startColumnIndex ?? 0,
    hasFooter: t.rowsProperties?.footerColorStyle != null,
    columnNames: {
      for (final c in t.columnProperties ?? const <TableColumnProperties>[])
        // The API omits columnIndex when it is 0 (proto default).
        c.columnIndex ?? 0: c.columnName ?? '',
    },
  );
}

/// Accepts a full Google Sheets URL or a bare ID. Returns null if neither.
String? parseSpreadsheetId(String input) {
  final s = input.trim();
  final fromUrl = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(s);
  if (fromUrl != null) return fromUrl.group(1);
  if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(s)) return s;
  return null;
}
