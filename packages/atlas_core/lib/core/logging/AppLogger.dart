import 'package:flutter/foundation.dart';

/// Severity of a log record, ordered from most to least verbose.
enum AppLogLevel {
  /// Fine-grained tracing of normal operation: payloads, cache hits, per-call
  /// details. Never wanted in a shipped build.
  debug(0),

  /// Expected lifecycle events worth keeping in a debug log.
  info(1),

  /// Something did not work but the app recovered: offline, retry, fallback.
  warning(2),

  /// An operation failed and its caller has to cope with a missing result.
  error(3);

  const AppLogLevel(this.severity);

  /// Numeric weight used to compare a record against [AppLogger.minLevel].
  final int severity;
}

/// The single logging entry point used across AtlasChess.
///
/// `print` is not allowed in production Dart — it is unbuffered, has no
/// severity, cannot be silenced and the `avoid_print` lint rejects it — so every
/// diagnostic goes through this facade instead. It:
///
/// * writes through [debugPrint], Flutter's rate-limited console writer, so a
///   long payload is throttled instead of being dropped by the device log, and
///   the output still lands in `flutter run`, `adb logcat` and Console.app;
/// * drops records below [minLevel], which defaults to [AppLogLevel.debug] in
///   debug/profile builds and to [AppLogLevel.warning] in release builds, so a
///   shipped app's device log carries problems but not tracing noise;
/// * keeps the `'[Service] message'` shape the code base already used, so
///   existing log filters keep matching.
///
/// Every message carries its own `[Service]` prefix:
///
/// ```dart
/// AppLogger.warn('[MongoService] Connection error: $e');
/// ```
class AppLogger {
  const AppLogger._();

  /// Records below this level are dropped.
  ///
  /// Mutable on purpose: a test can lower it to [AppLogLevel.debug] to see the
  /// full trace, and a build can raise it to [AppLogLevel.error] for a quieter
  /// production log.
  static AppLogLevel minLevel =
      kReleaseMode ? AppLogLevel.warning : AppLogLevel.debug;

  /// Logs a verbose tracing record.
  static void debug(String message) => _write(AppLogLevel.debug, message);

  /// Logs an expected lifecycle event.
  static void info(String message) => _write(AppLogLevel.info, message);

  /// Logs a recoverable failure, degraded behaviour or skipped work.
  static void warn(String message) => _write(AppLogLevel.warning, message);

  /// Logs a failure that changes what the caller can return.
  static void error(String message) => _write(AppLogLevel.error, message);

  static void _write(AppLogLevel level, String message) {
    if (level.severity < minLevel.severity) return;
    debugPrint(message);
  }
}