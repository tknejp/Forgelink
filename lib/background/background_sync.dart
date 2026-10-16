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
import 'failure_notifier.dart';

/// Automatic daily sync (docs/implementation_plan.md §13 Phase 6).
///
/// One unique periodic WorkManager task, ~every 12 h with a 4 h flex, only
/// with network. Each run re-syncs the last three days in full plus today's
/// weight; unchanged cells are skipped, so extra runs cost nothing and late
/// data (e.g. steps Samsung Health pushes later) heals itself.
abstract final class BackgroundSync {
  static const uniqueName = 'forgelink_daily_sync';
  static const taskName = 'forgelink.daily_sync';
  static const lookbackDays = 3;

  /// Call on every app start and when the setting changes: registers the
  /// task when auto sync is on (also recovering it after a force-stop or
  /// hibernation), cancels it otherwise.
  static Future<void> apply(PrefsStore prefs) async {
    try {
      await Workmanager().initialize(backgroundSyncCallback);
      if (await prefs.autoSync()) {
        await Workmanager().registerPeriodicTask(
          uniqueName,
          taskName,
          frequency: const Duration(hours: 12),
          flexInterval: const Duration(hours: 4),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        );
        AppLog.sync.info('Background sync scheduled (12 h)');
      } else {
        await Workmanager().cancelByUniqueName(uniqueName);
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

  /// Debug aid: runs the same headless worker once, [delay] from now, so it
  /// can be observed with the app closed (periodic work can't be forced
  /// before its window).
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

/// One background run. Return values follow workmanager_android:
/// `true` → success (also for problems only the user can fix — they are
/// recorded and notified), `false` → retry with backoff (transient problems).
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

    final googleAuth = GoogleAuth(prefs);
    await googleAuth.initialize();
    final engine = SyncEngine(
      prefs: prefs,
      health: HealthSource(prefs: prefs, requireBackgroundPermission: true),
      kt: KtSource(KtClient(storage: SecureStore.instance)),
      sheet: TrackerSheet(SheetsGateway(googleAuth, interactive: false)),
    );
    final history = SyncHistory(prefs, IntegrationStatusStore(prefs));

    final today = LocalDate.today();
    final result = await engine.run(
      SyncTrigger.background,
      BackgroundSync.datesFor(today),
    );
    await history.record(result);
    await FailureNotifier(prefs).notifyIfNeeded(result);

    // Retry soon only when nothing got through and the cause is transient.
    final retry =
        result.status == RunStatus.failed &&
        result.issues.isNotEmpty &&
        result.issues.every((i) => i.isTransient);
    return !retry;
  } catch (e, st) {
    AppLog.sync.error('Background run crashed', err: e, stackTrace: st);
    return true; // don't loop on a bug; the next period runs anyway
  } finally {
    await log.flush();
  }
}
