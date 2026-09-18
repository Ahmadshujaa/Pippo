import 'dart:async';
import 'dart:isolate';

/// A long-lived background isolate with a bidirectional message transport.
///
/// Protocol (canonical Dart port handshake):
///
/// 1. **Spawner** creates `ReceivePort fromWorker` and spawns the entry point
///    with `fromWorker.sendPort` as its initial message.
/// 2. **Worker** receives that [SendPort] (its "handler" port back to the
///    spawner), creates its own `ReceivePort commandPort`, and immediately
///    sends `commandPort.sendPort` back through the handler port.
/// 3. **This client** recognises the [SendPort] handshake, keeps it as the
///    outbound port, and forwards every later message to [onMessage].
///
/// Sending from the main isolate never blocks; messages are delivered in
/// order to the worker's event loop.
class IsolateWorker {
  IsolateWorker._({
    required this._isolate,
    required this._inbound,
  });

  final Isolate _isolate;
  final ReceivePort _inbound;

  StreamSubscription<Object?>? _inboundSub;
  SendPort? _outbound;
  bool _disposed = false;

  /// True once the handshake has completed and [send] is safe to call.
  bool get isReady => _outbound != null && !_disposed;

  /// Starts [entry] in a fresh isolate and performs the port handshake.
  ///
  /// The returned future completes only after the handshake, so callers can
  /// start sending commands immediately. On failure (spawn error or a worker
  /// that never completes the handshake in time) the future throws and the
  /// isolate is torn down.
  static Future<IsolateWorker> start(
    void Function(dynamic message) entry, {
    required void Function(Object? message) onMessage,
    String? debugName,
  }) async {
    final fromWorker = ReceivePort();

    Isolate isolate;
    try {
      isolate = await Isolate.spawn(entry, fromWorker.sendPort,
          debugName: debugName);
    } catch (_) {
      fromWorker.close();
      rethrow;
    }

    final handshake = Completer<void>();
    final commandPort = Completer<SendPort>();

    final sub = fromWorker.listen((message) {
      if (message is SendPort && !commandPort.isCompleted) {
        commandPort.complete(message);
        if (!handshake.isCompleted) {
          handshake.complete();
        }
        return; // Handshake message, never surfaced to callers.
      }
      if (!handshake.isCompleted) {
        // A worker that sends data before its port handshake is malformed.
        return;
      }
      onMessage(message);
    });

    try {
      final sendPort = await commandPort.future
          .timeout(const Duration(seconds: 10));
      final worker = IsolateWorker._(
        isolate: isolate,
        inbound: fromWorker,
      )
        .._outbound = sendPort
        .._inboundSub = sub;
      await handshake.future;
      return worker;
    } catch (e) {
      await sub.cancel();
      fromWorker.close();
      isolate.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  /// Sends a command to the worker. Ignored (never queued) until the worker
  /// is ready; callers that depend on ordering should await [isReady].
  void send(Object? message) {
    if (_disposed) return;
    _outbound?.send(message);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _inboundSub?.cancel();
    _inbound.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}