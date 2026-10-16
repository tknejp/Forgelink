import 'package:forgelink/sources/health/hc_read_client.dart';
import 'package:health/health.dart';

class FakeHcReadClient implements HcReadClient {
  HcAvailability availabilityValue = HcAvailability.available;
  Set<HealthDataType> granted = {HealthDataType.STEPS, HealthDataType.WEIGHT};
  bool historyAuthorized = false;
  Object? stepsError;
  int? stepsValue = 0;
  List<WeightSample> weights = [];
  final stepCalls = <(DateTime, DateTime)>[];

  @override
  Future<HcAvailability> availability() async => availabilityValue;

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<bool> hasReadPermission(HealthDataType type) async =>
      granted.contains(type);

  @override
  Future<bool> requestReadPermissions(List<HealthDataType> types) async {
    granted.addAll(types);
    return true;
  }

  @override
  Future<bool> isHistoryAvailable() async => true;

  @override
  Future<bool> isHistoryAuthorized() async => historyAuthorized;

  @override
  Future<bool> requestHistoryAuthorization() async => historyAuthorized = true;

  bool backgroundAuthorized = false;

  @override
  Future<bool> isBackgroundAvailable() async => true;

  @override
  Future<bool> isBackgroundAuthorized() async => backgroundAuthorized;

  @override
  Future<bool> requestBackgroundAuthorization() async =>
      backgroundAuthorized = true;

  @override
  Future<int?> totalSteps(DateTime start, DateTime end) async {
    stepCalls.add((start, end));
    if (stepsError != null) throw stepsError!;
    return stepsValue;
  }

  @override
  Future<List<WeightSample>> weightSamples(
    DateTime start,
    DateTime end,
  ) async => weights;
}
