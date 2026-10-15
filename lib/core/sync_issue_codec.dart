import 'local_date.dart';
import 'sync_issue.dart';

/// JSON round-trip for [SyncIssue] (history, open issues, day statuses).
/// Unknown codes decode to [UnexpectedIssue] rather than failing.
abstract final class SyncIssueCodec {
  static Map<String, Object?> encode(SyncIssue i) => {
        'c': i.code,
        ...switch (i) {
          SheetNoEditAccess(:final email) => {'email': email},
          SheetTabMissing(:final tab) => {'tab': tab},
          SheetLayoutChanged(:final tab) => {'tab': tab},
          DateNotInSheet(:final date) => {'date': date.isoKey},
          DateDuplicated(:final date, :final rows) => {
              'date': date.isoKey,
              'rows': rows,
            },
          CellHasFormula(:final cell) => {'cell': cell},
          HcPermissionMissing(:final types) => {
              'types': [for (final t in types) t.name],
            },
          HcReadFailed(:final date) => {'date': date.isoKey},
          NoData(:final source, :final date) => {
              'source': source.name,
              'date': date.isoKey,
            },
          _ => const <String, Object?>{},
        },
      };

  static SyncIssue decode(Map<String, Object?> j) {
    final code = j['c'] as String? ?? '';
    final plain = SyncIssue.parameterlessFromCode(code);
    if (plain != null) return plain;

    LocalDate date() =>
        LocalDate.tryParseIso(j['date'] as String? ?? '') ??
        LocalDate(2000, 1, 1);

    return switch (code) {
      'sheetNoEditAccess' => SheetNoEditAccess(j['email'] as String? ?? ''),
      'sheetTabMissing' => SheetTabMissing(j['tab'] as String? ?? ''),
      'sheetLayoutChanged' => SheetLayoutChanged(j['tab'] as String? ?? ''),
      'dateNotInSheet' => DateNotInSheet(date()),
      'dateDuplicated' => DateDuplicated(
          date(),
          [for (final r in (j['rows'] as List? ?? const [])) (r as num).toInt()],
        ),
      'cellHasFormula' => CellHasFormula(j['cell'] as String? ?? ''),
      'hcPermissionMissing' => HcPermissionMissing({
          for (final t in (j['types'] as List? ?? const []))
            ...HcDataType.values.where((v) => v.name == t),
        }),
      'hcReadFailed' => HcReadFailed(date()),
      'noData' => NoData(
          DataSource.values.firstWhere((s) => s.name == j['source'],
              orElse: () => DataSource.kt),
          date(),
        ),
      _ => const UnexpectedIssue(),
    };
  }
}
