import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/background/background_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:forgelink/background/sync_notifier.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  group('nextSlot (00:30 / 12:30)', () {
    DateTime next(int h, int m) =>
        BackgroundSync.nextSlot(DateTime(2026, 10, 16, h, m));

    test('morning → 12:30 today', () {
      expect(next(9, 0), DateTime(2026, 10, 16, 12, 30));
    });
    test('afternoon → 00:30 tomorrow', () {
      expect(next(13, 0), DateTime(2026, 10, 17, 0, 30));
    });
    test('just after midnight → 00:30 today', () {
      expect(next(0, 5), DateTime(2026, 10, 16, 0, 30));
    });
    test('a run finishing at its own slot books the other one', () {
      expect(next(12, 30), DateTime(2026, 10, 17, 0, 30));
      expect(next(0, 30), DateTime(2026, 10, 16, 12, 30));
    });
    test('month and year boundaries', () {
      expect(
        BackgroundSync.nextSlot(DateTime(2026, 12, 31, 20)),
        DateTime(2027, 1, 1, 0, 30),
      );
    });
  });

  group('SyncNotifier.noticeFor', () {
    late AppLocalizations l10n;
    setUpAll(() async {
      await initializeDateFormatting('cs');
      l10n = lookupAppLocalizations(const Locale('cs'));
    });

    RunResult run(List<DayResult> days, [List<SyncIssue> issues = const []]) =>
        RunResult(
          trigger: SyncTrigger.background,
          startedAt: DateTime(2026, 10, 16, 12, 30),
          finishedAt: DateTime(2026, 10, 16, 12, 30, 4),
          days: days,
          issues: issues,
        );

    DayResult day(int d, Map<SheetColumn, FieldOutcome> f) => DayResult(
      date: LocalDate(2026, 10, d),
      status: DayResult.statusOf(f, null),
      fields: f,
    );

    const written = FieldOutcome(FieldOutcomeKind.written, value: 1);
    const same = FieldOutcome(FieldOutcomeKind.unchanged, value: 1);

    test('success with writes names dates and count', () {
      final n = SyncNotifier.noticeFor(
        run([
          day(15, {SheetColumn.weight: written, SheetColumn.kcal: written}),
        ]),
        l10n,
        notifySuccess: true,
      )!;
      expect(n.kind, NoticeKind.success);
      expect(n.body, contains('15. 10. 2026'));
      expect(n.body, contains('2 hodnoty'));
    });

    test('nothing new → "vše už bylo aktuální"', () {
      final n = SyncNotifier.noticeFor(
        run([
          day(15, {SheetColumn.weight: same}),
        ]),
        l10n,
        notifySuccess: true,
      )!;
      expect(n.body, contains('aktuální'));
    });

    test('success notification can be switched off', () {
      expect(
        SyncNotifier.noticeFor(
          run([
            day(15, {SheetColumn.weight: written}),
          ]),
          l10n,
          notifySuccess: false,
        ),
        isNull,
      );
    });

    test('partial and failed runs always notify with the manual-sync hint', () {
      final partial = SyncNotifier.noticeFor(
        run(
          [
            day(15, {
              SheetColumn.weight: written,
              SheetColumn.kcal: const FieldOutcome(
                FieldOutcomeKind.failed,
                issue: KtAuthRejected(),
              ),
            }),
          ],
          const [KtAuthRejected()],
        ),
        l10n,
        notifySuccess: false,
      )!;
      expect(partial.kind, NoticeKind.partial);
      expect(partial.body, contains('Kalorických tabulek'));
      expect(partial.body, contains('synchronizuj ručně'));

      final failed = SyncNotifier.noticeFor(
        run(
          [
            day(15, {
              SheetColumn.weight: const FieldOutcome(
                FieldOutcomeKind.failed,
                issue: SheetNotFound(),
              ),
            }),
          ],
          const [SheetNotFound()],
        ),
        l10n,
        notifySuccess: false,
      )!;
      expect(failed.kind, NoticeKind.failed);
      expect(failed.body, contains('synchronizuj ručně'));
    });

    test('connection problems stay silent (retried automatically)', () {
      final offline = SyncNotifier.noticeFor(
        run(
          [
            day(15, {
              SheetColumn.weight: const FieldOutcome(
                FieldOutcomeKind.failed,
                issue: Offline(),
              ),
            }),
          ],
          const [Offline()],
        ),
        l10n,
        notifySuccess: true,
      );
      expect(offline, isNull);
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
