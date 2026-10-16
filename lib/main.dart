import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'background/background_sync.dart';
import 'core/app_log.dart';
import 'core/log_buffer.dart';
import 'core/prefs_store.dart';
import 'core/secure_store.dart';
import 'core/system_intents.dart';
import 'l10n/app_localizations.dart';
import 'sheets/drive_chooser.dart';
import 'sheets/google_auth.dart';
import 'sheets/sheets_gateway.dart';
import 'sheets/tracker_sheet.dart';
import 'sources/health/health_source.dart';
import 'sources/kt/kt_client.dart';
import 'sources/kt/kt_source.dart';
import 'sync/integration_status.dart';
import 'sync/sync_controller.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_history.dart';
import 'ui/settings/health_connect_controller.dart';
import 'ui/settings/auto_sync_controller.dart';
import 'ui/settings/google_controller.dart';
import 'ui/settings/kt_controller.dart';
import 'ui/settings/sheet_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('cs');

  final prefs = PrefsStore();
  final logBuffer = PersistentLogBuffer(prefs);
  AppLog.sink = logBuffer;
  await logBuffer.load();
  AppLog.app.info('Forgelink starting');

  const intents = SystemIntents();
  // Notification texts for the sync foreground service (no BuildContext yet).
  final l10n = lookupAppLocalizations(const Locale('cs'));
  final statusStore = IntegrationStatusStore(prefs);
  final ktClient = KtClient(storage: SecureStore.instance);
  final healthSource = HealthSource(prefs: prefs);
  final googleAuth = GoogleAuth(prefs);
  try {
    await googleAuth.initialize();
  } catch (e, st) {
    // Don't block startup; connect/sync will surface the problem.
    AppLog.auth.error('GoogleSignIn.initialize failed', err: e, stackTrace: st);
  }
  final trackerSheet = TrackerSheet(SheetsGateway(googleAuth));
  final ktSource = KtSource(ktClient);
  final syncController = SyncController(
    SyncEngine(
      prefs: prefs,
      health: healthSource,
      kt: ktSource,
      sheet: trackerSheet,
    ),
    SyncHistory(prefs, statusStore),
    keepAlive: ForegroundServiceKeepAlive(
      intents,
      title: l10n.syncServiceTitle,
      text: l10n.syncServiceText,
      channelName: l10n.syncServiceChannel,
    ),
  );
  await syncController.reload();
  // Register (or cancel) the automatic sync on every start (plan Phase 6).
  await BackgroundSync.apply(prefs);

  // First-launch setup only while nothing is configured yet; an existing
  // setup counts as done.
  var showOnboarding = !await prefs.onboardingDone();
  if (showOnboarding &&
      (await prefs.spreadsheetId() != null ||
          await prefs.googleAccount() != null ||
          await ktClient.storedEmail() != null)) {
    await prefs.setOnboardingDone();
    showOnboarding = false;
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsStore>.value(value: prefs),
        Provider<SystemIntents>.value(value: intents),
        Provider<IntegrationStatusStore>.value(value: statusStore),
        Provider<KtClient>.value(value: ktClient),
        Provider<KtSource>.value(value: ktSource),
        ChangeNotifierProvider<SyncController>.value(value: syncController),
        ChangeNotifierProvider(
          create: (_) => AutoSyncController(prefs, intents),
        ),
        Provider<HealthSource>.value(value: healthSource),
        ChangeNotifierProvider<PersistentLogBuffer>.value(value: logBuffer),
        ChangeNotifierProvider(
          create: (_) => HealthConnectController(healthSource, intents),
        ),
        ChangeNotifierProvider(
          create: (_) => KtController(ktClient, statusStore),
        ),
        Provider<GoogleAuth>.value(value: googleAuth),
        Provider<TrackerSheet>.value(value: trackerSheet),
        Provider<DriveChooser>(create: (_) => DriveChooser(googleAuth)),
        ChangeNotifierProvider(
          create: (_) => GoogleController(googleAuth, statusStore),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              SheetController(prefs, trackerSheet, googleAuth, statusStore),
        ),
      ],
      child: ForgelinkApp(showOnboarding: showOnboarding),
    ),
  );
}
