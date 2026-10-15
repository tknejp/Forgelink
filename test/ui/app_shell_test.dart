import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/sources/health/health_source.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:forgelink/sync/integration_status.dart';
import 'package:forgelink/ui/settings/health_connect_controller.dart';
import 'package:forgelink/core/sync_issue.dart' as issues;
import 'package:forgelink/sheets/google_auth.dart';
import 'package:forgelink/sheets/sheets_gateway.dart';
import 'package:forgelink/sheets/tracker_sheet.dart';
import 'package:forgelink/ui/settings/google_controller.dart';
import 'package:forgelink/ui/settings/kt_controller.dart';
import 'package:forgelink/ui/settings/sheet_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

import '../sources/health/fake_hc_read_client.dart';

Widget _withProviders(Widget child) {
  final prefs = PrefsStore();
  const intents = SystemIntents();
  final health = HealthSource(prefs: prefs, client: FakeHcReadClient());
  final kt = KtClient(
    storage: const FlutterSecureStorage(),
    client: MockClient((_) async => http.Response('', 500)),
  );
  return MultiProvider(
    providers: [
      Provider<PrefsStore>.value(value: prefs),
      Provider<SystemIntents>.value(value: intents),
      ChangeNotifierProvider(create: (_) => PersistentLogBuffer(prefs)),
      ChangeNotifierProvider(
          create: (_) => HealthConnectController(health, intents)),
      ChangeNotifierProvider(
          create: (_) => KtController(kt, IntegrationStatusStore(prefs))),
      ChangeNotifierProvider(
          create: (_) =>
              GoogleController(GoogleAuth(prefs), IntegrationStatusStore(prefs))),
      ChangeNotifierProvider(
          create: (_) => SheetController(
                prefs,
                TrackerSheet(SheetsGateway(_NoTokens())),
                _NoTokens(),
                IntegrationStatusStore(prefs),
              )),
    ],
    child: child,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('cs'));

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({});
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
    await tester.pump(const Duration(milliseconds: 400)); // second pass
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

class _NoTokens implements TokenProvider {
  @override
  Future<String?> accountEmail() async => null;
  @override
  Future<String> accessToken({required bool interactive}) async =>
      throw const issues.SyncIssueException(issues.GoogleNotConnected());
  @override
  Future<void> invalidate(String token) async {}
}
