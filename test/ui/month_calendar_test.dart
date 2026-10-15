import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/l10n/app_localizations.dart';
import 'package:forgelink/sync/integration_status.dart';
import 'package:forgelink/sync/sync_controller.dart';
import 'package:forgelink/sync/sync_engine.dart';
import 'package:forgelink/sync/sync_history.dart';
import 'package:forgelink/ui/home/month_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../sync/sync_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('cs'));

  late List<String> events;

  Future<void> pump(WidgetTester tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = PrefsStore();
    // "Today" = 16.10.2026, so 17.+ are future.
    DateTime now() => DateTime(2026, 10, 16, 9);
    final controller = SyncController(
      SyncEngine(
          prefs: prefs,
          health: FakeHealth(),
          kt: FakeKt(),
          sheet: FakeSheet(),
          now: now),
      SyncHistory(prefs, IntegrationStatusStore(prefs)),
      now: now,
    );
    events = [];
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        locale: const Locale('cs'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthCalendar(
              onTapDay: (d) => events.add('tap $d'),
              onLongPressDay: (d) => events.add('detail $d'),
              onSelectRange: (a, b) => events.add('range $a..$b'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('tap syncs a single day', (tester) async {
    await pump(tester);
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(events.single, startsWith('tap '));
  });

  testWidgets('hold without moving opens the day detail', (tester) async {
    await pump(tester);
    await tester.longPress(find.text('6'));
    await tester.pump();
    expect(events.single, startsWith('detail '));
  });

  testWidgets('hold and drag selects a range', (tester) async {
    await pump(tester);
    final start = tester.getCenter(find.text('5'));
    final end = tester.getCenter(find.text('9'));
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final from = LocalDate(2026, 10, 5);
    final to = LocalDate(2026, 10, 9);
    expect(events.single, 'range $from..$to');
  });

  testWidgets('dragging into the future stops at today', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.text('14')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('20')));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(events.single,
        'range ${LocalDate(2026, 10, 14)}..${LocalDate(2026, 10, 16)}');
  });

  testWidgets('future days ignore taps', (tester) async {
    await pump(tester);
    await tester.tap(find.text('20'));
    await tester.pump();
    expect(events, isEmpty);
  });
}
