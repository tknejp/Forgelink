import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/background/background_sync.dart';
import 'package:forgelink/background/failure_notifier.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/core/system_intents.dart';
import 'package:forgelink/sources/health/health_source.dart';
import 'package:forgelink/sync/sync_models.dart';
import 'package:forgelink/ui/settings/auto_sync_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../sources/health/fake_hc_read_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('a background run covers the last 3 days and today', () {
    final today = LocalDate(2026, 10, 16);
    expect(BackgroundSync.datesFor(today), [
      LocalDate(2026, 10, 13),
      LocalDate(2026, 10, 14),
      LocalDate(2026, 10, 15),
      today,
    ]);
  });

  group('FailureNotifier.actionable', () {
    RunResult run(List<SyncIssue> issues) => RunResult(
      trigger: SyncTrigger.background,
      startedAt: DateTime(2026, 10, 16),
      finishedAt: DateTime(2026, 10, 16),
      days: const [],
      issues: issues,
    );

    test('user-fixable problems notify', () {
      expect(
        FailureNotifier.actionable(
          run(const [
            KtAuthRejected(),
            GoogleReauthRequired(),
            HcBackgroundPermissionMissing(),
          ]),
        ),
        hasLength(3),
      );
    });

    test('transient problems and no-data notes never notify', () {
      expect(
        FailureNotifier.actionable(
          run([
            const Offline(),
            const SheetsUnavailable(),
            const KtUnavailable(),
            NoData(DataSource.kt, LocalDate(2026, 10, 15)),
          ]),
        ),
        isEmpty,
      );
    });
  });

  group('HealthSource in the worker', () {
    test(
      'without background-read permission → HcBackgroundPermissionMissing',
      () async {
        final client = FakeHcReadClient();
        final source = HealthSource(
          prefs: PrefsStore(),
          client: client,
          requireBackgroundPermission: true,
        );
        expect(
          await source.preflight({HcDataType.weight}),
          isA<HcBackgroundPermissionMissing>(),
        );
        client.backgroundAuthorized = true;
        expect(await source.preflight({HcDataType.weight}), isNull);
      },
    );

    test('the foreground app does not need it', () async {
      final source = HealthSource(
        prefs: PrefsStore(),
        client: FakeHcReadClient(),
      );
      expect(await source.preflight({HcDataType.weight}), isNull);
    });
  });

  test('AutoSyncController persists the switch and reschedules', () async {
    final prefs = PrefsStore();
    var scheduled = 0;
    final c = AutoSyncController(
      prefs,
      const SystemIntents(),
      scheduler: (_) async => scheduled++,
    );
    await c.load();
    expect(c.enabled, isFalse);

    await c.setEnabled(true);
    expect(await prefs.autoSync(), isTrue);
    expect(scheduled, 1);

    await c.setEnabled(false);
    expect(await prefs.autoSync(), isFalse);
    expect(scheduled, 2);
  });
}
