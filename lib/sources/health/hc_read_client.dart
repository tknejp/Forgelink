import 'package:health/health.dart';

import '../../core/app_log.dart';

/// Health Connect availability as Forgelink sees it.
enum HcAvailability { available, needsUpdate, notInstalled }

/// One weight reading: local timestamp, kilograms, source app.
typedef WeightSample = ({DateTime time, double kg, String source});

/// Thin wrapper over the `health` plugin (trimmed port of Forgetrack's
/// HcReadClient). Every plugin call goes through here so tests can fake it.
///
/// Plugin quirks this class exposes honestly instead of hiding:
/// - `getTotalStepsInInterval` returns 0 for "no data" and null on any
///   native error; it does no availability check of its own.
/// - `getHealthDataFromTypes` returns an empty list on missing permission or
///   error, so callers must run a permission preflight first.
class HcReadClient {
  HcReadClient({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _log = AppLog.health;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Always call this first in a run: besides reporting availability it
  /// re-initializes the plugin's native client if Health Connect became
  /// available after the plugin attached.
  Future<HcAvailability> availability() async {
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    _log.debug('Health Connect SDK status: $status');
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable => HcAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HcAvailability.needsUpdate,
      _ => HcAvailability.notInstalled,
    };
  }

  Future<void> installHealthConnect() async {
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  Future<bool> hasReadPermission(HealthDataType type) async {
    await _ensureConfigured();
    final granted = await _health.hasPermissions(
      [type],
      permissions: const [HealthDataAccess.READ],
    );
    return granted ?? false;
  }

  Future<bool> requestReadPermissions(List<HealthDataType> types) async {
    await _ensureConfigured();
    return _health.requestAuthorization(
      types,
      permissions: [for (final _ in types) HealthDataAccess.READ],
    );
  }

  Future<bool> isHistoryAvailable() => _health.isHealthDataHistoryAvailable();

  Future<bool> isHistoryAuthorized() => _health.isHealthDataHistoryAuthorized();

  Future<bool> requestHistoryAuthorization() =>
      _health.requestHealthDataHistoryAuthorization();

  Future<bool> isBackgroundAvailable() =>
      _health.isHealthDataInBackgroundAvailable();

  Future<bool> isBackgroundAuthorized() =>
      _health.isHealthDataInBackgroundAuthorized();

  Future<bool> requestBackgroundAuthorization() =>
      _health.requestHealthDataInBackgroundAuthorization();

  /// De-duplicated step total (Health Connect Aggregate API). 0 = no data,
  /// null = native error.
  Future<int?> totalSteps(DateTime start, DateTime end) =>
      _health.getTotalStepsInInterval(start, end);

  Future<List<WeightSample>> weightSamples(DateTime start, DateTime end) async {
    await _ensureConfigured();
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WEIGHT],
      startTime: start,
      endTime: end,
      preferredUnits: const {HealthDataType.WEIGHT: HealthDataUnit.KILOGRAM},
    );
    return [
      for (final p in points)
        if (p.value is NumericHealthValue)
          (
            time: p.dateFrom,
            kg: (p.value as NumericHealthValue).numericValue.toDouble(),
            source: p.sourceName,
          ),
    ];
  }
}
