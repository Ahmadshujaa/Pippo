import 'package:chess/chess.dart' as chess;

/// One engine line (principal variation) shipped as part of an
/// [AnalysisResult]. Pure data, so instances can cross isolate boundaries.
class AnalysisLine {
  final String moves; // SAN notation
  final String rawPv; // UCI notation
  final String eval;
  final bool isPrimary;

  AnalysisLine({
    required this.moves,
    required this.rawPv,
    required this.eval,
    this.isPrimary = false,
  });
}

/// A published engine evaluation for one position.
///
/// This is a plain-data object with no native resources, so it is safe to
/// send between isolates created with `Isolate.spawn` (shared code).
class AnalysisResult {
  final String fen;
  final int depth;
  final double evaluation;
  final bool isMate;
  /// Monotonically increasing identifier for the engine search that produced
  /// this result. Consumers can use it to reject a late result from an older
  /// search when the same FEN is analyzed again.
  final int generation;
  final List<AnalysisLine> lines;
  final chess.Color turn; // Side to move

  /// Depth reached per MultiPV line at publish time, keyed by the UCI
  /// `multipv` number (1..N). Consumers that wait until every requested PV
  /// line has hit a target depth use this instead of parsing raw engine
  /// output (which would put per-line FEN/legal-move work on their isolate).
  final Map<int, int>? lineDepths;

  /// True when this result was emitted because Stockfish sent `bestmove`.
  /// This lets one-shot callers finish cleanly even when the engine did not
  /// publish every requested MultiPV line at the exact target depth.
  final bool isFinal;

  AnalysisResult({
    required this.fen,
    required this.depth,
    required this.evaluation,
    this.isMate = false,
    this.generation = 0,
    required this.lines,
    required this.turn,
    this.lineDepths,
    this.isFinal = false,
  });

  String get evalText {
    if (isMate) {
      return 'M${evaluation.toInt().abs()}';
    }
    final val = evaluation / 100.0;
    return val > 0 ? '+$val' : val.toString();
  }
}
