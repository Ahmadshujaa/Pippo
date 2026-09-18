import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Global internet-connection monitor.
///
/// This is intentionally a plain static service with a [ValueNotifier] so that
/// ANY screen can subscribe to connection changes without owning any state:
///
///   ConnectivityService.isOnline.value   // current status
///   `ValueListenableBuilder<bool>`(       // rebuild a screen when it changes
///     valueListenable: ConnectivityService.isOnline,
///     builder: (context, isOnline, child) { ... },
///   )
///
/// [startMonitoring] is called once during bootstrap and keeps the [isOnline]
/// value fresh by probing a well-known connectivity endpoint every
/// [_kMonitorInterval]. [checkNow] can also be called on demand (e.g. right
/// before a download) to get an immediate, up-to-date answer.
class ConnectivityService {
  /// Current connection state. `true` = internet reachable.
  static final ValueNotifier<bool> isOnline = ValueNotifier(true);

  /// Endpoint used to probe connectivity. `generate_204` is the same
  /// lightweight reachability endpoint Android/Chrome use: it returns a tiny
  /// 204 No Content response and never redirects, so it is perfect for a
  /// background check.
  static final Uri _probeUri = Uri.parse('https://www.gstatic.com/generate_204');

  /// How long a probe may take before we consider the connection dead.
  static const Duration _kProbeTimeout = Duration(seconds: 4);

  /// How often the background monitor re-checks the connection.
  static const Duration _kMonitorInterval = Duration(seconds: 10);

  static Timer? _monitorTimer;
  static bool _checkInProgress = false;

  /// Runs one connectivity probe and publishes the result to [isOnline].
  ///
  /// Multiple overlapping calls are collapsed into a single probe.
  ///
  /// Returns the resulting status (true = online). Never throws.
  static Future<bool> checkNow() async {
    if (_checkInProgress) return isOnline.value;
    _checkInProgress = true;
    try {
      final online = await Future.any<bool>([
        _probe(),
        Future.delayed(_kProbeTimeout, () => false),
      ]);
      isOnline.value = online;
      return online;
    } finally {
      _checkInProgress = false;
    }
  }

  static Future<bool> _probe() async {
    try {
      // Dart's http client throws on transport failures (DNS, refused, ...),
      // which is exactly what we want to treat as "offline".
      final response = await http.get(
        _probeUri,
        headers: {'Accept': '*/*', 'Cache-Control': 'no-cache'},
      );
      // 204 No Content (generate_204), 200, or any 3xx redirect counts as a
      // reachable network. Server-side errors (5xx) still mean we reached a
      // server, so even those count as "online" for offline-mode purposes.
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Starts the background connectivity monitor.
  ///
  /// Safe to call more than once — only one periodic timer is ever started.
  /// Runs one immediate check so [isOnline] reflects reality right away.
  static void startMonitoring() {
    if (_monitorTimer != null) return;
    _monitorTimer = Timer.periodic(_kMonitorInterval, (timer) {
      unawaited(checkNow());
    });
    unawaited(checkNow());
  }

  /// Stops the background monitor (mainly useful in tests).
  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }
}