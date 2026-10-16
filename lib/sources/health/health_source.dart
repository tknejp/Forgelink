import 'package:flutter/services.dart';
import 'package:health/health.dart';

import '../../core/app_log.dart';
import '../../core/local_date.dart';
import '../../core/prefs_store.dart';
import '../../core/sync_issue.dart';
import 'hc_read_client.dart';

/// Health Connect as a sync source: preflight, steps and weight per local
/// calendar day (docs/implementation_plan.md §3).
///
/// Return-value contract:
/// - `null` = missing data (leave the cell untouched),
/// - a value = write it,
/// - [SyncIssueException] = a failure for that day / type.
class HealthSource {
  HealthSource({
    required PrefsStore prefs,
    HcReadClient? client,
    DateTime Function()? now,
    this.requireBackgroundPermission = false,
  }) : _prefs = prefs,
       _client = client ?? HcReadClient(),
       _now = now ?? DateTime.now;

  /// True in the Phase 6 worker: reads there only work with Health Connect's
  /// background-read permission, and without it the plugin would return
  /// empty results that look like "no data".
  final bool requireBackgroundPermission;

  final PrefsStore _prefs;
  final HcReadClient _client;
  final DateTime Function() _now;

  static const _typeMap = {
    HcDataType.steps: HealthDataType.STEPS,
    HcDataType.weight: HealthDataType.WEIGHT,
  };

  /// Health Connect only allows reads back to 30 days before the app's first
  /// permission grant; older days need the history permission.
  static const historyWindowDays = 30;

  // ─── Status / permissions ───────────────────────────────────────────────

  Future<HcAvailability> availability() async {
    try {
      return await _client.availability();
    } on PlatformException catch (e) {
      AppLog.health.warn('availability check failed', payload: '$e');
      return HcAvailability.notInstalled;
    }
  }

  Future<void> installOrUpdate() => _client.installHealthConnect();

  /// Read types (of [needed]) that are not granted. Records the first-grant
  /// date the first time everything Forgelink needs is granted.
  Future<Set<HcDataType>> missingPermissions([
    Set<HcDataType> needed = const {HcDataType.steps, HcDataType.weight},
  ]) async {
    final missing = <HcDataType>{};
    for (final type in needed) {
      if (!await _client.hasReadPermission(_typeMap[type]!)) missing.add(type);
    }
    if (missing.isEmpty && needed.length == HcDataType.values.length) {
      await _prefs.recordHcFirstGrant(LocalDate.fromDateTime(_now()));
    }
    return missing;
  }

  /// Opens the Health Connect permission dialog for steps + weight.
  /// Returns true when both end up granted.
  Future<bool> requestPermissions() async {
    await _client.requestReadPermissions([
      for (final t in HcDataType.values) _typeMap[t]!,
    ]);
    // The request's own Boolean is unreliable — re-check.
    return (await missingPermissions()).isEmpty;
  }

  Future<bool> isHistoryAvailable() => _client.isHistoryAvailable();

  Future<bool> isHistoryAuthorized() => _client.isHistoryAuthorized();

  Future<bool> requestHistoryAuthorization() async {
    await _client.requestHistoryAuthorization();
    return _client.isHistoryAuthorized();
  }

  Future<bool> isBackgroundAvailable() => _client.isBackgroundAvailable();

  Future<bool> isBackgroundAuthorized() => _client.isBackgroundAuthorized();

  /// Lets reads continue after the user leaves the app (manual sync in the
  /// background now, automatic sync in Phase 6).
  Future<bool> requestBackgroundAuthorization() async {
    await _client.requestBackgroundAuthorization();
    return _client.isBackgroundAuthorized();
  }

  /// Run-level preflight for the [needed] types. Returns the blocking issue
  /// for Health Connect, or null when reads can be trusted.
  Future<SyncIssue?> preflight(Set<HcDataType> needed) async {
    if (needed.isEmpty) return null;
    if (await availability() != HcAvailability.available) {
      return const HcNotAvailable();
    }
    final missing = await missingPermissions(needed);
    if (missing.isNotEmpty) return HcPermissionMissing(missing);
    if (requireBackgroundPermission &&
        !(await _client.isBackgroundAvailable() &&
            await _client.isBackgroundAuthorized())) {
      return const HcBackgroundPermissionMissing();
    }
    return null;
  }

  /// [HcHistoryPermissionMissing] when [day] lies before the readable window
  /// and the history permission is not granted; otherwise null.
  Future<SyncIssue?> historyGate(LocalDate day) async {
    final firstGrant =
        await _prefs.hcFirstGrantDate() ?? LocalDate.fromDateTime(_now());
    final windowStart = firstGrant.addDays(-historyWindowDays);
    if (!day.isBefore(windowStart)) return null;
    if (await _client.isHistoryAuthorized()) return null;
    return const HcHistoryPermissionMissing();
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  /// De-duplicated daily step total. `0` → null (Health Connect can't store a
  /// 0-count record, so 0 means no data). A native error → [HcReadFailed].
  Future<int?> steps(LocalDate day) async {
    int? total;
    try {
      total = await _client.totalSteps(day.startOfDay, day.endOfDay);
    } on PlatformException catch (e) {
      throw SyncIssueException(HcReadFailed(day), e);
    }
    if (total == null) {
      AppLog.health.warn('steps($day): aggregate returned null');
      throw SyncIssueException(HcReadFailed(day));
    }
    AppLog.health.debug('steps($day) = $total');
    return total > 0 ? total : null;
  }

  /// The last weight reading whose local timestamp falls on [day], rounded
  /// to 1 decimal. Null when there is none (or the value is not positive).
  Future<double?> lastWeight(LocalDate day) async {
    final start = day.startOfDay;
    final end = day.endOfDay;
    final List<WeightSample> samples;
    try {
      samples = await _client.weightSamples(start, end);
    } on PlatformException catch (e) {
      throw SyncIssueException(HcReadFailed(day), e);
    }

    final inDay =
        samples
            .where((s) => !s.time.isBefore(start) && s.time.isBefore(end))
            .toList()
          ..sort((a, b) {
            final byTime = a.time.compareTo(b.time);
            return byTime != 0 ? byTime : a.source.compareTo(b.source);
          });
    if (inDay.isEmpty) {
      AppLog.health.debug('lastWeight($day): no readings');
      return null;
    }
    final last = inDay.last;
    if (last.kg <= 0) return null;
    final rounded = (last.kg * 10).round() / 10;
    AppLog.health.debug(
      'lastWeight($day) = $rounded',
      payload: 'readings=${inDay.length}, source=${last.source}',
    );
    return rounded;
  }
}
