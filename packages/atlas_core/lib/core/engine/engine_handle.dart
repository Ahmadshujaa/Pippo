import 'engine_models.dart';

/// Minimal engine surface that `MoveClassificationService` and the game
/// analyzers depend on.
///
/// Kept as a plain-interface in this file so that the classification module
/// stays free of Flutter imports and can be loaded inside background worker
/// isolates. `StockfishEngineService` implements this interface; custom
/// engine implementations (e.g. a test double) can implement it too.
abstract class EngineHandle {
  bool get isReady;

  Stream<AnalysisResult> get analysisStream;

  /// Raw UCI output lines. Consumers that still parse raw engine output (for
  /// example to complete an analysis wait) subscribe here.
  Stream<String> get outputStream;

  Future<void> start();

  void analyze(String fen, {int depth});

  void stop();

  void setLines(int lines);

  void setOption(String name, String value);

  void send(String command);
}