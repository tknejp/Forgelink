import 'package:meta/meta.dart';

/// A calendar date with no time or time zone. Every date comparison in the
/// app goes through this type, never through `DateTime` instants, so DST and
/// UTC/local mix-ups cannot shift a day.
@immutable
class LocalDate implements Comparable<LocalDate> {
  final int year;
  final int month;
  final int day;

  /// Normalizes overflow (e.g. day 32) through `DateTime`.
  factory LocalDate(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    return LocalDate._(d.year, d.month, d.day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// The local calendar date of [dateTime] (its own y/m/d fields).
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  factory LocalDate.today({DateTime Function() now = DateTime.now}) =>
      LocalDate.fromDateTime(now());

  // ─── Google Sheets serial dates ─────────────────────────────────────────

  static final DateTime _sheetsEpoch = DateTime.utc(1899, 12, 30);

  /// Converts a Sheets day serial (days since 1899-12-30, as returned with
  /// `UNFORMATTED_VALUE` + `SERIAL_NUMBER`). A fractional part (time) is dropped.
  factory LocalDate.fromSheetSerial(num serial) {
    final d = _sheetsEpoch.add(Duration(days: serial.floor()));
    return LocalDate._(d.year, d.month, d.day);
  }

  int toSheetSerial() =>
      DateTime.utc(year, month, day).difference(_sheetsEpoch).inDays;

  // ─── Parsing ────────────────────────────────────────────────────────────

  static final RegExp _czDate = RegExp(
    r'^\s*(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s*$',
  );

  /// Parses `12.10.2026`, `12. 10. 2026` or `1.7.2025`. Returns null for any
  /// other text or an impossible date (e.g. `31.2.2026`).
  static LocalDate? tryParseCz(String input) {
    final m = _czDate.firstMatch(input);
    if (m == null) return null;
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    if (month < 1 || month > 12 || day < 1) return null;
    final date = LocalDate(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Parses the `yyyy-MM-dd` key produced by [isoKey].
  static LocalDate? tryParseIso(String input) {
    final parts = input.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    final date = LocalDate(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    return date;
  }

  // ─── Arithmetic / windows ───────────────────────────────────────────────

  /// Calendar-day arithmetic (never `Duration`, which drifts across DST).
  LocalDate addDays(int days) => LocalDate(year, month, day + days);

  /// Local midnight that starts this day.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Local midnight that starts the next day (exclusive end of the day window).
  DateTime get endOfDay => DateTime(year, month, day + 1);

  /// ISO weekday, Monday = 1 … Sunday = 7.
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(LocalDate other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Stable storage key, `yyyy-MM-dd`.
  String get isoKey =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => isoKey;
}
