import 'dart:convert';

import 'package:meta/meta.dart';

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/prefs_store.dart';
import '../core/sync_issue.dart';
import '../sheets/tracker_index.dart';
import '../sheets/tracker_sheet.dart';

/// How much of a date's row in the coach's sheet is filled, read from the
/// sheet itself (not from Forgelink's own sync history).
enum SheetFill {
  /// Every owned cell the day needs is filled (steps optional, see
  /// [SheetSnapshot.fillOf]).
  full,
  partial,
  empty,

  /// The date can't be written: it is on several rows, or its weekly Table
  /// lacks one of the owned headers.
  problem,
}

/// One date's owned cells as they are in the sheet.
@immutable
class SheetDay {
  /// Owned columns with a non-empty value.
  final Set<SheetColumn> filled;

  /// Numeric values of [filled] cells (text cells count as filled but have
  /// no value here).
  final Map<SheetColumn, num> values;

  const SheetDay(this.filled, this.values);

  Map<String, Object?> toJson() => {
    'f': [for (final c in filled) c.name],
    'v': {for (final e in values.entries) e.key.name: e.value},
  };

  static SheetDay fromJson(Map<String, Object?> j) => SheetDay(
    {
      for (final n in (j['f'] as List? ?? const []))
        for (final c in SheetColumn.values)
          if (c.name == n) c,
    },
    {
      for (final e in ((j['v'] as Map?) ?? const {}).entries)
        for (final c in SheetColumn.values)
          if (c.name == e.key && e.value is num) c: e.value as num,
    },
  );
}

/// The sheet's fill state for every date it contains, taken at [at].
@immutable
class SheetSnapshot {
  final DateTime at;
  final Map<LocalDate, SheetDay> days;

  /// Duplicated dates and dates in a Table with a broken layout.
  final Set<LocalDate> problems;

  const SheetSnapshot({
    required this.at,
    required this.days,
    required this.problems,
  });

  factory SheetSnapshot.fromIndex(TrackerIndex index, DateTime at) {
    final days = <LocalDate, SheetDay>{};
    for (final e in index.rows.entries) {
      final filled = <SheetColumn>{};
      final values = <SheetColumn, num>{};
      for (final c in e.value.current.entries) {
        final v = c.value;
        if (v == null || (v is String && v.trim().isEmpty)) continue;
        filled.add(c.key);
        if (v is num) values[c.key] = v;
      }
      days[e.key] = SheetDay(filled, values);
    }
    return SheetSnapshot(
      at: at,
      days: days,
      problems: {...index.duplicates, ...index.layoutBroken},
    );
  }

  /// Fill state of [date], or null when the date isn't in the sheet.
  ///
  /// A past day is [SheetFill.full] when everything except steps is filled
  /// (a day with 0 steps is left blank on purpose); today only needs the
  /// weight — the rest comes after midnight.
  SheetFill? fillOf(LocalDate date, LocalDate today) {
    if (problems.contains(date)) return SheetFill.problem;
    final day = days[date];
    if (day == null) return null;
    if (day.filled.isEmpty) return SheetFill.empty;
    final required = date == today
        ? const {SheetColumn.weight}
        : {
            for (final c in SheetColumn.values)
              if (c != SheetColumn.steps) c,
          };
    return day.filled.containsAll(required)
        ? SheetFill.full
        : SheetFill.partial;
  }

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'd': {for (final e in days.entries) e.key.isoKey: e.value.toJson()},
    'p': [for (final d in problems) d.isoKey],
  };

  static SheetSnapshot fromJson(Map<String, Object?> j) => SheetSnapshot(
    at: DateTime.parse(j['at'] as String),
    days: {
      for (final e in ((j['d'] as Map?) ?? const {}).entries)
        ?LocalDate.tryParseIso(e.key as String): SheetDay.fromJson(
          (e.value as Map).cast(),
        ),
    },
    problems: {
      for (final s in (j['p'] as List? ?? const []))
        ?LocalDate.tryParseIso(s as String),
    },
  );
}

/// Reads the sheet's fill state (one metadata + one values read, never
/// interactive) and keeps the last snapshot in prefs so Home paints at once
/// on start and works offline.
class SheetStatusSource {
  SheetStatusSource(this._prefs, this._sheet, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PrefsStore _prefs;

  /// Must use a non-interactive gateway: this runs on app open.
  final TrackerSheet _sheet;
  final DateTime Function() _now;

  static const _key = 'sheet.snapshot';
  static const _keyId = 'sheet.snapshot_id';

  /// Last snapshot, if it belongs to the sheet chosen now.
  Future<SheetSnapshot?> cached() async {
    final raw = await _prefs.rawString(_key);
    if (raw == null || raw.isEmpty) return null;
    if (await _prefs.rawString(_keyId) != await _prefs.spreadsheetId()) {
      return null;
    }
    try {
      return SheetSnapshot.fromJson((jsonDecode(raw) as Map).cast());
    } catch (_) {
      return null;
    }
  }

  /// Fresh snapshot, or null when there is no sheet / no Google account /
  /// the read failed (the cached one stays).
  Future<SheetSnapshot?> load() async {
    final id = await _prefs.spreadsheetId();
    if (id == null || await _prefs.googleAccount() == null) return null;
    try {
      final index = await _sheet.loadIndex(id, await _prefs.sheetTab());
      final snap = SheetSnapshot.fromIndex(index, _now());
      await _prefs.setRawString(_key, jsonEncode(snap.toJson()));
      await _prefs.setRawString(_keyId, id);
      return snap;
    } on SyncIssueException catch (e) {
      AppLog.sheets.info('Sheet status not refreshed', payload: e.issue.code);
      return null;
    } catch (e) {
      AppLog.sheets.warn('Sheet status read failed', payload: '$e');
      return null;
    }
  }
}
