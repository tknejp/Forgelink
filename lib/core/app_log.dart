import 'package:flutter/foundation.dart';

// Trimmed port of Forgetrack's lib/core/logging/app_log.dart: Sentry removed,
// `[Forgelink]` prefix, plus an optional persisted sink so warnings and
// errors stay inspectable in release builds (Settings → Diagnostika).

// ─── ANSI colors ──────────────────────────────────────────────────────────────

abstract final class _Ansi {
  static const reset = '\x1B[0m';

  static const gray = '\x1B[90m';
  static const blue = '\x1B[34m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const red = '\x1B[31m';
}

// ─── Log levels ───────────────────────────────────────────────────────────────

enum LogLevel {
  debug,
  info,
  success,
  warn,
  error;

  String get _prefix => switch (this) {
    debug => '·',
    info => 'ℹ',
    success => '✓',
    warn => '⚠',
    error => '✖',
  };

  String get _tag => switch (this) {
    debug => 'DEBUG',
    info => 'INFO ',
    success => 'OK   ',
    warn => 'WARN ',
    error => 'ERROR',
  };

  String get _ansiColor => switch (this) {
    debug => _Ansi.gray,
    info => _Ansi.blue,
    success => _Ansi.green,
    warn => _Ansi.yellow,
    error => _Ansi.red,
  };
}

bool _shouldPrint(LogLevel level) {
  if (kReleaseMode) return false;
  if (kProfileMode) return level.index >= LogLevel.warn.index;
  return true;
}

/// Receives log lines independently of the console gate. Installed once at
/// bootstrap (see `PersistentLogBuffer`).
abstract interface class LogSink {
  void add(LogLevel level, String line);
}

// ─── Logger ───────────────────────────────────────────────────────────────────

class AppLogger {
  final String domain;
  final String? scope;

  const AppLogger(this.domain, {this.scope});

  void _emit(
    LogLevel level,
    String message, {
    Object? payload,
    Object? err,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';

    final domainTag = scope != null ? '[$domain][$scope]' : '[$domain]';
    final payloadStr = payload != null ? '  | $payload' : '';
    final errStr = err != null ? '  | err: $err' : '';
    final line = '[$ts][${level._tag}]$domainTag $message$payloadStr$errStr';

    AppLog.sink?.add(level, line);

    if (!_shouldPrint(level)) return;

    debugPrint(
      '${level._ansiColor}${level._prefix} [Forgelink]$line${_Ansi.reset}',
    );

    if (stackTrace != null) {
      for (final frame in stackTrace.toString().trimRight().split('\n')) {
        debugPrint('${_Ansi.red}[Forgelink] $frame${_Ansi.reset}');
      }
    }
  }

  void debug(String message, {Object? payload}) =>
      _emit(LogLevel.debug, message, payload: payload);

  void info(String message, {Object? payload}) =>
      _emit(LogLevel.info, message, payload: payload);

  void success(String message, {Object? payload}) =>
      _emit(LogLevel.success, message, payload: payload);

  void warn(String message, {Object? payload}) =>
      _emit(LogLevel.warn, message, payload: payload);

  void error(
    String message, {
    Object? payload,
    Object? err,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.error,
    message,
    payload: payload,
    err: err,
    stackTrace: stackTrace,
  );
}

// ─── Namespace ────────────────────────────────────────────────────────────────

abstract final class AppLog {
  /// Optional persisted sink; null in tests and before bootstrap.
  static LogSink? sink;

  static const app = AppLogger('APP');
  static const auth = AppLogger('AUTH');
  static const health = AppLogger('HEALTH');
  static const sheets = AppLogger('SHEETS');
  static const sync = AppLogger('SYNC');

  // Kept so the KT files ported from Forgetrack compile unchanged.
  static const kt = AppLogger('KT');
  static const ktApi = AppLogger('KT', scope: 'API');
  static const ktParse = AppLogger('KT', scope: 'PARSE');
}

/// Masks an email for logs: `jan.novak@example.com` → `j***@example.com`.
/// Never throws (empty local part or no `@` included).
String maskEmail(String? email) {
  if (email == null || email.isEmpty) return '<none>';
  final at = email.indexOf('@');
  if (at < 0) return '***';
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  if (local.isEmpty) return '***@$domain';
  return '${local[0]}***@$domain';
}
