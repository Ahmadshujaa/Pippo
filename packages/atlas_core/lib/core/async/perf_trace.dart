import 'dart:developer' as dev;

/// Lightweight, debug-only performance tracer for the heavy engine paths.
///
/// Enabled via the `--dart-define=PERF_TRACE=true` compile-time flag (or by
/// setting [enabled] programmatically in a debug session). When off — the
/// default in release — all calls are no-ops. When on, [measure] reports a
/// label and its elapsed microseconds through `dart:developer`.
abstract final class PerfTrace {
  static bool enabled = const bool.fromEnvironment('PERF_TRACE');

  static final Map<String, int> _started = {};

  /// Marks the start of a timed section keyed by [label].
  static void start(String label) {
    if (!enabled) return;
    _started[label] = _nowUs();
  }

  /// Records how long the named section ran since [start], logging it via
  /// [dev.log] if it exceeded [minUs] (default 1ms). Returns the elapsed
  /// microseconds (or -1 when tracing is disabled / no start was recorded).
  static int end(String label, {int minUs = 1000}) {
    if (!enabled) return -1;
    final int? s = _started.remove(label);
    if (s == null) return -1;
    final int elapsed = _nowUs() - s;
    if (elapsed >= minUs) {
      dev.log('[perf] $label: ${elapsed}us');
    }
    return elapsed;
  }

  static int _nowUs() => DateTime.now().microsecondsSinceEpoch;
}