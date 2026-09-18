import 'package:atlas_core/core/analysis/BookMoveService.dart';
import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/analysis/classification_scheduler.dart';
import 'package:atlas_core/core/engine/StockfishEngineService.dart';
import 'package:atlas_core/features/board/chessboard_controller.dart';
import 'package:chess/chess.dart' as chess;

/// Sequential full-game analysis orchestrator for the Analysis page.
///
/// Walks the mainline of a loaded game (root -> last node following
/// `children.first`; variations untouched) and classifies every move:
///
/// - While the opening book is still "open", moves are resolved through
///   [BookMoveService] alone — no Stockfish calls happen at all.
/// - After the first definitive non-book move, the book is never consulted
///   again during the run and classification switches to the shared engine.
/// - Consecutive mainline moves share positions, so each unique mainline
///   position is analyzed exactly once.
/// - Positions with exactly one legal move take a forced-move fast path that
///   skips searching the parent position entirely.
class GameAnalyzer {
  GameAnalyzer({required this.controller, this.engineOverride});

  final ChessboardController controller;

  /// When set, every position analysis this run performs is driven through
  /// this dedicated Stockfish process instead of the shared UI singleton.
  /// Background puzzle generation uses this so its engine work can run
  /// alongside the Analysis screen / interactive play without interference.
  final StockfishEngineService? engineOverride;

  /// FEN from which the last book move of the run was played. The caller
  /// copies this into its own book-state so interactive play continues
  /// coherently after the run.
  String? lastBookParentFen;

  /// Whether the game left the opening book during this run.
  bool bookEnded = false;

  /// Classifies [mainline] sequentially, one engine search at a time.
  ///
  /// [onProgress] fires when a node starts processing (with the number of
  /// completed nodes) and again when it finishes. [isCanceled] is checked
  /// around every await point; when it returns true the loop stops silently
  /// so the caller can reset any leftover pending flags.
  Future<void> analyze({
    required List<MoveNode> mainline,
    int depth = 13,
    required void Function(MoveNode node, double done, double total) onProgress,
    required bool Function() isCanceled,
  }) async {
    final service = MoveClassificationService.instance;
    final double total = mainline.length.toDouble();
    double done = 0;

    for (final node in mainline) {
      if (isCanceled()) return;

      // Idempotent fast re-run: already-classified nodes are skipped.
      if (node.hasClassification) {
        done += 1;
        onProgress(node, done, total);
        continue;
      }

      // Row spinner shows immediately while the move is processed.
      controller.setPendingClassificationForNode(node, true);
      onProgress(node, done, total);

      final moveObj = node.move!;
      final parentFen = node.parent!.fen;
      final moveUci =
          '${moveObj.fromAlgebraic}${moveObj.toAlgebraic}${moveObj.promotion?.name ?? ''}';

      // Forced takes precedence even over book moves and checkmate.
      final forced = service.tryClassifyForcedMove(parentFen, moveUci);
      if (forced != null) {
        controller.updateClassificationForNode(node, forced);
        done += 1;
        onProgress(node, done, total);
        continue;
      }

      // Non-forced checkmate skips the opening book.
      final bool isCheckmateMove = _isCheckmateMove(node.fen);

      // -----------------------------------------------------------------
      // Book phase: resolve through the opening book while it is open.
      // -----------------------------------------------------------------
      if (!bookEnded && !isCheckmateMove) {
        if (isCanceled()) return;
        final bookResult = await BookMoveService.checkMove(
          parentFen,
          moveUci,
          moveSan: node.san.isEmpty ? null : node.san,
        );
        if (isCanceled()) return;

        if (bookResult.isBookMove) {
          lastBookParentFen = parentFen;
          controller.updateClassificationForNode(
            node,
            ClassificationResult(
              classification: MoveClassification.book,
              comment: 'A move from the opening book.',
              evalBefore: 0,
              evalAfter: 0,
              epBefore: 0.5,
              epAfter: 0.5,
              loss: 0,
              bestMove: bookResult.bestMoveUci ?? '',
              playedMoveUci: moveUci,
            ),
          );
          done += 1;
          onProgress(node, done, total);
          continue;
        } else if (bookResult.requestSucceeded) {
          // Definitively not a book move: the book is over for this run.
          bookEnded = true;
        }
        // Inconclusive request: classify this move via the engine but keep
        // the book open for subsequent moves (transient-failure semantics).
      }

      // -----------------------------------------------------------------
      // Engine phase: shared instance, strictly sequential searches.
      // -----------------------------------------------------------------
      if (isCanceled()) return;
      final analysisAfter = await _ensurePositionAnalysis(node.fen, depth);
      if (isCanceled()) return;

      final ClassificationResult result;

      if (isCheckmateMove) {
        // Forced moves were already handled before the book phase.
        final double evalAfterPawns = -analysisAfter.evalInPawns;
        final int? mateAfter =
            analysisAfter.mateIn != null ? -analysisAfter.mateIn! : null;
        final double epAfter = service.calculateExpectedPoints(
          evalAfterPawns,
          mateIn: mateAfter,
        );
        // analysisBefore is unavailable on this path (book may have been
        // skipped and parent never searched); use the after-move standing
        // for the before fields so the result stays consistent.
        result = ClassificationResult(
          classification: MoveClassification.best,
          comment: 'Checkmate — the best possible move.',
          evalBefore: evalAfterPawns,
          evalAfter: evalAfterPawns,
          epBefore: epAfter,
          epAfter: epAfter,
          loss: 0,
          bestMove: moveUci,
          playedMoveUci: moveUci,
        );
      } else {
        final analysisBefore =
            await _ensurePositionAnalysis(parentFen, depth);
        if (isCanceled()) return;

        result = await ClassificationScheduler.instance.classify(
          fenBefore: parentFen,
          moveUci: moveUci,
          analysisBefore: analysisBefore,
          analysisAfter: analysisAfter,
        );
      }

      controller.updateClassificationForNode(node, result);
      done += 1;
      onProgress(node, done, total);
    }
  }

  /// Returns the cached analysis for [fen], analyzing and caching it first
  /// when missing. Sharing consecutive positions across moves halves the
  /// number of engine searches versus two-per-move.
  Future<PositionAnalysis> _ensurePositionAnalysis(String fen, int depth) async {
    final service = MoveClassificationService.instance;
    final cached = service.getCachedAnalysis(fen);
    if (cached != null) return cached;

    final analysis = await service.analyzePosition(
      fen,
      depth: depth,
      multiPv: 2,
      engineOverride: engineOverride,
    );
    service.cachePositionAnalysis(fen, analysis);
    return analysis;
  }

  /// True when [fenAfter] (position after the played move) is checkmate.
  /// Pure board check — no engine involved.
  bool _isCheckmateMove(String fenAfter) {
    try {
      return chess.Chess.fromFEN(fenAfter).in_checkmate;
    } catch (_) {
      return false;
    }
  }
}
