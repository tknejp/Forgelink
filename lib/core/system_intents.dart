import 'package:flutter/services.dart';

import '../sync/sync_controller.dart';
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
      AppLog.health.error(
        'openHealthConnectSettings failed',
        err: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Starts the foreground service that keeps a manual sync alive in the
  /// background (`SyncForegroundService.kt`).
  Future<void> startSyncService({
    required String title,
    required String text,
    required String channelName,
  }) async {
    try {
      await _channel.invokeMethod<void>('startSyncService', {
        'title': title,
        'text': text,
        'channel': channelName,
      });
    } on PlatformException catch (e) {
      // Not fatal: the sync still runs, it just may be paused in background.
      AppLog.sync.warn('startSyncService failed', payload: '$e');
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } catch (_) {
      return false; // no channel (tests, headless engine)
    }
  }

  /// System dialog that exempts Forgelink from battery optimisation, which
  /// also keeps it out of the restricted standby bucket.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      AppLog.sync.warn(
        'requestIgnoreBatteryOptimizations failed',
        payload: '$e',
      );
    }
  }

  /// App details screen ("Pause app activity if unused" lives there).
  Future<void> openAppDetails() async {
    try {
      await _channel.invokeMethod<void>('openAppDetails');
    } catch (e) {
      AppLog.sync.warn('openAppDetails failed', payload: '$e');
    }
  }

  /// Opens [url] in the app that handles it (Google Sheets or the browser).
  Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod<void>('openUrl', {'url': url});
    } catch (e) {
      AppLog.app.warn('openUrl failed', payload: '$e');
    }
  }

  Future<void> stopSyncService() async {
    try {
      await _channel.invokeMethod<void>('stopSyncService');
    } on PlatformException catch (e) {
      AppLog.sync.warn('stopSyncService failed', payload: '$e');
    }
  }
}

/// [SyncKeepAlive] backed by the Android foreground service.
class ForegroundServiceKeepAlive implements SyncKeepAlive {
  const ForegroundServiceKeepAlive(
    this._intents, {
    required this.title,
    required this.text,
    required this.channelName,
  });

  final SystemIntents _intents;
  final String title;
  final String text;
  final String channelName;

  @override
  Future<void> start() => _intents.startSyncService(
    title: title,
    text: text,
    channelName: channelName,
  );

  @override
  Future<void> stop() => _intents.stopSyncService();
}
