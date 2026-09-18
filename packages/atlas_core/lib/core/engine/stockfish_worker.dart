import 'dart:isolate';

import 'stockfish_output_parser.dart';

/// Command message identifiers used between `StockfishEngineService` and this
/// worker. Kept as string constants so the protocol survives formatting and
/// refactors intact.
const String kStockfishWorkerCmdBegin = 'begin';
const String kStockfishWorkerCmdResume = 'resume';
const String kStockfishWorkerCmdConfigure = 'configure';
const String kStockfishWorkerCmdLine = 'line';
const String kStockfishWorkerCmdDispose = 'dispose';

const String kStockfishWorkerTagPublish = 'publish';
const String kStockfishWorkerTagEnded = 'ended';

/// Isolate entry point for the Stockfish output parser.
///
/// Receives the main isolate's [SendPort] (the "handler" port used to report
/// events back), then runs the canonical handshake: this isolate creates its
/// own command port and announces it with the first message.
///
/// From then on the main isolate sends commands as `List`-shaped messages:
/// * `['begin', fen, generation, targetDepth]` — reset state for a new search
/// * `['resume', fen, generation]` — the engine completed `readyok`; output now
///   belongs to [fen]
/// * `['configure', lines, minDepth, depthInterval]`
/// * `['line', rawLine]` — one raw UCI output line
/// * `['dispose']` — shut down
void stockfishWorkerEntry(dynamic message) {
  final handlerPort = message as SendPort;

  final parser = StockfishOutputParser();
  final commandPort = ReceivePort();
  // Handshake: announce our command port before anything else.
  handlerPort.send(commandPort.sendPort);

  commandPort.listen((dynamic raw) {
    if (raw is! List) return;
    final tag = raw.isEmpty ? null : raw[0];
    try {
      switch (tag) {
        case kStockfishWorkerCmdBegin:
          parser.beginSearch(
            raw[1] as String,
            generation: raw.length > 2 ? raw[2] as int : 0,
            targetDepth: raw.length > 3 ? raw[3] as int? : null,
          );
          break;
        case kStockfishWorkerCmdResume:
          parser.resumeSearch(
            raw[1] as String,
            generation: raw.length > 2 ? raw[2] as int? : null,
          );
          break;
        case kStockfishWorkerCmdConfigure:
          parser.configure(
            lines: raw[1] as int?,
            minDepth: raw[2] as int?,
            depthInterval: raw[3] as int?,
          );
          break;
        case kStockfishWorkerCmdLine:
          _handleLine(parser, handlerPort, raw[1] as String);
          break;
        case kStockfishWorkerCmdDispose:
          commandPort.close();
          return;
      }
    } catch (_) {
      // A malformed command must never kill the worker; the parser resets
      // lazily on the next valid command.
    }
  });
}

void _handleLine(
  StockfishOutputParser parser,
  SendPort handlerPort,
  String line,
) {
  final outcome = parser.handleLine(line);
  final publish = outcome.publish;
  if (publish != null) {
    handlerPort.send([kStockfishWorkerTagPublish, publish]);
  }
  if (outcome.searchEnded) {
    handlerPort.send([kStockfishWorkerTagEnded, outcome.generation]);
  }
}
