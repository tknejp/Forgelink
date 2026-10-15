import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/sheets/tracker_index.dart';

/// Mirrors the coach sheet screenshot: goals block at rows 878–879 ("CÍLE:"
/// in A879), Table header at row 882 (DATUM … KROKY …), days 12.–18.10.2026
/// at rows 883–889, footer with AVERAGE formulas at row 890.
/// Grid indexes are 0-based: header 881, footer 889, end exclusive 890.
TableInfo weekTable({
  String name = 'Tabulka63',
  int headerRow = 882,
  Map<int, String>? columnNames,
}) =>
    TableInfo(
      name: name,
      startRow: headerRow - 1,
      endRow: headerRow - 1 + 9,
      startColumn: 0,
      hasFooter: true,
      columnNames: columnNames ??
          const {
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
          },
    );

/// `A:H` UNFORMATTED values from row 1 to 890 with the week above filled in.
/// Dates are serials (real date cells) unless [textDates] is set.
List<List<Object?>> trackerValues({
  bool textDates = false,
  Map<int, List<Object?>> extraRows = const {},
}) {
  final lastRow = [890, ...extraRows.keys].reduce((a, b) => a > b ? a : b);
  final rows = List<List<Object?>>.generate(lastRow, (_) => <Object?>[]);
  rows[879 - 1] = ['CÍLE:', 'Vyplnit v neděli feedback :)'];
  rows[882 - 1] = [
    'DATUM', 'VÁHA', 'KCAL', 'BÍLKOVINY', 'SACHARIDY', 'TUKY', 'VLÁKNINA', //
    'KROKY',
  ];
  for (var i = 0; i < 7; i++) {
    final d = LocalDate(2026, 10, 12 + i);
    rows[883 - 1 + i] = [
      textDates ? '${d.day}.${d.month}.${d.year}' : d.toSheetSerial(),
    ];
  }
  rows[890 - 1] = ['', '#DIV/0!', '#DIV/0!', '#DIV/0!', '#DIV/0!', '#DIV/0!', //
    '#DIV/0!', '#DIV/0!'];
  extraRows.forEach((row, values) => rows[row - 1] = values);
  return rows;
}
