import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sheets/tracker_index.dart';

/// Newest weeks (screenshot): A DATUM, B VÁHA, C KCAL, D BÍLKOVINY,
/// E SACHARIDY, F TUKY, G VLÁKNINA, H KROKY, I–L manual.
const newLayout = {
  0: 'DATUM',
  1: 'VÁHA',
  2: 'KCAL',
  3: 'BÍLKOVINY',
  4: 'SACHARIDY',
  5: 'TUKY',
  6: 'VLÁKNINA',
  7: 'KROKY',
  8: 'POCIT HLADU',
  9: 'HYDRATACE',
  10: 'TRÉNINK',
  11: 'POZNÁMKY',
};

/// Older weeks (seen in the real sheet, e.g. Tabulka32): KCAL in G and
/// KROKY in K, with the manual columns H–J in between.
const oldLayout = {
  0: 'DATUM',
  1: 'VÁHA',
  2: 'BÍLKOVINY',
  3: 'SACHARIDY',
  4: 'TUKY',
  5: 'VLÁKNINA',
  6: 'KCAL',
  7: 'POCIT HLADU',
  8: 'HYDRATACE',
  9: 'TRÉNINK',
  10: 'KROKY',
  11: 'POZNÁMKY',
};

/// A weekly Table: header at [headerRow] (1-based), 7 day rows, footer.
/// Grid indexes are 0-based: header headerRow-1, end exclusive headerRow+8.
TableInfo weekTable({
  String name = 'Tabulka63',
  int headerRow = 882,
  Map<int, String> columnNames = newLayout,
  bool hasFooter = true,
}) =>
    TableInfo(
      name: name,
      startRow: headerRow - 1,
      endRow: headerRow - 1 + 9,
      startColumn: 0,
      hasFooter: hasFooter,
      columnNames: columnNames,
    );

/// Unformatted values from row 1 (column A first). Contains the goals row
/// ("CÍLE:" at 879), the header at 882, days 12.–18.10.2026 at 883–889 and
/// the footer at 890. [weeks] adds more weeks: header row → first Monday.
List<List<Object?>> trackerValues({
  bool textDates = false,
  Map<int, LocalDate> weeks = const {},
  Map<int, List<Object?>> extraRows = const {},
}) {
  final allWeeks = {882: LocalDate(2026, 10, 12), ...weeks};
  final lastRow = [
    for (final h in allWeeks.keys) h + 8,
    ...extraRows.keys,
  ].reduce((a, b) => a > b ? a : b);
  final rows = List<List<Object?>>.generate(lastRow, (_) => <Object?>[]);
  rows[879 - 1] = ['CÍLE:', 'Vyplnit v neděli feedback :)'];
  allWeeks.forEach((header, monday) {
    rows[header - 1] = ['DATUM', 'VÁHA'];
    for (var i = 0; i < 7; i++) {
      final d = monday.addDays(i);
      rows[header + i] = [
        textDates ? '${d.day}.${d.month}.${d.year}' : d.toSheetSerial(),
      ];
    }
    rows[header + 7] = ['', '#DIV/0!', '#DIV/0!'];
  });
  extraRows.forEach((row, values) => rows[row - 1] = values);
  return rows;
}
