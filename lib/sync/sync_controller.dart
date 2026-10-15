import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/sync_issue.dart';
import 'sync_engine.dart';
import 'sync_history.dart';
import 'sync_models.dart';

/// UI state for syncing: busy flag (one run at a time), progress, last run,
/// per-date statuses for the calendar, open issues, last success.
class SyncController extends ChangeNotifier {
  SyncController(this._engine, this._history, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final SyncEngine _engine;
  final SyncHistory _history;
  final DateTime Function() _now;

  bool busy = false;
  SyncProgress? progress;
  Set<LocalDate> running = const {};

  RunResult? lastRun;
  Map<LocalDate, DayResult> days = const {};
  List<SyncIssue> openIssues = const [];
  LastSuccess? lastSuccess;
  List<RunResult> runs = const [];

  LocalDate get today => LocalDate.fromDateTime(_now());

  /// Re-reads everything persisted (start, resume, after a background run).
  Future<void> reload() async {
    runs = await _history.runs();
    lastRun = runs.isEmpty ? null : runs.first;
    days = await _history.days();
    openIssues = await _history.openIssues();
    lastSuccess = await _history.lastSuccess();
    notifyListeners();
  }

  /// Yesterday in full + today's weight.
  Future<RunResult?> quickSync() =>
      _run(SyncTrigger.quick, [today.addDays(-1), today]);

  Future<RunResult?> syncDate(LocalDate date) =>
      _run(SyncTrigger.calendar, [date]);

  /// Inclusive range; null when already busy, throws [ArgumentError] when
  /// longer than [AppConfig.maxRangeDays].
  Future<RunResult?> syncRange(LocalDate from, LocalDate to) {
    final n = from.daysUntil(to) + 1;
    if (n > AppConfig.maxRangeDays) {
      throw ArgumentError('Range of $n days exceeds ${AppConfig.maxRangeDays}');
    }
    return _run(
        SyncTrigger.range, [for (var i = 0; i < n; i++) from.addDays(i)]);
  }

  Future<void> dismissIssue(SyncIssue issue) async {
    await _history.dismiss(issue);
    openIssues = await _history.openIssues();
    notifyListeners();
  }

  Future<RunResult?> _run(SyncTrigger trigger, List<LocalDate> dates) async {
    if (busy) return null;
    busy = true;
    running = dates.toSet();
    progress = SyncProgress(0, dates.length);
    notifyListeners();
    try {
      final result = await _engine.run(
        trigger,
        dates,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
      );
      await _history.record(result);
      return result;
    } catch (e, st) {
      AppLog.sync.error('Run ${trigger.name} crashed', err: e, stackTrace: st);
      final crash = RunResult(
        trigger: trigger,
        startedAt: _now(),
        finishedAt: _now(),
        days: const [],
        issues: const [UnexpectedIssue()],
      );
      await _history.record(crash);
      return crash;
    } finally {
      busy = false;
      running = const {};
      progress = null;
      await reload();
    }
  }
}
