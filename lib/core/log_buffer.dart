import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_log.dart';
import 'prefs_store.dart';

/// Ring buffer of the most recent important log lines (warnings, errors and
/// `success` lines such as run summaries), persisted in prefs so they survive
/// restarts and are visible in release builds under Settings → Diagnostika.
class PersistentLogBuffer extends ChangeNotifier implements LogSink {
  PersistentLogBuffer(this._prefs, {this.capacity = 300});

  final PrefsStore _prefs;
  final int capacity;
  final List<String> _lines = [];
  Timer? _flushTimer;

  List<String> get lines => List.unmodifiable(_lines);

  /// Loads previously persisted lines. Lines logged before [load] completes
  /// are kept after the loaded ones.
  Future<void> load() async {
    final stored = await _prefs.logLines();
    _lines.insertAll(0, stored);
    _trim();
    notifyListeners();
  }

  @override
  void add(LogLevel level, String line) {
    if (level != LogLevel.warn &&
        level != LogLevel.error &&
        level != LogLevel.success) {
      return;
    }
    _lines.add(line);
    _trim();
    _scheduleFlush();
    notifyListeners();
  }

  Future<void> clear() async {
    _lines.clear();
    await _prefs.setLogLines(const []);
    notifyListeners();
  }

  void _trim() {
    if (_lines.length > capacity) {
      _lines.removeRange(0, _lines.length - capacity);
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_prefs.setLogLines(List.of(_lines)));
    });
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}
