import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';

import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/log_buffer.dart';
import '../core/prefs_store.dart';
import '../core/secure_store.dart';
import '../sheets/google_auth.dart';
import '../sheets/sheets_gateway.dart';
import '../sheets/tracker_sheet.dart';
import '../sources/health/health_source.dart';
import '../sources/kt/kt_client.dart';
import '../sources/kt/kt_source.dart';
import '../sync/integration_status.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_history.dart';
import '../sync/sync_models.dart';
import 'sync_notifier.dart';

/// Automatic sync at fixed times of day (docs/implementation_plan.md Phase 6).
///
/// Runs at about 00:30 (the day that just ended, complete) and 12:30 (after
/// the morning weigh-in). WorkManager periodic work drifts, so each run is a
/// one-off task with its own name; a run first books the next slot, then
/// syncs — the chain survives a crash, and every app start re-arms it.
/// Each run re-syncs the last [lookbackDays] days in full plus today's
/// weight; unchanged cells are skipped, so overlapping runs cost nothing.
abstract final class BackgroundSync {
  static const taskName = 'forgelink.daily_sync';
  static const tag = 'forgelink_scheduled';
  static const lookbackDays = 3;

  /// Times of day (hour, minute), local time.
  static const slots = [(0, 30), (12, 30)];

  /// Unique name of the old 12 h periodic task (before fixed times).
  static const _legacyPeriodicName = 'forgelink_daily_sync';

  /// The first slot strictly later than [now] + 1 minute.
  static DateTime nextSlot(DateTime now) {
    final earliest = now.add(const Duration(minutes: 1));
    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      for (final (h, m) in slots) {
        final t = DateTime(now.year, now.month, now.day + dayOffset, h, m);
        if (t.isAfter(earliest)) return t;
      }
    }
    final (h, m) = slots.first;
    return DateTime(now.year, now.month, now.day + 2, h, m);
  }

  static String _nameFor(DateTime slot) =>
      'forgelink_sync_${LocalDate.fromDateTime(slot).isoKey}_'
      '${slot.hour.toString().padLeft(2, '0')}'
      '${slot.minute.toString().padLeft(2, '0')}';

  /// Call on every app start and when the setting changes: books the next
  /// slot when auto sync is on (KEEP — never pushes an already booked run),
  /// cancels everything otherwise.
  static Future<void> apply(PrefsStore prefs) async {
    try {
      await Workmanager().initialize(backgroundSyncCallback);
      await Workmanager().cancelByUniqueName(_legacyPeriodicName);
      if (await prefs.autoSync()) {
        await scheduleNext(prefs);
      } else {
        await Workmanager().cancelByTag(tag);
        await prefs.setNextBackgroundRun(null);
        AppLog.sync.info('Background sync cancelled');
      }
    } catch (e, st) {
      AppLog.sync.error(
        'Scheduling background sync failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Books the next 00:30 / 12:30 run. Safe to call repeatedly.
  static Future<void> scheduleNext(PrefsStore prefs, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final slot = nextSlot(at);
    await Workmanager().registerOneOffTask(
      _nameFor(slot),
      taskName,
      tag: tag,
      initialDelay: slot.difference(at),
      // Offline at the slot → runs as soon as the network is back.
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
    await prefs.setNextBackgroundRun(slot);
    AppLog.sync.info('Next background sync booked', payload: '$slot');
  }

  /// Debug aid: runs the same headless worker once, [delay] from now, so it
  /// can be observed with the app closed.
  static Future<void> runOnceForTest({
    Duration delay = const Duration(seconds: 10),
  }) async {
    await Workmanager().initialize(backgroundSyncCallback);
    await Workmanager().registerOneOffTask(
      'forgelink_test_run',
      taskName,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    AppLog.sync.info('Test background run scheduled in ${delay.inSeconds} s');
  }

  /// Dates one background run covers: the last [lookbackDays] days in full
  /// and today (weight only, by the engine's rules).
  static List<LocalDate> datesFor(LocalDate today) => [
    for (var i = lookbackDays; i >= 0; i--) today.addDays(-i),
  ];
}

/// Headless entry point: runs in its own Flutter engine with no Activity.
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, input) => runBackgroundSync());
}

/// One background run. Always returns `true` (no WorkManager retries): the
/// outcome is recorded and notified, and the next slot or a manual sync
/// takes over — retries would only produce a burst of notifications.
Future<bool> runBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await initializeDateFormatting('cs');

  final prefs = PrefsStore();
  final log = PersistentLogBuffer(prefs);
  AppLog.sink = log;
  await log.load();

  try {
    if (!await prefs.autoSync()) {
      AppLog.sync.info('Background run skipped: auto sync is off');
      return true;
    }
    // Book the next slot first, so a crash below can't break the chain.
    await BackgroundSync.scheduleNext(prefs);

    final googleAuth = GoogleAuth(prefs);
    await googleAuth.initialize();
    final engine = SyncEngine(
      prefs: prefs,
      health: HealthSource(prefs: prefs, requireBackgroundPermission: true),
      kt: KtSource(KtClient(storage: SecureStore.instance)),
      sheet: TrackerSheet(SheetsGateway(googleAuth, interactive: false)),
    );
    final history = SyncHistory(prefs, IntegrationStatusStore(prefs));

    final result = await engine.run(
      SyncTrigger.background,
      BackgroundSync.datesFor(LocalDate.today()),
    );
    await history.record(result);
    await SyncNotifier(prefs).notify(result);
    return true;
  } catch (e, st) {
    AppLog.sync.error('Background run crashed', err: e, stackTrace: st);
    await SyncNotifier(prefs).notifyCrash();
    return true;
  } finally {
    await log.flush();
  }
}
