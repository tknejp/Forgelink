import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/app.dart';
import 'package:forgelink/core/log_buffer.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/core/system_intents.dart';
import 'package:forgelink/l10n/app_localizations.dart';
import 'package:forgelink/ui/settings/settings_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _withProviders(Widget child) {
  final prefs = PrefsStore();
  return MultiProvider(
    providers: [
      Provider<PrefsStore>.value(value: prefs),
      Provider<SystemIntents>.value(value: const SystemIntents()),
      ChangeNotifierProvider(create: (_) => PersistentLogBuffer(prefs)),
    ],
    child: child,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('cs'));

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('home renders in Czech with the brand title', (tester) async {
    await tester.pumpWidget(_withProviders(const ForgelinkApp()));
    await tester.pumpAndSettle();

    expect(find.text('Forgelink'), findsOneWidget);
    expect(find.text('Synchronizovat'), findsOneWidget);
    expect(find.text('Včera: výživa a kroky · Dnes: váha'), findsOneWidget);
  });

  testWidgets('settings deep link scrolls to the target section',
      (tester) async {
    await tester.pumpWidget(_withProviders(
      const MaterialApp(
        locale: Locale('cs'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: SettingsScreen(initialSection: SettingsSection.diagnostics),
      ),
    ));
    await tester.pump(); // post-frame reveal starts
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Diagnostika'), findsOneWidget);
    final rect = tester.getRect(find.text('Diagnostika'));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.top, lessThan(screen.height));

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('dark theme follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(_withProviders(const ForgelinkApp()));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Forgelink'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
