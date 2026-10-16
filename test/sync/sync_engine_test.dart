import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:forgelink/sync/sync_engine.dart';
import 'package:forgelink/sync/sync_models.dart';
import 'package:googleapis/sheets/v4.dart' show ValueRange;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../sheets/tracker_fixture.dart';
import 'sync_fakes.dart';

void main() {
  // "Today" is Thursday 15.10.2026; the fixture week is 12.–18.10.2026.
  final today = LocalDate(2026, 10, 15);
  final yesterday = today.addDays(-1);

  late PrefsStore prefs;
  late FakeHealth health;
  late FakeKt kt;
  late FakeSheet sheet;
  late SyncEngine engine;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = PrefsStore();
    await prefs.setSpreadsheetId('sheet');
    await prefs.setGoogleAccount(email: 'tom@example.com', userId: '1');
    health = FakeHealth();
    kt = FakeKt();
    sheet = FakeSheet();
    engine = SyncEngine(
      prefs: prefs,
      health: health,
      kt: kt,
      sheet: sheet,
      now: () => DateTime(2026, 10, 15, 8, 0),
    );
  });

  List<String> ranges() => [
    for (final p in sheet.writes)
      for (final ValueRange r in p.ranges) r.range!,
  ];

  test('quick sync: yesterday in full, today weight only', () async {
    health.weights[yesterday] = 106.3;
    health.weights[today] = 105.9;
    health.stepCounts[yesterday] = 8432;
    kt.days[yesterday] = loggedDay;

    final r = await engine.run(SyncTrigger.quick, [yesterday, today]);

    expect(r.status, RunStatus.success);
    expect(kt.calls, [yesterday]); // no KT for today
    expect(health.calls, isNot(contains('steps:$today')));
    expect(ranges(), ["'tracker'!B885:H885", "'tracker'!B886"]);
    expect(sheet.writes.single.ranges.first.values, [
      [106.3, 2700, 216, 308, 61, 27, 8432],
    ]);
    expect(r.days.last.fields.keys, [SheetColumn.weight]);
    expect(r.countsAsSuccess, isTrue);
  });

  test(
    'missing data is never written and does not make the day partial',
    () async {
      health.weights[yesterday] = null; // no weigh-in
      health.stepCounts[yesterday] = null; // 0 steps → null from HealthSource
      kt.days[yesterday] = loggedDay;

      final r = await engine.run(SyncTrigger.calendar, [yesterday]);

      expect(ranges(), ["'tracker'!C885:G885"]);
      final d = r.days.single;
      expect(d.status, DayStatus.ok);
      expect(d.fields[SheetColumn.weight]!.kind, FieldOutcomeKind.missing);
      expect(d.fields[SheetColumn.steps]!.kind, FieldOutcomeKind.missing);
    },
  );

  test('empty KT day → NoData note, KT cells untouched', () async {
    health.weights[yesterday] = 106.3;
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(ranges(), ["'tracker'!B885"]);
    expect(r.days.single.notes.single, isA<NoData>());
  });

  test('a single absent macro stays missing; a real 0 is written', () async {
    kt.days[yesterday] = const KtDayNutrition(
      kcal: 1800,
      protein: 120,
      carbs: 200,
      fat: 0,
    );
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    final f = r.days.single.fields;
    expect(f[SheetColumn.fat]!.kind, FieldOutcomeKind.written);
    expect(f[SheetColumn.fat]!.value, 0);
    expect(f[SheetColumn.fiber]!.kind, FieldOutcomeKind.missing);
  });

  test(
    'WEIGHT permission missing → C–H written, B failed, run partial',
    () async {
      health.preflightIssue = const HcPermissionMissing({HcDataType.weight});
      health.stepCounts[yesterday] = 8432;
      kt.days[yesterday] = loggedDay;

      final r = await engine.run(SyncTrigger.calendar, [yesterday]);

      expect(ranges(), ["'tracker'!C885:H885"]);
      expect(
        r.days.single.fields[SheetColumn.weight]!.kind,
        FieldOutcomeKind.failed,
      );
      expect(r.days.single.status, DayStatus.partial);
      expect(r.status, RunStatus.partial);
      expect(r.issues.single, isA<HcPermissionMissing>());
      expect(health.calls, isNot(contains('weight:$yesterday')));
    },
  );

  test('KT credentials missing → B and H written, C–G failed', () async {
    kt.credentials = false;
    health.weights[yesterday] = 106.3;
    health.stepCounts[yesterday] = 8432;

    final r = await engine.run(SyncTrigger.calendar, [yesterday]);

    expect(ranges(), ["'tracker'!B885", "'tracker'!H885"]);
    expect(kt.calls, isEmpty);
    expect(r.issues.single, isA<KtCredentialsMissing>());
    expect(r.status, RunStatus.partial);
  });

  test(
    'today only needs no KT, so missing KT credentials do not matter',
    () async {
      kt.credentials = false;
      health.weights[today] = 105.9;
      final r = await engine.run(SyncTrigger.calendar, [today]);
      expect(r.status, RunStatus.success);
      expect(r.issues, isEmpty);
    },
  );

  test('every needed source blocked → failed run, nothing fetched', () async {
    health.preflightIssue = const HcNotAvailable();
    final r = await engine.run(SyncTrigger.calendar, [today]);
    expect(r.status, RunStatus.failed);
    expect(sheet.writes, isEmpty);
    expect(health.calls, isNot(contains('weight:$today')));
  });

  test('KT failure blocks KT for the rest of the run', () async {
    kt.failWith = const Offline();
    final r = await engine.run(SyncTrigger.range, [
      today.addDays(-3),
      today.addDays(-2),
    ]);
    expect(kt.calls, hasLength(1));
    expect(r.issues.single, isA<Offline>());
  });

  test('HC read failure fails only that field', () async {
    health.failing.add(yesterday);
    kt.days[yesterday] = loggedDay;
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(
      r.days.single.fields[SheetColumn.weight]!.issue,
      isA<HcReadFailed>(),
    );
    expect(r.days.single.status, DayStatus.partial);
  });

  test('history gate fails HC fields with the history issue', () async {
    health.historyIssue = const HcHistoryPermissionMissing();
    kt.days[yesterday] = loggedDay;
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(
      r.days.single.fields[SheetColumn.weight]!.issue,
      isA<HcHistoryPermissionMissing>(),
    );
    expect(r.issues.single, isA<HcHistoryPermissionMissing>());
  });

  test('sheet not configured → failed run before any fetch', () async {
    await prefs.setSpreadsheetId(null);
    final r = await engine.run(SyncTrigger.quick, [yesterday, today]);
    expect(r.status, RunStatus.failed);
    expect(r.issues.single, isA<SheetNotConfigured>());
    expect(health.calls, isEmpty);
  });

  test('Google not connected → failed run', () async {
    await prefs.clearGoogleAccount();
    final r = await engine.run(SyncTrigger.quick, [yesterday, today]);
    expect(r.issues.single, isA<GoogleNotConnected>());
  });

  test('index load failure (e.g. tab missing) fails the run', () async {
    sheet.loadError = const SheetTabMissing('tracker');
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(r.status, RunStatus.failed);
    expect(r.days.single.issue, isA<SheetTabMissing>());
  });

  test('date not in sheet → day failed, KT not called', () async {
    final outside = LocalDate(2026, 9, 1);
    final r = await engine.run(SyncTrigger.calendar, [outside]);
    expect(r.days.single.issue, isA<DateNotInSheet>());
    expect(kt.calls, isEmpty);
    expect(sheet.writes, isEmpty);
  });

  test('Health Connect is read before the sheet is touched', () async {
    sheet.loadError = const Offline();
    health.weights[yesterday] = 106.3;
    await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(health.calls, contains('weight:$yesterday'));
  });

  test('write failure (403) marks written cells failed', () async {
    sheet.writeError = const SheetNoEditAccess('tom@example.com');
    health.weights[yesterday] = 106.3;
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(
      r.days.single.fields[SheetColumn.weight]!.kind,
      FieldOutcomeKind.failed,
    );
    expect(r.issues, contains(isA<SheetNoEditAccess>()));
    expect(r.status, RunStatus.failed);
  });

  test('idempotent second run → all unchanged and no write request', () async {
    final idx = TrackerIndex.build(
      tables: [weekTable()],
      values: trackerValues(
        extraRows: {
          885: [yesterday.toSheetSerial(), 106.3, 2700, 216, 308, 61, 27, 8432],
        },
      ),
    );
    sheet.index = idx;
    health.weights[yesterday] = 106.3;
    health.stepCounts[yesterday] = 8432;
    kt.days[yesterday] = loggedDay;

    final r = await engine.run(SyncTrigger.calendar, [yesterday]);

    expect(sheet.writes, isEmpty);
    expect(
      r.days.single.fields.values.map((f) => f.kind),
      everyElement(FieldOutcomeKind.unchanged),
    );
    expect(r.status, RunStatus.success);
  });

  test('all missing → run noData, no write', () async {
    final r = await engine.run(SyncTrigger.calendar, [yesterday]);
    expect(r.status, RunStatus.noData);
    expect(sheet.writes, isEmpty);
    expect(r.countsAsSuccess, isFalse);
  });

  test('future dates are dropped', () async {
    final r = await engine.run(SyncTrigger.calendar, [today.addDays(1)]);
    expect(r.days, isEmpty);
  });

  test('progress reports each date', () async {
    final seen = <SyncProgress>[];
    await engine.run(SyncTrigger.range, [
      yesterday,
      today,
    ], onProgress: seen.add);
    expect(seen.map((p) => p.done), [0, 1, 2]);
  });
}
