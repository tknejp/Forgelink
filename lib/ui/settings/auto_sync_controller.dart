import 'package:flutter/foundation.dart';

import '../../background/background_sync.dart';
import '../../core/prefs_store.dart';
import '../../core/system_intents.dart';

/// State of Settings → Automatická synchronizace.
class AutoSyncController extends ChangeNotifier {
  AutoSyncController(this._prefs, this._intents, {this.scheduler});

  final PrefsStore _prefs;
  final SystemIntents _intents;

  /// Registers/cancels the WorkManager task; replaceable in tests.
  final Future<void> Function(PrefsStore prefs)? scheduler;

  bool enabled = false;
  bool ignoringBattery = false;
  bool notifySuccess = true;
  DateTime? nextRun;

  Future<void> load() async {
    enabled = await _prefs.autoSync();
    notifySuccess = await _prefs.notifySuccess();
    nextRun = enabled ? await _prefs.nextBackgroundRun() : null;
    ignoringBattery = await _intents.isIgnoringBatteryOptimizations();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    notifyListeners();
    await _prefs.setAutoSync(value);
    await (scheduler ?? BackgroundSync.apply)(_prefs);
    await load();
  }

  Future<void> setNotifySuccess(bool value) async {
    notifySuccess = value;
    notifyListeners();
    await _prefs.setNotifySuccess(value);
  }

  Future<void> requestBatteryExemption() async {
    await _intents.requestIgnoreBatteryOptimizations();
    // The result comes back via the system dialog; re-check on resume.
  }

  Future<void> openAppDetails() => _intents.openAppDetails();
}
