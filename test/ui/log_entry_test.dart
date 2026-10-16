import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/ui/settings/diagnostics_screen.dart';

void main() {
  test('parses an AppLogger line into its parts', () {
    final e = LogEntry.parse(
      '[13:56:45.687][WARN ][KT][API] Day without data  | 2026-10-15  | err: x',
    );
    expect(e.time, '13:56:45.687');
    expect(e.level, 'WARN');
    expect(e.tag, 'KT · API');
    expect(e.message, 'Day without data');
    expect(e.detail, '2026-10-15 · err: x');
    expect(e.isIssue, isTrue);
  });

  test('success lines are not issues', () {
    final e = LogEntry.parse('[12:30:08.115][OK   ][SYNC] Run finished');
    expect(e.level, 'OK');
    expect(e.tag, 'SYNC');
    expect(e.detail, isEmpty);
    expect(e.isIssue, isFalse);
  });

  test('unknown lines are kept whole', () {
    final e = LogEntry.parse('something else');
    expect(e.message, 'something else');
    expect(e.isIssue, isFalse);
  });
}
