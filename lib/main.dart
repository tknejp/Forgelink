import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/log_buffer.dart';
import 'core/prefs_store.dart';
import 'core/secure_store.dart';
import 'core/system_intents.dart';
import 'sources/health/health_source.dart';
import 'sources/kt/kt_client.dart';
import 'sources/kt/kt_source.dart';
import 'sync/integration_status.dart';
import 'ui/settings/health_connect_controller.dart';
import 'ui/settings/kt_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('cs');

  final prefs = PrefsStore();
  final logBuffer = PersistentLogBuffer(prefs);
  AppLog.sink = logBuffer;
  await logBuffer.load();
  AppLog.app.info('Forgelink starting');

  const intents = SystemIntents();
  final statusStore = IntegrationStatusStore(prefs);
  final ktClient = KtClient(storage: SecureStore.instance);
  final healthSource = HealthSource(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsStore>.value(value: prefs),
        Provider<SystemIntents>.value(value: intents),
        Provider<IntegrationStatusStore>.value(value: statusStore),
        Provider<KtClient>.value(value: ktClient),
        Provider<KtSource>(create: (_) => KtSource(ktClient)),
        Provider<HealthSource>.value(value: healthSource),
        ChangeNotifierProvider<PersistentLogBuffer>.value(value: logBuffer),
        ChangeNotifierProvider(
          create: (_) => HealthConnectController(healthSource, intents),
        ),
        ChangeNotifierProvider(
          create: (_) => KtController(ktClient, statusStore),
        ),
      ],
      child: const ForgelinkApp(),
    ),
  );
}
