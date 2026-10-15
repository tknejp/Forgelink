import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sources/health/hc_read_client.dart';
import 'package:forgelink/sources/health/health_source.dart';
import 'package:health/health.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_hc_read_client.dart';

void main() {
  late FakeHcReadClient client;
  late PrefsStore prefs;
  late HealthSource source;
  final today = LocalDate(2026, 10, 16);
  final day = LocalDate(2026, 10, 12);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    client = FakeHcReadClient();
    prefs = PrefsStore();
    source = HealthSource(
      prefs: prefs,
      client: client,
      now: () => DateTime(2026, 10, 16, 9, 30),
    );
  });

  group('steps', () {
    test('queries local midnight to next midnight', () async {
      client.stepsValue = 8432;
      expect(await source.steps(day), 8432);
      expect(client.stepCalls.single,
          (DateTime(2026, 10, 12), DateTime(2026, 10, 13)));
    });

    test('0 means no data → null (cell untouched)', () async {
      client.stepsValue = 0;
      expect(await source.steps(day), isNull);
    });

    test('null (native error swallowed by the plugin) → HcReadFailed',
        () async {
      client.stepsValue = null;
      await expectLater(
        source.steps(day),
        throwsA(isA<SyncIssueException>()
            .having((e) => e.issue, 'issue', isA<HcReadFailed>())),
      );
    });

    test('PlatformException → HcReadFailed', () async {
      client.stepsError = PlatformException(code: 'x');
      await expectLater(source.steps(day), throwsA(isA<SyncIssueException>()));
    });

    test('DST end day still ends at next local midnight', () async {
      client.stepsValue = 1;
      await source.steps(LocalDate(2026, 10, 25));
      expect(client.stepCalls.single.$2, DateTime(2026, 10, 26));
    });
  });

  group('lastWeight', () {
    test('picks the last reading of the day, rounded to 1 decimal', () async {
      client.weights = [
        (time: DateTime(2026, 10, 12, 21, 0), kg: 106.94, source: 'scale'),
        (time: DateTime(2026, 10, 12, 7, 0), kg: 105.21, source: 'scale'),
        (time: DateTime(2026, 10, 12, 12, 0), kg: 106.0, source: 'scale'),
      ];
      expect(await source.lastWeight(day), 106.9);
    });

    test('ignores readings outside the local day', () async {
      client.weights = [
        (time: DateTime(2026, 10, 12, 7, 0), kg: 105.2, source: 'scale'),
        (time: DateTime(2026, 10, 13, 0, 0), kg: 999.0, source: 'scale'),
        (time: DateTime(2026, 10, 11, 23, 59), kg: 888.0, source: 'scale'),
      ];
      expect(await source.lastWeight(day), 105.2);
    });

    test('same timestamp → deterministic tie-break by source', () async {
      final t = DateTime(2026, 10, 12, 7, 0);
      client.weights = [
        (time: t, kg: 105.3, source: 'z-app'),
        (time: t, kg: 105.1, source: 'a-app'),
      ];
      expect(await source.lastWeight(day), 105.3);
    });

    test('no readings or non-positive → null', () async {
      expect(await source.lastWeight(day), isNull);
      client.weights = [
        (time: DateTime(2026, 10, 12, 7, 0), kg: 0, source: 'x'),
      ];
      expect(await source.lastWeight(day), isNull);
    });
  });

  group('preflight', () {
    test('ok when available and granted; records the first-grant date',
        () async {
      expect(await source.preflight(HcDataType.values.toSet()), isNull);
      expect(await prefs.hcFirstGrantDate(), today);
    });

    test('not available → HcNotAvailable', () async {
      client.availabilityValue = HcAvailability.notInstalled;
      expect(await source.preflight({HcDataType.weight}),
          isA<HcNotAvailable>());
    });

    test('missing WEIGHT → HcPermissionMissing({weight})', () async {
      client.granted = {HealthDataType.STEPS};
      final issue = await source.preflight(HcDataType.values.toSet());
      expect(issue, isA<HcPermissionMissing>());
      expect((issue as HcPermissionMissing).types, {HcDataType.weight});
      expect(await prefs.hcFirstGrantDate(), isNull);
    });

    test('only checks the types the run needs', () async {
      client.granted = {HealthDataType.WEIGHT};
      expect(await source.preflight({HcDataType.weight}), isNull);
    });

    test('nothing needed → no checks at all', () async {
      client.availabilityValue = HcAvailability.notInstalled;
      expect(await source.preflight({}), isNull);
    });
  });

  group('history gate', () {
    test('inside the 30-day window → ok', () async {
      await prefs.recordHcFirstGrant(today);
      expect(await source.historyGate(today.addDays(-30)), isNull);
    });

    test('before the window without permission → HcHistoryPermissionMissing',
        () async {
      await prefs.recordHcFirstGrant(today);
      expect(await source.historyGate(today.addDays(-31)),
          isA<HcHistoryPermissionMissing>());
    });

    test('before the window with permission → ok', () async {
      await prefs.recordHcFirstGrant(today);
      client.historyAuthorized = true;
      expect(await source.historyGate(today.addDays(-200)), isNull);
    });
  });
}
