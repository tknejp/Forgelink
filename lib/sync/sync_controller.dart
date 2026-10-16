import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../core/app_log.dart';
import '../core/local_date.dart';
import '../core/sync_issue.dart';
import 'sync_engine.dart';
import 'sync_history.dart';
import 'sync_models.dart';

/// Keeps the process alive (and its network) while manual syncs run, e.g.
/// an Android foreground service. Implemented in `core/system_intents.dart`.
abstract interface class SyncKeepAlive {
  Future<void> start();
  Future<void> stop();
}

class _NoKeepAlive implements SyncKeepAlive {
  const _NoKeepAlive();
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

class _Job {
  _Job(this.trigger, this.dates);
  final SyncTrigger trigger;
  final List<LocalDate> dates;
  final completer = Completer<RunResult?>();
}

/// UI state for syncing: a queue of requests (taps never block), progress,
/// last run, per-date statuses for the calendar, open issues, last success.
///
/// Requests that arrive while a run is in progress wait; when it ends, all
/// waiting requests are merged into one run (one sheet read for all of
/// them). Each request's future completes with the run that covered it.
class SyncController extends ChangeNotifier {
  SyncController(
    this._engine,
    this._history, {
    DateTime Function()? now,
    SyncKeepAlive keepAlive = const _NoKeepAlive(),
  }) : _now = now ?? DateTime.now,
       _keepAlive = keepAlive;

  final SyncEngine _engine;
  final SyncHistory _history;
  final DateTime Function() _now;
  final SyncKeepAlive _keepAlive;

  final List<_Job> _queue = [];
  bool _draining = false;

  /// True while a run is in progress (taps are still accepted and queued).
  bool busy = false;
  SyncProgress? progress;

  /// Dates in the run that is in progress right now.
  Set<LocalDate> running = const {};

  /// Dates waiting for the next run.
  Set<LocalDate> get queued => {for (final j in _queue) ...j.dates};

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
      _enqueue(SyncTrigger.quick, [today.addDays(-1), today]);

  Future<RunResult?> syncDate(LocalDate date) =>
      _enqueue(SyncTrigger.calendar, [date]);

  /// Inclusive range; throws [ArgumentError] when longer than
  /// [AppConfig.maxRangeDays].
  Future<RunResult?> syncRange(LocalDate from, LocalDate to) {
    final n = from.daysUntil(to) + 1;
    if (n > AppConfig.maxRangeDays) {
      throw ArgumentError('Range of $n days exceeds ${AppConfig.maxRangeDays}');
    }
    return _enqueue(SyncTrigger.range, [
      for (var i = 0; i < n; i++) from.addDays(i),
    ]);
  }

  Future<void> dismissIssue(SyncIssue issue) async {
    await _history.dismiss(issue);
    openIssues = await _history.openIssues();
    notifyListeners();
  }

  Future<RunResult?> _enqueue(SyncTrigger trigger, List<LocalDate> dates) {
    final job = _Job(trigger, dates);
    _queue.add(job);
    notifyListeners();
    if (!_draining) unawaited(_drain());
    return job.completer.future;
  }

  Future<void> _drain() async {
    _draining = true;
    await _keepAlive.start();
    try {
      while (_queue.isNotEmpty) {
        final batch = List.of(_queue);
        _queue.clear();
        final dates = {for (final j in batch) ...j.dates}.toList()..sort();
        final trigger = batch.map((j) => j.trigger).toSet().length == 1
            ? batch.first.trigger
            : SyncTrigger.calendar;

        final result = await _runOnce(trigger, dates);
        for (final j in batch) {
          j.completer.complete(result);
        }
      }
    } finally {
      await _keepAlive.stop();
      _draining = false;
    }
  }

  Future<RunResult> _runOnce(SyncTrigger trigger, List<LocalDate> dates) async {
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
