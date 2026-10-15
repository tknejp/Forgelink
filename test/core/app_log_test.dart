import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_log.dart';

class _RecordingSink implements LogSink {
  final lines = <(LogLevel, String)>[];
  @override
  void add(LogLevel level, String line) => lines.add((level, line));
}

void main() {
  group('maskEmail', () {
    test('masks the local part', () {
      expect(maskEmail('jan.novak@example.com'), 'j***@example.com');
    });

    test('never throws on odd input', () {
      expect(maskEmail('@example.com'), '***@example.com');
      expect(maskEmail('no-at-sign'), '***');
      expect(maskEmail(''), '<none>');
      expect(maskEmail(null), '<none>');
    });
  });

  test('sink receives lines regardless of the console gate', () {
    final sink = _RecordingSink();
    AppLog.sink = sink;
    addTearDown(() => AppLog.sink = null);

    AppLog.sync.warn('something odd', payload: 'date=2026-10-12');

    expect(sink.lines, hasLength(1));
    expect(sink.lines.single.$1, LogLevel.warn);
    expect(sink.lines.single.$2, contains('[SYNC] something odd'));
    expect(sink.lines.single.$2, contains('date=2026-10-12'));
  });
}
