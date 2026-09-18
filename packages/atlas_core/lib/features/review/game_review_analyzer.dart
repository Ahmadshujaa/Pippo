import 'package:chess/chess.dart' as chess;

import 'package:atlas_core/core/analysis/GameAccuracyService.dart';
import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/engine/StockfishEngineService.dart';
import 'package:atlas_core/core/analysis/AICoachService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/features/board/chessboard_controller.dart';
import 'package:atlas_core/features/analysis/game_analyzer.dart';

/// Data needed to call the backend AI review endpoint.
class ReviewPayload {
  final List<String> moveHistory;
  final List<Map<String, dynamic>> moveAnalyses;
  final String userColor;

  const ReviewPayload({
    required this.moveHistory,
    required this.moveAnalyses,
    required this.userColor,
  });
}

/// How to interpret raw engine values when formatting evals for the payload.
enum _EvalPerspective { moverDirect, after }

/// Manages the full review flow for the GameReview screen.
///
/// Keeps the analysis stateless and screen-level (no global session):
/// each method takes the screen's own [ChessboardController] and operates on
/// its mainline. Accuracy is derived from the shared engine analysis cache;
/// classification nodes are populated into the live move tree so the moves
/// tab / report tab can display them immediately.
class GameReviewAnalyzer {
  const GameReviewAnalyzer._();

  // =========================================================================
  // 1. FULL-GAME ANALYSIS
  // =========================================================================

  /// Runs the same Stockfish classification the Analysis page uses over the
  /// entire mainline of [controller].
  ///
  /// [depth] is the Analysis screen's chosen game-analysis depth (the Analyze
  /// menu exposes it as a 7-20 slider); it is no longer hardcoded so both the
  /// Analysis and the Game Review run at the depth the user picked.
  ///
  /// Returns `true` when the run completed, `false` if it was cancelled.
  /// The caller is responsible for ensuring [controller] already holds a
  /// full game.
  static Future<bool> analyzeGame(
    ChessboardController controller, {
    int depth = 13,
  }) async {
    final sanMoves = _collectSanMoves(controller);
    if (sanMoves.isEmpty) return false;

    final mainline = extractMainline(controller);
    if (mainline.isEmpty) return false;

    const engineOwner = 'game-review-analyzer';
    final engine = StockfishEngineService.instance;
    if (!engine.tryAcquireExclusive(engineOwner)) return false;

    try {
      await engine.start();
    } catch (_) {
      engine.releaseExclusive(engineOwner);
      return false;
    }

    try {
      final analyzer = GameAnalyzer(controller: controller);
      await analyzer.analyze(
        mainline: mainline,
        depth: depth,
        onProgress: (_, _, _) {},
        isCanceled: () => false,
      );
      return true;
    } catch (e) {
      AppLogger.error('[GameReviewAnalyzer] Analysis failed: $e');
      return false;
    } finally {
      engine.releaseExclusive(engineOwner);
    }
  }

  // =========================================================================
  // 2. ACCURACY
  // =========================================================================

  /// Computes the Lichess-style 0–100 accuracy for both players from the
  /// cached position analyses populated during [analyzeGame].
  ///
  /// Returns `null` when there are fewer than two classified positions.
  static Map<String, double>? computeAccuracy(ChessboardController controller) {
    final service = MoveClassificationService.instance;

    final mainline = extractMainline(controller);
    if (mainline.isEmpty) return null;

    final winPercents = <double>[];
    winPercents.add(_winPercentFor(service, controller.root.fen));
    for (final node in mainline) {
      winPercents.add(_winPercentFor(service, node.fen));
    }

    return GameAccuracyService.calculateGameAccuracy(true, winPercents);
  }

  // =========================================================================
  // 3. REVIEW PAYLOAD (moveHistory + moveAnalyses)
  // =========================================================================

  /// Builds the payload the backend requires to construct the Enhanced PGN
  /// and call Gemini. The [userColor] should be `'white'` or `'black'`.
  static ReviewPayload? buildReviewPayload(
    ChessboardController controller, {
    required String userColor,
  }) {
    final mainline = extractMainline(controller);
    if (mainline.isEmpty) return null;

    final moveHistory = <String>[];
    final moveAnalyses = <Map<String, dynamic>>[];

    for (final node in mainline) {
      moveHistory.add(node.san);

      final classification = node.classification;
      final parentAnalysis = MoveClassificationService.instance
          .getCachedAnalysis(node.parent!.fen);
      final afterAnalysis = MoveClassificationService.instance
          .getCachedAnalysis(node.fen);

      moveAnalyses.add({
        'category': _mapCategory(classification?.classification),
        'pv': _convertPvToSan(
          parentAnalysis?.principalVariation ?? [],
          node.parent!.fen,
        ),
        'pvAfter': _convertPvToSan(
          afterAnalysis?.principalVariation ?? [],
          node.fen,
        ),
        'evalBefore': _formatMoverEval(
          parentAnalysis?.evalInPawns ?? 0.0,
          mateIn: parentAnalysis?.mateIn,
          perspective: _EvalPerspective.moverDirect,
        ),
        'evalAfter': _formatMoverEval(
          afterAnalysis?.evalInPawns ?? 0.0,
          mateIn: afterAnalysis?.mateIn,
          perspective: _EvalPerspective.after,
        ),
      });
    }

    return ReviewPayload(
      moveHistory: moveHistory,
      moveAnalyses: moveAnalyses,
      userColor: userColor,
    );
  }

  /// Requests the AI coach notes from the mobile backend.
  static Future<List<AICoachNote>> fetchAIExplanations(
    ReviewPayload payload,
  ) async {
    return AICoachService.requestExplanations(
      moveHistory: payload.moveHistory,
      moveAnalyses: payload.moveAnalyses,
      userColor: payload.userColor,
    );
  }

  /// Returns a map from SAN move → coach explanation text.
  static Map<String, String> mapExplanationsBySan(List<AICoachNote> notes) {
    final map = <String, String>{};
    for (final note in notes) {
      map[note.move] = note.explanation;
    }
    return map;
  }

  /// Aligns the coach notes (one object per move, in chronological order)
  /// with the mainline plies so the review view can look up the explanation
  /// for the current move by index.
  ///
  /// The primary source of truth is POSITION: the model is instructed to
  /// return exactly one object per move in order, so note[i] belongs to
  /// mainline[i]. When the arrays have different lengths (degenerate model
  /// output), the SAN of the move is used as a fallback match so an otherwise
  /// good response is not thrown away.
  ///
  /// Returns a list with exactly one entry per mainline node ('' when no
  /// explanation is available for that move).
  static List<String> mapExplanationsToMainline(
    ChessboardController controller,
    List<AICoachNote> notes,
  ) {
    final mainline = extractMainline(controller);
    final explanations = List<String>.filled(mainline.length, '');

    if (notes.isEmpty) return explanations;

    final notesBySan = mapExplanationsBySan(notes);
    final sharedLength =
        mainline.length < notes.length ? mainline.length : notes.length;

    for (int i = 0; i < mainline.length; i++) {
      if (i < sharedLength && notes[i].explanation.isNotEmpty) {
        explanations[i] = notes[i].explanation;
      } else {
        explanations[i] = notesBySan[mainline[i].san] ?? '';
      }
    }
    return explanations;
  }

  /// Derives the color the user played from the loaded game's headers.
  ///
  /// The Analysis screen writes 'You' into the White/Black header of the
  /// player's own side. Returns `'white'` as a safe fallback.
  static String userColorFromHeaders(Map<String, String>? headers) {
    final white = headers?['White']?.trim().toLowerCase();
    if (white == 'you') return 'black';
    final black = headers?['Black']?.trim().toLowerCase();
    if (black == 'you') return 'white';
    return 'white';
  }

  // =========================================================================
  // MAINLINE HELPERS
  // =========================================================================

  /// Extracts the mainline of the move tree (root.children.first chain,
  /// root excluded) — the game as it was played, ignoring variations.
  static List<MoveNode> extractMainline(ChessboardController controller) {
    final mainline = <MoveNode>[];
    MoveNode? current = controller.root.children.isEmpty
        ? null
        : controller.root.children.first;
    while (current != null) {
      mainline.add(current);
      current = current.children.isEmpty ? null : current.children.first;
    }
    return mainline;
  }

  /// True when [node] lies on the mainline: every step from the node up to
  /// the root must follow `children.first`.
  static bool isOnMainline(ChessboardController controller, [MoveNode? node]) {
    MoveNode? current = node ?? controller.currentNode;
    while (current != null && current.parent != null) {
      if (!identical(current.parent!.children.first, current)) return false;
      current = current.parent;
    }
    return true;
  }

  /// The mainline position the user diverted from — i.e. the closest ancestor
  /// of the current node that is still on the mainline. This is exactly the
  /// position the "Resume" button returns to. Returns `null` when the current
  /// node is already on the mainline.
  static MoveNode? mainlineDiversionNode(ChessboardController controller) {
    if (isOnMainline(controller)) return null;

    MoveNode? current = controller.currentNode;
    while (current != null) {
      final parent = current.parent;
      if (parent == null) return null;
      if (identical(parent.children.first, current)) return current;
      current = parent;
    }
    return null;
  }

  // =========================================================================
  // INTERNAL HELPERS
  // =========================================================================

  static List<String> _collectSanMoves(ChessboardController controller) {
    return extractMainline(controller).map((n) => n.san).toList();
  }

  static double _winPercentFor(MoveClassificationService service, String fen) {
    final analysis = service.getCachedAnalysis(fen);
    if (analysis == null) return 50.0;

    final wp = chess.Chess.fromFEN(fen).turn == chess.Color.WHITE
        ? analysis.expectedPoints
        : 1.0 - analysis.expectedPoints;
    return wp.clamp(0.0, 1.0).toDouble() * 100.0;
  }

  /// Maps the mobile engine's classification to the website's MoveCategory
  /// string so the backend's Enhanced PGN generator matches exactly.
  static String _mapCategory(MoveClassification? classification) {
    if (classification == null) return 'Best'; // default safe fallback
    switch (classification) {
      case MoveClassification.book:
        return 'Book';
      case MoveClassification.brilliant:
        return 'Brilliant';
      case MoveClassification.great:
        return 'Great';
      case MoveClassification.best:
        return 'Best';
      case MoveClassification.excellent:
        return 'Excellent';
      case MoveClassification.good:
        return 'Okay';
      case MoveClassification.inaccuracy:
        return 'Inaccuracy';
      case MoveClassification.mistake:
        return 'Mistake';
      case MoveClassification.blunder:
        return 'Blunder';
      case MoveClassification.miss:
        return 'Miss';
      case MoveClassification.forced:
        return 'Forced';
    }
  }

  static List<String> _convertPvToSan(List<String> pvUci, String startFen) {
    if (pvUci.isEmpty) return [];
    try {
      final game = chess.Chess.fromFEN(startFen);
      final sanMoves = <String>[];
      for (final uci in pvUci) {
        if (uci.length < 4) break;
        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promotion = uci.length > 4 ? uci.substring(4, 5) : null;

        chess.Move? moveObj;
        for (final m in game.generate_moves()) {
          if (m.fromAlgebraic == from &&
              m.toAlgebraic == to &&
              (m.promotion == null || m.promotion!.name == promotion)) {
            moveObj = m;
            break;
          }
        }
        if (moveObj == null) return []; // invalid PV — return empty for safety
        sanMoves.add(game.move_to_san(moveObj));
        game.make_move(moveObj);
      }
      return sanMoves;
    } catch (_) {
      return [];
    }
  }

  /// Formats an eval (in pawns) from the analysis perspective into a human
  /// string as seen by the mover of the current move.
  ///
  /// [perspective] tells us how to interpret the raw analysis values:
  /// - `moverDirect`: the analysis is already from the mover's perspective
  ///   (used for evalBefore, where side-to-move == mover).
  /// - `after`: the analysis is from the opponent's perspective (used for
  ///   evalAfter, where side-to-move == opponent).
  static String _formatMoverEval(
    double evalInPawns, {
    int? mateIn,
    required _EvalPerspective perspective,
  }) {
    int? effectiveMate = mateIn;
    double effectivePawns = evalInPawns;

    if (perspective == _EvalPerspective.after) {
      effectivePawns = -evalInPawns;
      effectiveMate = mateIn != null ? -mateIn : null;
    }

    if (effectiveMate != null) {
      if (effectiveMate > 0) {
        return 'M$effectiveMate';
      } else if (effectiveMate < 0) {
        final absMate = -effectiveMate;
        return '-M$absMate';
      }
      return '0.0';
    }

    final rounded = double.parse(effectivePawns.toStringAsFixed(1));
    if (rounded == 0.0 || rounded == -0.0) return '0.0';
    return rounded > 0 ? '+$rounded' : '$rounded';
  }
}
