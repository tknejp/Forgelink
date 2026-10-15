import 'package:forgelink/core/local_date.dart';
import 'package:forgelink/core/sync_issue.dart';
import 'package:forgelink/sheets/tracker_index.dart';
import 'package:forgelink/sheets/tracker_sheet.dart';
import 'package:forgelink/sheets/write_plan.dart';
import 'package:forgelink/sources/health/hc_read_client.dart';
import 'package:forgelink/sources/health/health_source.dart';
import 'package:forgelink/sources/kt/kt_client.dart';
import 'package:forgelink/sources/kt/kt_source.dart';

import '../sheets/tracker_fixture.dart';

class FakeHealth implements HealthSource {
  SyncIssue? preflightIssue;
  SyncIssue? historyIssue;
  final weights = <LocalDate, double?>{};
  final stepCounts = <LocalDate, int?>{};
  final failing = <LocalDate>{};
  final calls = <String>[];

  @override
  Future<SyncIssue?> preflight(Set<HcDataType> needed) async {
    calls.add('preflight:${needed.map((t) => t.name).toList()..sort()}');
    return needed.isEmpty ? null : preflightIssue;
  }

  @override
  Future<SyncIssue?> historyGate(LocalDate day) async => historyIssue;

  @override
  Future<double?> lastWeight(LocalDate day) async {
    calls.add('weight:$day');
    if (failing.contains(day)) throw SyncIssueException(HcReadFailed(day));
    return weights[day];
  }

  @override
  Future<int?> steps(LocalDate day) async {
    calls.add('steps:$day');
    if (failing.contains(day)) throw SyncIssueException(HcReadFailed(day));
    return stepCounts[day];
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeKt implements KtSource {
  bool credentials = true;
  SyncIssue? failWith;
  final days = <LocalDate, KtDayNutrition>{};
  final calls = <LocalDate>[];

  @override
  void beginRun() {}

  @override
  Future<bool> hasCredentials() async => credentials;

  @override
  Future<KtDayNutrition> fetchDay(LocalDate date) async {
    calls.add(date);
    if (failWith != null) throw SyncIssueException(failWith!);
    return days[date] ?? const KtDayNutrition(kcal: 0, protein: 0);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeSheet implements TrackerSheet {
  FakeSheet({TrackerIndex? index})
      : index = index ??
            TrackerIndex.build(tables: [weekTable()], values: trackerValues());

  TrackerIndex index;
  SyncIssue? loadError;
  SyncIssue? writeError;
  Map<int, List<Object?>> formulas = const {};
  final writes = <WritePlan>[];

  @override
  Future<TrackerIndex> loadIndex(String spreadsheetId, String tab) async {
    if (loadError != null) throw SyncIssueException(loadError!);
    return index;
  }

  @override
  Future<Map<int, List<Object?>>> loadFormulas(
          String spreadsheetId, String tab, TrackerIndex index) async =>
      formulas;

  @override
  Future<int> write(String spreadsheetId, WritePlan plan) async {
    if (writeError != null) throw SyncIssueException(writeError!);
    writes.add(plan);
    return plan.cellsToWrite;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Real-looking nutrition for a logged day.
const loggedDay = KtDayNutrition(
  kcal: 2700.4,
  protein: 216.009,
  carbs: 308.422,
  fat: 61.2185,
  fiber: 26.645,
);

/// Silences "unused" lints for HcAvailability in fakes that don't need it.
const unusedAvailability = HcAvailability.available;
