import 'dart:isolate';

import 'MoveClassificationService.dart';

/// Message tags for the MoveClassificationService worker.
const String kClassificationWorkerTagOk = 'ok';
const String kClassificationWorkerTagError = 'error';

/// Isolate entry point for move classification.
///
/// Receives the main isolate's [SendPort] (the "handler" port), then runs the
/// canonical port handshake: this isolate creates its own command port and
/// announces it with the first message.
///
/// Each incoming command is a list shaped like:
/// `[jobId, fenBefore, moveUci, analysisBefore, analysisAfter, analysisPrevious]`
/// where `analysisBefore`/`analysisAfter` are [PositionAnalysis] instances and
/// `analysisPrevious` is `null` or a [PositionAnalysis].
///
/// The result is reported back as `['ok', jobId, ClassificationResult]` or, on
/// failure, `['error', jobId, message]`.
void classificationWorkerEntry(dynamic message) {
  final handlerPort = message as SendPort;
  final commandPort = ReceivePort();
  // Handshake: announce our command port before anything else.
  handlerPort.send(commandPort.sendPort);

  commandPort.listen((dynamic raw) {
    if (raw is! List || raw.length < 6) return;
    final Object id = raw[0];
    try {
      final PositionAnalysis? previous = raw[5] as PositionAnalysis?;
      final result = MoveClassificationService.runClassificationJob(
        fenBefore: raw[1] as String,
        moveUci: raw[2] as String,
        analysisBefore: raw[3] as PositionAnalysis,
        analysisAfter: raw[4] as PositionAnalysis,
        analysisPrevious: previous,
      );
      handlerPort.send([kClassificationWorkerTagOk, id, result]);
    } catch (e) {
      handlerPort.send([kClassificationWorkerTagError, id, '$e']);
    }
  });
}