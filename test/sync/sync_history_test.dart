import 'package:flutter_test/flutter_test.dart';
import 'package:forgelink/core/app_config.dart';
import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/prefs_store.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/core/sync_issue_codec.dart';
import 'package:forgelink/sync/integration_status.dart';
import 'package:forgelink/sync/sync_controller.dart';
import 'package:forgelink/sync/sync_engine.dart';
import 'package:forgelink/sync/sync_history.dart';
import 'package:forgelink/sync/sync_models.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'sync_fakes.dart';

void main() {
  final day = LocalDate(2026, 10, 14);
  late PrefsStore prefs;
  late IntegrationStatusStore statuses;
  late SyncHistory history;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = PrefsStore();
    statuses = IntegrationStatusStore(prefs);
    history = SyncHistory(prefs, statuses);
  });

  RunResult run({
    Map<SheetColumn, FieldOutcome>? fields,
    List<SyncIssue> issues = const [],
    SyncIssue? dayIssue,
  }) {
    final f = fields ??
        {SheetColumn.weight: const FieldOutcome(FieldOutcomeKind.written, value: 106.3)};
    return RunResult(
      trigger: SyncTrigger.calendar,
      startedAt: DateTime(2026, 10, 15, 8),
      finishedAt: DateTime(2026, 10, 15, 8, 0, 5),
      days: [
        DayResult(
          date: day,
          status: DayResult.statusOf(f, dayIssue),
          fields: f,
          issue: dayIssue,
        ),
      ],
      issues: issues,
    );
  }

  group('codec', () {
    test('every issue round-trips', () {
      final all = <SyncIssue>[
        const KtCredentialsMissing(),
        const SheetNoEditAccess('tom@example.com'),
        const SheetTabMissing('tracker'),
        const SheetLayoutChanged('tracker'),
        DateNotInSheet(day),
        DateDuplicated(day, const [883, 893]),
        const CellHasFormula('C883'),
        const HcPermissionMissing({HcDataType.weight}),
        HcReadFailed(day),
        NoData(DataSource.kt, day),
        const Offline(),
      ];
      for (final i in all) {
        final back = SyncIssueCodec.decode(SyncIssueCodec.encode(i));
        expect(back.code, i.code);
        expect(SyncIssueCodec.encode(back), SyncIssueCodec.encode(i));
      }
    });
  });

  test('records the run, per-date status and last success', () async {
    await history.record(run());
    expect((await history.runs()).single.days.single.date, day);
    expect((await history.days())[day]!.status, DayStatus.ok);
    expect((await history.lastSuccess())!.trigger, SyncTrigger.calendar);
    expect((await statuses.load(Integration.googleSheets))!.state,
        IntegrationState.verified);
  });

  test('a run with failures does not update last success', () async {
    await history.record(run(fields: {
      SheetColumn.weight: const FieldOutcome(FieldOutcomeKind.written, value: 1),
      SheetColumn.kcal: const FieldOutcome(FieldOutcomeKind.failed,
          issue: KtUnavailable()),
    }, issues: const [KtUnavailable()]));
    expect(await history.lastSuccess(), isNull);
  });

  test('open issues persist until a later run proves the area', () async {
    await history.record(run(
      fields: {
        SheetColumn.kcal: const FieldOutcome(FieldOutcomeKind.failed,
            issue: KtAuthRejected()),
      },
      issues: const [KtAuthRejected()],
    ));
    expect((await history.openIssues()).single, isA<KtAuthRejected>());
    expect((await statuses.load(Integration.kt))!.state, IntegrationState.error);

    // An unrelated weight-only success keeps the KT issue open.
    await history.record(run());
    expect((await history.openIssues()).single, isA<KtAuthRejected>());

    // A KT field succeeding clears it.
    await history.record(run(fields: {
      SheetColumn.kcal: const FieldOutcome(FieldOutcomeKind.written, value: 2000),
    }));
    expect(await history.openIssues(), isEmpty);
    expect((await statuses.load(Integration.kt))!.state,
        IntegrationState.verified);
  });

  test('date-level issues never become open issues', () async {
    await history.record(run(fields: const {}, dayIssue: DateNotInSheet(day),
        issues: const []));
    expect(await history.openIssues(), isEmpty);
  });

  test('dismiss removes an open issue', () async {
    await history.record(run(issues: const [Offline()]));
    // Offline is in the general area; the same run proved it, so re-add.
    await history.record(run(fields: const {
      SheetColumn.kcal: FieldOutcome(FieldOutcomeKind.failed, issue: Offline()),
    }, issues: const [Offline()]));
    expect(await history.openIssues(), isNotEmpty);
    await history.dismiss(const Offline());
    expect(await history.openIssues(), isEmpty);
  });

  test('run log is capped', () async {
    for (var i = 0; i < SyncHistory.maxRuns + 5; i++) {
      await history.record(run());
    }
    expect(await history.runs(), hasLength(SyncHistory.maxRuns));
  });

  group('SyncController', () {
    late FakeHealth health;
    late SyncController controller;

    setUp(() async {
      await prefs.setSpreadsheetId('sheet');
      await prefs.setGoogleAccount(email: 'tom@example.com', userId: '1');
      health = FakeHealth()..weights[LocalDate(2026, 10, 15)] = 105.9;
      controller = SyncController(
        SyncEngine(
          prefs: prefs,
          health: health,
          kt: FakeKt(),
          sheet: FakeSheet(),
          now: () => DateTime(2026, 10, 15, 8),
        ),
        history,
        now: () => DateTime(2026, 10, 15, 8),
      );
    });

    test('a second request while busy is ignored', () async {
      final first = controller.syncDate(LocalDate(2026, 10, 15));
      expect(controller.busy, isTrue);
      expect(await controller.syncDate(LocalDate(2026, 10, 14)), isNull);
      await first;
      expect(controller.busy, isFalse);
    });

    test('reload picks up the persisted run', () async {
      await controller.syncDate(LocalDate(2026, 10, 15));
      final other = SyncController(
          SyncEngine(
              prefs: prefs,
              health: health,
              kt: FakeKt(),
              sheet: FakeSheet()),
          SyncHistory(prefs, statuses));
      await other.reload();
      expect(other.lastRun, isNotNull);
      expect(other.days[LocalDate(2026, 10, 15)]!.status, DayStatus.ok);
    });

    test('range longer than the cap is rejected', () {
      expect(
        () => controller.syncRange(
            LocalDate(2026, 1, 1), LocalDate(2026, 10, 15)),
        throwsArgumentError,
      );
    });
  });
}
