import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../core/sync_issue.dart';
import '../../core/system_intents.dart';
import '../../sources/health/hc_read_client.dart';
import '../../sources/health/health_source.dart';
import '../../sync/integration_status.dart';

/// State of Settings → Health Connect. All checks are local IPC (no network),
/// so [refresh] runs on open and on every app resume.
class HealthConnectController extends ChangeNotifier {
  HealthConnectController(this._source, this._intents);

  final HealthSource _source;
  final SystemIntents _intents;

  HcAvailability? availability;
  Set<HcDataType> missing = const {};
  bool historyAvailable = false;
  bool historyAuthorized = false;
  bool busy = false;
  bool _loaded = false;

  bool get loaded => _loaded;

  IntegrationStatus get status {
    if (!_loaded) return IntegrationStatus.notConfigured;
    if (availability != HcAvailability.available) {
      return const IntegrationStatus(
          IntegrationState.notConfigured, HcNotAvailable());
    }
    if (missing.isNotEmpty) {
      return IntegrationStatus(
          IntegrationState.notConfigured, HcPermissionMissing(missing));
    }
    return IntegrationStatus.configured;
  }

  Future<void> refresh() async {
    try {
      availability = await _source.availability();
      if (availability == HcAvailability.available) {
        missing = await _source.missingPermissions();
        historyAvailable = await _source.isHistoryAvailable();
        historyAuthorized = await _source.isHistoryAuthorized();
      } else {
        missing = HcDataType.values.toSet();
      }
    } catch (e, st) {
      AppLog.health.error('Health Connect status refresh failed',
          err: e, stackTrace: st);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> install() => _run(_source.installOrUpdate);

  /// Requests steps + weight. If the dialog can't help (e.g. the user denied
  /// twice, so Android stops showing it), opens Health Connect settings.
  Future<void> grantPermissions() => _run(() async {
        final granted = await _source.requestPermissions();
        if (!granted) await _intents.openHealthConnectSettings();
      });

  Future<void> grantHistory() => _run(() async {
        final granted = await _source.requestHistoryAuthorization();
        if (!granted) await _intents.openHealthConnectSettings();
      });

  Future<void> openSettings() => _run(_intents.openHealthConnectSettings);

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } catch (e, st) {
      AppLog.health.error('Health Connect action failed',
          err: e, stackTrace: st);
    } finally {
      busy = false;
      await refresh();
    }
  }
}
