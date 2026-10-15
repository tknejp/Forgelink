import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/log_buffer.dart';
import 'core/prefs_store.dart';
import 'core/system_intents.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('cs');

  final prefs = PrefsStore();
  final logBuffer = PersistentLogBuffer(prefs);
  AppLog.sink = logBuffer;
  await logBuffer.load();
  AppLog.app.info('Forgelink starting');

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsStore>.value(value: prefs),
        Provider<SystemIntents>.value(value: const SystemIntents()),
        ChangeNotifierProvider<PersistentLogBuffer>.value(value: logBuffer),
      ],
      child: const ForgelinkApp(),
    ),
  );
}
