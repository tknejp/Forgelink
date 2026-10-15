import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';

void main() {
  group('Sheets serial', () {
    test('known serials from the coach sheet', () {
      expect(LocalDate.fromSheetSerial(46307), LocalDate(2026, 10, 12));
      expect(LocalDate.fromSheetSerial(46310), LocalDate(2026, 10, 15));
      expect(LocalDate(2026, 10, 12).toSheetSerial(), 46307);
    });

    test('fractional part (time of day) is ignored', () {
      expect(LocalDate.fromSheetSerial(46307.75), LocalDate(2026, 10, 12));
    });

    test('round-trips across a year including DST changes', () {
      var d = LocalDate(2026, 1, 1);
      for (var i = 0; i < 400; i++) {
        expect(LocalDate.fromSheetSerial(d.toSheetSerial()), d);
        d = d.addDays(1);
      }
    });
  });

  group('tryParseCz', () {
    test('accepts the coach sheet formats', () {
      expect(LocalDate.tryParseCz('12.10.2026'), LocalDate(2026, 10, 12));
      expect(LocalDate.tryParseCz('12. 10. 2026'), LocalDate(2026, 10, 12));
      expect(LocalDate.tryParseCz(' 1.7.2025 '), LocalDate(2025, 7, 1));
    });

    test('rejects non-dates and impossible dates', () {
      expect(LocalDate.tryParseCz('CÍLE:'), isNull);
      expect(LocalDate.tryParseCz('DATUM'), isNull);
      expect(LocalDate.tryParseCz(''), isNull);
      expect(LocalDate.tryParseCz('31.2.2026'), isNull);
      expect(LocalDate.tryParseCz('12.13.2026'), isNull);
      expect(LocalDate.tryParseCz('2026-10-12'), isNull);
    });
  });

  group('day window', () {
    test('DST start day (2026-03-29, Europe/Prague) ends at next midnight', () {
      final d = LocalDate(2026, 3, 29);
      expect(d.startOfDay, DateTime(2026, 3, 29));
      expect(d.endOfDay, DateTime(2026, 3, 30));
    });

    test('DST end day (2026-10-25) ends at next midnight', () {
      final d = LocalDate(2026, 10, 25);
      expect(d.endOfDay, DateTime(2026, 10, 26));
    });

    test('addDays crosses month and year boundaries', () {
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
    });
  });

  group('misc', () {
    test('isoKey round-trips', () {
      final d = LocalDate(2026, 7, 5);
      expect(d.isoKey, '2026-07-05');
      expect(LocalDate.tryParseIso(d.isoKey), d);
      expect(LocalDate.tryParseIso('2026-02-30'), isNull);
    });

    test('weekday: 12.10.2026 is a Monday', () {
      expect(LocalDate(2026, 10, 12).weekday, DateTime.monday);
    });

    test('ordering and daysUntil', () {
      final a = LocalDate(2026, 10, 12);
      final b = LocalDate(2026, 10, 15);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.daysUntil(b), 3);
      expect(LocalDate.fromDateTime(DateTime(2026, 10, 12, 23, 59)), a);
    });
  });
}
