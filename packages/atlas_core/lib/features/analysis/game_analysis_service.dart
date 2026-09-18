import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess;

import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/engine/StockfishEngineService.dart';
import 'package:atlas_core/core/analysis/GameAccuracyService.dart';
import 'package:atlas_core/core/analysis/AICoachService.dart';
import 'package:atlas_core/features/board/chessboard_controller.dart';
import 'package:atlas_core/features/analysis/game_analyzer.dart';
import 'package:atlas_core/features/review/game_review_analyzer.dart';

/// The phases of a Game Review run.
///
/// A review is a two-step process on top of the normal full-game analysis:
/// 1. [classifying] — the exact same Stockfish classification pass the
///    Analysis feature runs (book moves first, then sequential engine
///    classification at the user-chosen depth).
/// 2. [awaitingCoach] — the Enhanced PGN is built from the classification
///    results and sent to the coach service.
/// The UI shows the same "Your game is being reviewed" shimmer for BOTH
/// in-flight phases (no percentage ring). [ready] means the explanations
/// arrived and the compact review view can be shown; [failed] means the run
/// was aborted or the request returned nothing.
enum GameReviewPhase { idle, classifying, awaitingCoach, ready, failed }

/// Session-level owner of the full-game analysis session.
///
/// Full-game analysis is expensive: it walks the whole mainline and runs a
/// sequential engine search per unique position. The [AnalysisScreen] widget
/// is disposed whenever the user navigates away (the app's navigation uses
/// `pushReplacementNamed`), so all analysis state used to live and die with
/// that widget and a background run was cancelled the moment the user left.
///
/// To let a run keep going and finish in the background, all of that state —
/// the loaded game, the move tree / board controller, the running analyzer
/// and its progress — lives here, at the process/session level, independent
/// of any [AnalysisScreen] instance. Returning to the Analysis screen binds
/// to this service and shows the ongoing progress or the finished result.
class GameAnalysisService extends ChangeNotifier {
  GameAnalysisService._();

  static const String _engineOwnerPrefix = 'game-analysis';

  static GameAnalysisService? _instance;

  static GameAnalysisService get instance =>
      _instance ??= GameAnalysisService._();

  /// The single, shared board/move-tree controller. Every Analysis screen
  /// binds to this instance so a run that finishes in the background lands
  /// on the same tree the user left and sees again on return.
  final ChessboardController controller = ChessboardController();

  // -------------------------------------------------------------------------
  // Loaded game state.
  // -------------------------------------------------------------------------
  String? loadedPgn;
  Map<String, String>? loadedHeaders;
  List<String>? loadedSanMoves;
  bool isGameLoaded = false;
  bool isGameAnalyzed = false;

  // -------------------------------------------------------------------------
  // Full-game analysis runtime state.
  // -------------------------------------------------------------------------
  bool isAnalyzing = false;
  (int, int)? analysisProgress;
  bool bookEnded = false;
  String? lastBookPositionFen;

  // -------------------------------------------------------------------------
  // Game Review runtime state (two steps on top of the analysis pass).
  // -------------------------------------------------------------------------
  GameReviewPhase reviewPhase = GameReviewPhase.idle;

  /// One coach explanation per mainline ply (aligned by index, '' when a move
  /// has no explanation). Populated when the review reaches [GameReviewPhase.ready].
  List<String> reviewExplanations = const [];

  int _reviewRunId = 0;

  /// True when a run finishes while no Analysis screen is listening, so a
  /// freshly mounted screen knows to surface the result (e.g. open the report
  /// dialog once) instead of showing stale "not analyzed" controls.
  bool completedInBackground = false;

  /// When the user finishes Board Setup, classification and engine analysis
  /// must not start until they actually play a move in the created position.
  /// Set by the setup screen on apply; the Analysis screen clears it the first
  /// time a non-root node (i.e. a played move) is observed and otherwise
  /// leaves the freshly-loaded root position inert.
  bool suppressEngineUntilMove = false;

  int _analysisRunId = 0;
  String? _activeEngineOwner;

  /// Loads a full game (PGN + headers + moves) into the shared board and move
  /// tree, cancelling any running analysis first.
  ///
  /// [fens] are required because building them from SAN moves needs a chess
  /// library that this package already uses, avoiding an import dependency on
  /// the import/parse services.
  bool loadFullGame({
    required String pgn,
    required Map<String, String>? headers,
    required List<String>? sanMoves,
    required List<String> fens,
  }) {
    if (pgn.isEmpty) return false;

    // Cancel any running full-game analysis before the tree is rebuilt.
    cancelRunningAnalysis();

    // A newly loaded game starts with a fresh opening book session.
    bookEnded = false;
    lastBookPositionFen = null;

    loadedPgn = pgn;
    loadedHeaders = headers;
    loadedSanMoves = sanMoves;
    isGameLoaded = true;
    isGameAnalyzed = false;
    analysisProgress = null;
    completedInBackground = false;
    _resetReviewState();
    // Importing a full game restores the normal auto-analyse-on-position
    // behaviour (only Board Setup suppresses it until a move is played).
    suppressEngineUntilMove = false;

    controller.loadGame(fens);
    notifyListeners();
    return true;
  }

  /// Clears the loaded-game fields only (used when the user loads a bare FEN
  /// position instead of a full game). The board itself is preserved.
  void clearLoadedGameData() {
    loadedPgn = null;
    loadedHeaders = null;
    loadedSanMoves = null;
    isGameLoaded = false;
    isGameAnalyzed = false;
    analysisProgress = null;
    completedInBackground = false;
    _resetReviewState();
    notifyListeners();
  }

  /// Clears the loaded game and resets the board to the starting position.
  void clearLoadedGame() {
    // Cancels any running analysis first so no pending flags or engine
    // searches survive the reset below.
    cancelRunningAnalysis();

    loadedPgn = null;
    loadedHeaders = null;
    loadedSanMoves = null;
    isGameLoaded = false;
    isGameAnalyzed = false;
    analysisProgress = null;
    completedInBackground = false;
    suppressEngineUntilMove = false;
    _resetReviewState();

    controller.reset();
    notifyListeners();
  }

  /// Bumps the analysis generation counter and aborts any in-flight engine
  /// search. The running [GameAnalyzer] loop observes the stale run id at its
  /// next await point and stops silently.
  ///
  /// Cancelling also deletes every classification produced so far so the board
  /// and moves tree are left clean, matching the "start fresh" semantics of
  /// the Cancel button that replaces the Analyze button while a run is active.
  void cancelRunningAnalysis() {
    if (!isAnalyzing) return;
    _analysisRunId++;
    isAnalyzing = false;
    StockfishEngineService.instance.stop();
    // The analyzer observes the invalidated run id at its next await point.
    // The engine is already stopped, so release the lease now and allow a
    // newly requested run to acquire it without waiting for cleanup.
    final owner = _activeEngineOwner;
    if (owner != null) {
      StockfishEngineService.instance.releaseExclusive(owner);
      _activeEngineOwner = null;
    }

    void clearNode(MoveNode node) {
      node.classification = null;
      node.isPendingClassification = false;
      for (final child in node.children) {
        clearNode(child);
      }
    }

    clearNode(controller.root);
    MoveClassificationService.instance.clearCache();
    analysisProgress = null;
    isGameAnalyzed = false;
    completedInBackground = false;
    notifyListeners();
  }

  /// Classification models are cached per position and shared between the
  /// interactive engine lookups and the full-game run. Importing a game or
  /// starting a fresh session calls this to drop stale data.
  void clearPositionCache() {
    MoveClassificationService.instance.clearCache();
  }

  /// Computes the Lichess-style game accuracy (0-100) for both White and Black
  /// using the WDL rates cached by [MoveClassificationService] for each mainline
  /// position.
  ///
  /// The analyzer caches a [PositionAnalysis] (via FEN) for every unique mainline
  /// position as it processes the game. That analysis carries the expected-points
  /// WDL rate (0.0-1.0) from the perspective of the side to move, which we convert
  /// to a White-perspective win percentage (0-100) and feed to
  /// [GameAccuracyService.calculateGameAccuracy].
  ///
  /// Returns null when there is no usable mainline (fewer than two consecutive
  /// positions are cached) so callers know accuracy is not available yet.
  Map<String, double>? computeGameAccuracy() {
    final service = MoveClassificationService.instance;

    // Extract the mainline (root.children.first chain, root excluded).
    final mainline = <MoveNode>[];
    MoveNode? current = controller.root.children.isEmpty
        ? null
        : controller.root.children.first;
    while (current != null) {
      mainline.add(current);
      current = current.children.isEmpty ? null : current.children.first;
    }
    if (mainline.isEmpty) return null;

    // Gather the WDL rate for the starting position and for every half-move.
    // winPercents[i] is White's win % (0-100) after i half-moves from White's
    // perspective. The start position itself is index 0.
    final winPercents = <double>[];
    winPercents.add(_winPercentFor(service, controller.root.fen));
    for (final node in mainline) {
      winPercents.add(_winPercentFor(service, node.fen));
    }

    // White always makes the first move of a standard game.
    final isStartWhite = true;

    return GameAccuracyService.calculateGameAccuracy(isStartWhite, winPercents);
  }

  /// Converts the cached analysis' expected-points WDL rate for [fen] into a
  /// White-perspective win percentage (0-100), falling back to 50% (a balanced
  /// start) when the position has not been cached yet.
  double _winPercentFor(MoveClassificationService service, String fen) {
    final analysis = service.getCachedAnalysis(fen);
    if (analysis == null) return 50.0;

    // expectedPoints is from the perspective of the side to move. Flip it for
    // White when Black is to move.
    final double wp;
    if (chess.Chess.fromFEN(fen).turn == chess.Color.WHITE) {
      wp = analysis.expectedPoints;
    } else {
      wp = 1.0 - analysis.expectedPoints;
    }
    return wp.clamp(0.0, 1.0).toDouble() * 100.0;
  }

  /// Runs full-game analysis over the shared controller's mainline in the
  /// background. Unlike the old screen-bound flow, this never depends on a
  /// widget being mounted: it is cancelled only explicitly (a new game load or
  /// the Cancel button) or a newer run superseding it.
  ///
  /// Returns true when the run reached completion, false if it was cancelled
  /// or there was nothing to analyze. The caller is expected to have ensured
  /// the engine is ready/started beforehand.
  Future<bool> startGameAnalysis({int depth = 13}) async {
    final sanMoves = loadedSanMoves;
    if (isAnalyzing || !isGameLoaded || sanMoves == null || sanMoves.isEmpty) {
      return false;
    }

    // Extract the mainline (root.children.first chain, root excluded).
    final mainline = <MoveNode>[];
    MoveNode? current = controller.root.children.isEmpty
        ? null
        : controller.root.children.first;
    while (current != null) {
      mainline.add(current);
      current = current.children.isEmpty ? null : current.children.first;
    }
    if (mainline.isEmpty) return false;

    final runId = ++_analysisRunId;
    final engine = StockfishEngineService.instance;
    final engineOwner = '$_engineOwnerPrefix-$runId';
    if (!engine.tryAcquireExclusive(engineOwner)) return false;
    _activeEngineOwner = engineOwner;

    bool isCanceled() => runId != _analysisRunId;

    isAnalyzing = true;

    // Pin the board to the starting position while the run is active. The
    // analyzer only writes classifications; it never moves the board, so once
    // the run starts the displayed position stays exactly where it is for the
    // whole run (navigation is frozen on the screen). Without this the board
    // can be left on a middle/end-of-game position from a previous load, which
    // looks broken after analysis finishes.
    // Setting isAnalyzing first keeps the screen's board listener on the
    // early-return path when goToStart notifies it.
    controller.goToStart();

    analysisProgress = (0, mainline.length);
    completedInBackground = false;
    notifyListeners();

    final analyzer = GameAnalyzer(controller: controller);
    try {
      await analyzer.analyze(
        mainline: mainline,
        depth: depth,
        onProgress: (node, done, total) {
          if (isCanceled()) return;
          analysisProgress = (done.round(), total.round());
          notifyListeners();
        },
        isCanceled: isCanceled,
      );

      if (isCanceled()) return false;

      // Completion side-effects: sync book state so interactive play
      // continues coherently and restore the interactive line count.
      isGameAnalyzed = true;
      bookEnded = analyzer.bookEnded;
      lastBookPositionFen = analyzer.lastBookParentFen;
      engine.setLines(2);
      completedInBackground = true;
      notifyListeners();
      return true;
    } catch (e) {
      if (isCanceled()) return false;
      isAnalyzing = false;
      notifyListeners();
      rethrow;
    } finally {
      // Clear pending flags left on partially processed nodes so no spinner
      // gets stuck when the run ends early or fails.
      if (!isCanceled()) {
        for (final node in mainline) {
          if (node.isPendingClassification) {
            node.isPendingClassification = false;
          }
        }
      }
      if (runId == _analysisRunId) {
        isAnalyzing = false;
        notifyListeners();
      }
      engine.releaseExclusive(engineOwner);
      if (_activeEngineOwner == engineOwner) _activeEngineOwner = null;
    }
  }

  // ===========================================================================
  // GAME REVIEW (two steps: classification -> coach request)
  // ===========================================================================

  /// Runs a full Game Review over the shared controller's mainline:
  ///
  /// STEP 1 — classification: the exact same pass a plain full-game analysis
  /// runs ([GameAnalyzer] at [depth], driven through `isAnalyzing` /
  /// `analysisProgress` so the screen shows the identical percentage UI).
  ///
  /// STEP 2 — coach request: builds the Enhanced PGN payload from the
  /// classification results (the PVs cached during step 1, trimmed to exactly
  /// the move counts the coach prompt consumes) and waits for the explanation
  /// notes to come back.
  ///
  /// Returns true when the review completed (phase `ready`), false when it
  /// was cancelled, failed, or there was nothing to review.
  Future<bool> startGameReview({int depth = 13}) async {
    final sanMoves = loadedSanMoves;
    if (!isGameLoaded || sanMoves == null || sanMoves.isEmpty) return false;

    // A fresh review always starts clean (and cancels any running one).
    cancelRunningReview();

    final mainline = <MoveNode>[];
    MoveNode? current = controller.root.children.isEmpty
        ? null
        : controller.root.children.first;
    while (current != null) {
      mainline.add(current);
      current = current.children.isEmpty ? null : current.children.first;
    }
    if (mainline.isEmpty) return false;

    final runId = ++_reviewRunId;
    final engine = StockfishEngineService.instance;
    final engineOwner = '$_engineOwnerPrefix-review-$runId';
    if (!engine.tryAcquireExclusive(engineOwner)) return false;
    _activeEngineOwner = engineOwner;

    bool isCanceled() => runId != _reviewRunId;

    // -------------------------------------------------------------------
    // STEP 1 — classification (identical UX to a plain analysis run).
    // -------------------------------------------------------------------
    isAnalyzing = true;
    controller.goToStart();
    analysisProgress = (0, mainline.length);
    reviewPhase = GameReviewPhase.classifying;
    reviewExplanations = const [];
    completedInBackground = false;
    notifyListeners();

    final analyzer = GameAnalyzer(controller: controller);
    try {
      await analyzer.analyze(
        mainline: mainline,
        depth: depth,
        onProgress: (node, done, total) {
          if (isCanceled()) return;
          analysisProgress = (done.round(), total.round());
          notifyListeners();
        },
        isCanceled: isCanceled,
      );

      if (isCanceled()) return false;

      isGameAnalyzed = true;
      bookEnded = analyzer.bookEnded;
      lastBookPositionFen = analyzer.lastBookParentFen;
      engine.setLines(2);
    } catch (e) {
      if (isCanceled()) return false;
      isAnalyzing = false;
      reviewPhase = GameReviewPhase.failed;
      notifyListeners();
      return false;
    } finally {
      // Clear pending flags left on partially processed nodes so no spinner
      // gets stuck when the run ends early or fails.
      if (!isCanceled()) {
        for (final node in mainline) {
          if (node.isPendingClassification) {
            node.isPendingClassification = false;
          }
        }
      }
      if (runId == _reviewRunId) {
        isAnalyzing = false;
        notifyListeners();
      }
      engine.releaseExclusive(engineOwner);
      if (_activeEngineOwner == engineOwner) _activeEngineOwner = null;
    }

    if (isCanceled()) return false;

    // -------------------------------------------------------------------
    // STEP 2 — coach request. The engine is free again; the screen shows
    // the simple review-waiting state while the request is in flight.
    // -------------------------------------------------------------------
    reviewPhase = GameReviewPhase.awaitingCoach;
    notifyListeners();
    return _requestReviewExplanations(runId);
  }

  /// STEP 2 continuation: builds the Enhanced PGN payload, waits for the
  /// coach response and aligns the notes with the mainline. Split out of
  /// [startGameReview] only to keep each function readable.
  Future<bool> _requestReviewExplanations(int runId) async {
    bool isCanceled() => runId != _reviewRunId;

    final userColor = GameReviewAnalyzer.userColorFromHeaders(loadedHeaders);
    final payload = GameReviewAnalyzer.buildReviewPayload(
      controller,
      userColor: userColor,
    );

    List<AICoachNote> notes = const [];
    if (payload != null) {
      try {
        notes = await GameReviewAnalyzer.fetchAIExplanations(payload);
      } catch (e) {
        if (isCanceled()) return false;
        reviewPhase = GameReviewPhase.failed;
        notifyListeners();
        return false;
      }
    }

    if (isCanceled()) return false;

    reviewExplanations = GameReviewAnalyzer.mapExplanationsToMainline(
      controller,
      notes,
    );

    // The classification results are always usable; only the explanation
    // step can fail the review.
    reviewPhase = notes.isEmpty
        ? GameReviewPhase.failed
        : GameReviewPhase.ready;
    notifyListeners();
    return reviewPhase == GameReviewPhase.ready;
  }

  /// Cancels a running Game Review at any phase. During the classification
  /// step this reuses [cancelRunningAnalysis] (which also wipes the
  /// classifications produced so far, matching the plain analysis Cancel
  /// semantics); during the coach wait it simply invalidates the run so the
  /// awaited response is discarded when it arrives.
  void cancelRunningReview() {
    final bool wasActive =
        reviewPhase == GameReviewPhase.classifying ||
        reviewPhase == GameReviewPhase.awaitingCoach;
    if (!wasActive) return;

    _reviewRunId++;
    if (isAnalyzing) {
      cancelRunningAnalysis();
    }
    reviewPhase = GameReviewPhase.idle;
    reviewExplanations = const [];
    notifyListeners();
  }

  /// Marks the review as failed before it even starts (e.g. the Stockfish
  /// process could not be launched). Used so EVERY review failure — whatever
  /// its cause — surfaces through the same single generic message.
  void markReviewFailed() {
    _reviewRunId++;
    isAnalyzing = false;
    reviewPhase = GameReviewPhase.failed;
    reviewExplanations = const [];
    notifyListeners();
  }

  /// Clears all review state without notifying (used when a new game is
  /// loaded or the session is reset — the caller notifies).
  void _resetReviewState() {
    _reviewRunId++;
    reviewPhase = GameReviewPhase.idle;
    reviewExplanations = const [];
  }
}
