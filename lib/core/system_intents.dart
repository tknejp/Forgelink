import 'package:flutter/services.dart';

import 'app_log.dart';

/// Native intents the plugins don't cover. Backed by the
/// `forgelink/system_intents` channel in `MainActivity.kt`.
class SystemIntents {
  const SystemIntents();

  static const _channel = MethodChannel('forgelink/system_intents');

  /// Opens Health Connect settings (falls back to the HC app, then its
  /// app-details page). Returns false when nothing could be opened.
  Future<bool> openHealthConnectSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openHealthConnectSettings') ??
          false;
    } on PlatformException catch (e, st) {
      AppLog.health.error('openHealthConnectSettings failed',
          err: e, stackTrace: st);
      return false;
    }
  }
}
