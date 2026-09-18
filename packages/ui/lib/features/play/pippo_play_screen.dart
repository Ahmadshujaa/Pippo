import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';
import 'package:atlas_ui/shared/widgets/PippoChatBubble.dart';
import 'package:atlas_ui/features/analysis/widgets/MoveClassificationUI.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// How the game plays: Challenge keeps the competitive experience tight
/// (no hints/takebacks/hidden threats), while Training turns Pippo into a
/// coach (move feedback, visible threats, free takebacks, blunder pause,
/// hints).
enum PippoGameMode { challenge, training }

class PippoPlayScreen extends StatefulWidget {
  const PippoPlayScreen({super.key});

  @override
  State<PippoPlayScreen> createState() => _PippoPlayScreenState();
}

class _PippoPlayScreenState extends State<PippoPlayScreen> {
  late ChessboardController _controller;

  // Game state
  bool _isGameStarted = false;
  bool _isPlayingAsWhite = true;
  double _elo = 1500;
  bool _isThinking = false;
  String? _thinkingMessage;
  bool _engineMoveInProgress = false;
  bool _isRandomColor = false;

  // Mode: Challenge = competitive, Training = coached helper mode.
  PippoGameMode _mode = PippoGameMode.challenge;
  // Red threat-arrow toggle for Pippo's just-played move (analysis-screen style).
  bool _threatArrowsVisible = false;
  // Training-only: pause the game when the player makes a blunder so they
  // can look around / take back before the position moves on.
  bool _pausedForBlunder = false;
  // The user move (node) that triggered the blunder pause, so the Pippo
  // bubble can name the actual move played and offer "Take back" / "Continue".
  MoveNode? _blunderPauseNode;
  String? _pippoBubbleMessage;
  bool _isGameOver = false;
  String? _gameOverMessage;
  // Whether the finished game was a draw. Tracked separately from
  // [_gameOverMessage] because that text is localized and can no longer be
  // sniffed for the English word "draw".
  bool _gameOverIsDraw = false;
  // The game exactly as it was recorded when it ended (moves, result, player
  // colour, Pippo's Elo/name, timestamp). The result panel's Analyze action
  // hands this straight to the Analysis screen, so the finished game opens
  // there the same way a stored/imported game does.
  SavedGame? _finishedGame;

  /// Pippo's chat lines in the on-screen language. Built on demand (rather
  /// than `static const`) so the whole game talks to the user in the language
  /// picked in Settings.
  List<String> _thinkingMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.opponentThinking,
      l10n.pippoThinking2,
      l10n.pippoThinking3,
      l10n.pippoThinking4,
    ];
  }

  List<String> _threatMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.pippoThreatAsk1,
      l10n.pippoThreatAsk2,
      l10n.pippoThreatAsk3,
      l10n.pippoThreatAsk4,
    ];
  }

  List<String> _greatMoveMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.pippoGreat1,
      l10n.pippoGreat2,
      l10n.pippoGreat3,
    ];
  }

  List<String> _brilliantMoveMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.pippoBrilliant1,
      l10n.pippoBrilliant2,
      l10n.pippoBrilliant3,
    ];
  }

  List<String> _finishedMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.pippoFinished1,
      l10n.pippoFinished2,
      l10n.pippoFinished3,
    ];
  }

  // Move-history navigation (kept in sync with the controller's move tree).
  final ScrollController _movesScrollController = ScrollController();
  int _lastMovePly = 0;

  // Engine request guard: bumping this invalidates any in-flight engine move,
  // so a stale "best move" reply can never be applied to the wrong position
  // (e.g. after the board is reset mid-game).
  int _engineRequestId = 0;

  // Player info
  static const String _pippoName = 'Pippo';

  // Board orientation
  BoardOrientation _boardOrientation = BoardOrientation.white;

  // Classification & Stockfish background (exact replica of AnalysisScreen logic)
  bool _classifyUserMoves = true;
  bool _classifyPippoMoves = true;
  StreamSubscription<AnalysisResult>? _engineSubscription;
  StreamSubscription<void>? _engineAvailabilitySubscription;
  Timer? _engineDebounce;
  static const Duration _engineDebounceDuration = Duration(milliseconds: 200);
  bool _classificationReflowScheduled = false;
  bool _classificationReflowRunning = false;
  bool _classificationReflowQueued = false;
  bool _isEngineInitializing = false;
  String? _lastAnalyzedFen;
  final Set<MoveNode> _bookCheckInFlight = {};
  bool _bookEnded = false;
  String? _lastBookFen;
  String? _classificationSearchFen;
  MoveNode? _classificationSearchNode;
  // Keep interactive classification aligned with the full-game analyzer.
  // Depth 13 is the classifier's reliability milestone and avoids making
  // each Pippo move wait for an unnecessary deeper search.
  final double _engineDepth = 13;
  final int _engineLines = 2;

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController();
    _controller.addListener(_onBoardUpdate);
    _engineAvailabilitySubscription = StockfishEngineService
        .instance
        .exclusiveAvailabilityStream
        .listen((_) => _handleEngineAvailabilityChanged());
    _engineSubscription = StockfishEngineService.instance.analysisStream
        .listen(_handleEngineUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onBoardUpdate);
    _movesScrollController.dispose();
    _engineSubscription?.cancel();
    _engineAvailabilitySubscription?.cancel();
    _engineDebounce?.cancel();
    // Keep Stockfish process warm for instant re-enable (do not stop engine here)
    super.dispose();
  }

  // =========================================================================
  // Helpers: user vs pippo move detection
  // =========================================================================

  bool _isUserMoveNode(MoveNode node) {
    if (node.move == null) return false;
    final userColor =
        _isPlayingAsWhite ? chess.Color.WHITE : chess.Color.BLACK;
    return node.move!.color == userColor;
  }

  bool _shouldClassifyNode(MoveNode node) {
    if (_mode != PippoGameMode.training) return false;
    if (node.isRoot || node.hasClassification) return false;
    if (_isUserMoveNode(node)) return _classifyUserMoves;
    return _classifyPippoMoves;
  }

  /// True when the board shows the live tip of the game (the position play is
  /// actually at). Browsing back/forward through played moves leaves this
  /// false, so history review is read-only: Pippo's engine is never asked to
  /// move in a position that already has the game's real reply after it.
  bool get _isLiveGamePosition => !_controller.canRedo;

  // True when the current board node is Pippo's move and the threat detector
   // reports at least one material-winning capture for it. Drives both the
   // "Can you see what im threatning here?" chat bubble and the "Show threat"
   // button under the board.
   bool get _hasPippoThreatOnCurrentNode {
     final node = _controller.currentNode;
     if (node.isRoot || node.move == null || _isUserMoveNode(node)) return false;
     final moveUci =
         '${node.move!.fromAlgebraic}${node.move!.toAlgebraic}${node.move!.promotion?.name ?? ''}';
     return ThreatDetectorService
             .detect(fenBefore: node.parent!.fen, moveUci: moveUci)
             .isNotEmpty;
  }

  /// After Pippo lands a move, check whether it creates a material-winning
   /// threat for Pippo (analysis-screen-style red arrows). Arrows stay hidden
   /// in both modes until the player taps "Show threat".
  void _onPippoMovePlayed({required String fenBefore, required String moveUci}) {
     final threats = ThreatDetectorService.detect(fenBefore: fenBefore, moveUci: moveUci);
     if (!mounted) return;
    setState(() {
      // Keep threat arrows hidden until the player explicitly asks to see them.
      _threatArrowsVisible = false;
      if (threats.isNotEmpty) {
        _pippoBubbleMessage = _randomFrom(_threatMessages());
      }
    });
  }

  String _randomFrom(List<String> messages) =>
      messages[DateTime.now().microsecondsSinceEpoch % messages.length];

  // =========================================================================
  // Stockfish spin-up (exact same as AnalysisScreen._checkAndStartEngine)
  // =========================================================================

  Future<void> _ensureStockfishRunning() async {
    final stockfish = StockfishEngineService.instance;
    if (stockfish.hasExclusiveOwner) return;
    if (stockfish.isReady) return;
    if (_isEngineInitializing) return;
    _isEngineInitializing = true;
    try {
      stockfish.setThrottle(minDepth: 6, depthInterval: 4);
      await stockfish.start();
      if (stockfish.hasExclusiveOwner) return;
      stockfish.setLines(_engineLines);
      // Prime search for current position if classification will be needed
      _lastAnalyzedFen = null;
      if (_classifyUserMoves || _classifyPippoMoves) {
        final node = _controller.currentNode;
        if (!node.isRoot && node.isPendingClassification) {
          _ensureClassificationAnalyses(node);
        } else {
          _scheduleEngineSearch(_controller.game.fen);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stockfish failed to start: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      _isEngineInitializing = false;
    }
  }

  void _handleEngineAvailabilityChanged() {
    if (!mounted ||
        !_isGameStarted ||
        StockfishEngineService.instance.hasExclusiveOwner) {
      return;
    }
    _lastAnalyzedFen = null;
    if (StockfishEngineService.instance.isReady) _onBoardUpdate();
  }

  void _scheduleEngineSearch(String fen) {
    _scheduleEngineSearchForNode(fen);
  }

  /// Starts an engine search after the short move/navigation debounce.
  ///
  /// Ordinary searches must still be for the currently visible position. A
  /// classification search is allowed to target the current node's parent,
  /// because that position is intentionally off-screen while we fill the two
  /// cache entries needed for classification.
  void _scheduleEngineSearchForNode(String fen, {MoveNode? classificationNode}) {
    _engineDebounce?.cancel();
    _engineDebounce = Timer(_engineDebounceDuration, () {
      _engineDebounce = null;
      if (!mounted) return;
      if (!StockfishEngineService.instance.isReady ||
          StockfishEngineService.instance.hasExclusiveOwner) {
        return;
      }
      if (classificationNode != null) {
        if (!identical(_controller.currentNode, classificationNode) ||
            classificationNode.hasClassification ||
            !classificationNode.isPendingClassification) {
          return;
        }
      } else if (_controller.game.fen != fen) {
        return;
      }

      _classificationSearchFen = fen;
      _classificationSearchNode = classificationNode;
      StockfishEngineService.instance.analyze(
        fen,
        depth: _engineDepth.toInt(),
      );
    });
  }

  /// Ensures the two analyses required to classify [node] are produced in a
  /// deterministic order. Stockfish is a single shared process, so starting
  /// the child search before the parent is cached can interrupt the parent and
  /// make the reflow wait forever.
  void _ensureClassificationAnalyses(MoveNode node) {
    if (!mounted ||
        node.isRoot ||
        node.hasClassification ||
        !node.isPendingClassification ||
        !identical(node, _controller.currentNode)) {
      return;
    }

    final service = MoveClassificationService.instance;
    final parentFen = node.parent!.fen;
    final currentFen = node.fen;
    final parentCached = service.getCachedAnalysis(parentFen) != null;
    final currentCached = service.getCachedAnalysis(currentFen) != null;

    if (parentCached && currentCached) {
      _scheduleReflowClassifications();
      return;
    }

    final missingFen = parentCached ? currentFen : parentFen;
    if (_classificationSearchFen == missingFen &&
        identical(_classificationSearchNode, node)) {
      return;
    }

    _scheduleEngineSearchForNode(missingFen, classificationNode: node);
  }

  // =========================================================================
  // Engine update -> cache PositionAnalysis -> reflow (EXACT as AnalysisScreen)
  // =========================================================================

  void _handleEngineUpdate(AnalysisResult result) {
    if (!mounted) return;
    if (StockfishEngineService.instance.hasExclusiveOwner) return;

    if (result.depth >= 13 || result.isFinal) {
      final double mainEval = result.isMate
          ? (result.evaluation > 0 ? 100.0 : -100.0)
          : result.evaluation / 100.0;

      final posAnalysis = PositionAnalysis(
        evalInPawns: mainEval,
        mateIn: result.isMate ? result.evaluation.toInt() : null,
        expectedPoints: MoveClassificationService.instance
            .calculateExpectedPoints(
              mainEval,
              mateIn: result.isMate ? result.evaluation.toInt() : null,
            ),
        bestMoveUci: result.lines.isNotEmpty
            ? result.lines.first.rawPv.split(' ').first
            : "",
        principalVariation: result.lines.isNotEmpty
            ? result.lines.first.rawPv.split(' ')
            : [],
        candidateLines: result.lines.map((l) {
          double lineEval = 0.0;
          int? lineMate;
          if (l.eval.startsWith('M')) {
            lineMate = int.tryParse(l.eval.substring(1));
            lineEval = MoveClassificationService.instance
                .parseEngineEvaluation(l.eval);
          } else {
            lineEval = MoveClassificationService.instance
                .parseEngineEvaluation(l.eval);
          }

          return CandidateLine(
            moveUci: l.rawPv.split(' ').first,
            evalInPawns: lineEval,
            mateIn: lineMate,
            expectedPoints: MoveClassificationService.instance
                .calculateExpectedPoints(lineEval, mateIn: lineMate),
          );
        }).toList(),
      );

      MoveClassificationService.instance.cachePositionAnalysis(
        result.fen,
        posAnalysis,
      );

      _scheduleReflowClassifications();

      if (result.fen == _classificationSearchFen) {
        // This search has produced the cache entry that was requested. Clear
        // the marker before asking for the other half of the classification;
        // otherwise the continuation would mistake the completed parent
        // search for an already-running request and never start the child.
        _classificationSearchFen = null;
        _classificationSearchNode = null;
      }
    }

    // A move classification needs analyses for BOTH sides of the move. The
    // position before the move may be missing when a book move's background
    // search was interrupted by the next move. Once that parent search reaches
    // the cache threshold, continue with the destination search instead of
    // leaving the visible move pending forever.
    final currentNode = _controller.currentNode;
    if (!currentNode.isRoot &&
        currentNode.isPendingClassification &&
        !currentNode.hasClassification &&
        (result.fen == currentNode.parent!.fen ||
            result.fen == currentNode.fen)) {
      _ensureClassificationAnalyses(currentNode);
    }

    // The coordinator above owns continuation. There is intentionally no
    // elapsed-time retry or high-depth escape hatch: a healthy search must be
    // allowed to finish without being reset by the UI.
  }

  void _scheduleReflowClassifications() {
    if (_classificationReflowRunning) {
      _classificationReflowQueued = true;
      return;
    }
    if (_classificationReflowScheduled) return;
    _classificationReflowScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _classificationReflowScheduled = false;
      if (!mounted) return;
      _reflowClassifications();
    });
  }

  /// Recomputes any pending classifications that now have both cached
  /// analyses available.
  ///
  /// Classification runs expensive synchronous work (SEE-based brilliant
  /// detection, FEN parsing, legal-move generation). Each job is dispatched to
  /// the background [ClassificationScheduler] and awaited in order, so the UI
  /// thread never blocks on it. The running/queued guards mean an engine
  /// publish that lands mid-await cannot spawn a concurrent, duplicate pass.
  Future<void> _reflowClassifications() async {
    if (_classificationReflowRunning) return;
    if (!_classifyUserMoves && !_classifyPippoMoves) return;

    PerfTrace.start('reflow');
    _classificationReflowRunning = true;
    try {
      final path = _controller.currentPath;

      for (int i = 1; i < path.length; i++) {
        if (!mounted) return;
        final node = path[i];
        if (node.hasClassification) continue;
        if (!node.isPendingClassification) continue;
        final bool shouldClassify =
            _isUserMoveNode(node) ? _classifyUserMoves : _classifyPippoMoves;
        if (!shouldClassify) continue;

        final cachedCurrent = MoveClassificationService.instance
            .getCachedAnalysis(node.fen);
        final cachedParent = MoveClassificationService.instance.getCachedAnalysis(
          node.parent!.fen,
        );

        if (cachedCurrent != null && cachedParent != null) {
          final moveObj = node.move!;
          final moveUci = '${moveObj.fromAlgebraic}${moveObj.toAlgebraic}'
              '${moveObj.promotion?.name ?? ''}';

          final classification = await ClassificationScheduler.instance.classify(
            fenBefore: node.parent!.fen,
            moveUci: moveUci,
            analysisBefore: cachedParent,
            analysisAfter: cachedCurrent,
          );
          if (!mounted) return;
          // A navigation can occur while we awaited. Only attach the result to
          // the node that requested it (the controller keys results by node).
          if (node.hasClassification) continue;

          _controller.updateClassificationForNode(node, classification);
          if (mounted) _onClassificationApplied(node, classification);
        }
      }
    } finally {
      _classificationReflowRunning = false;
      PerfTrace.end('reflow');
      // A publish that arrived during the pass asked for another one.
      if (_classificationReflowQueued) {
        _classificationReflowQueued = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _reflowClassifications();
        });
      }
    }
  }

  Future<void> _attemptBookClassification(MoveNode node) async {
    final bool shouldClassify =
        _isUserMoveNode(node) ? _classifyUserMoves : _classifyPippoMoves;
    if (!shouldClassify) return;
    if (node.isRoot || node.hasClassification) return;
    if (_bookCheckInFlight.contains(node)) return;

    final parentFen = node.parent!.fen;
    final move = node.move!;
    final forced = MoveClassificationService.instance.tryClassifyForcedMove(
      parentFen,
      '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}',
    );
    if (forced != null) {
      _controller.updateClassificationForNode(node, forced);
      _onClassificationApplied(node, forced);
      return;
    }

    if (_bookEnded && parentFen != _lastBookFen) return;

    _bookCheckInFlight.add(node);
    try {
      final moveObj = node.move!;
      final moveUci =
          '${moveObj.fromAlgebraic}${moveObj.toAlgebraic}${moveObj.promotion?.name ?? ''}';

      final result = await BookMoveService.checkMove(
        parentFen,
        moveUci,
        moveSan: node.san.isEmpty ? null : node.san,
      );
      if (!mounted) return;

      final isCurrentNode = identical(node, _controller.currentNode);

      if (result.isBookMove) {
        if (isCurrentNode) {
          if (!StockfishEngineService.instance.hasExclusiveOwner) {
            StockfishEngineService.instance.stop();
          }
          _classificationSearchFen = null;
          _classificationSearchNode = null;
          _lastBookFen = parentFen;
          _bookEnded = false;
        }
        _controller.updateClassificationForNode(
          node,
          ClassificationResult(
            classification: MoveClassification.book,
            comment: AppLocalizations.of(context).classificationBookComment,
            evalBefore: 0,
            evalAfter: 0,
            epBefore: 0.5,
            epAfter: 0.5,
            loss: 0,
            bestMove: result.bestMoveUci ?? '',
            playedMoveUci: moveUci,
          ),
        );
      } else if (result.requestSucceeded && isCurrentNode) {
        _bookEnded = true;
      }
    } finally {
      _bookCheckInFlight.remove(node);
    }
  }

  // =========================================================================
  // Board listener: classification + engine gating (mirrors AnalysisScreen)
  // =========================================================================

  void _onBoardUpdate() {
    if (!_isGameStarted) return;

    if (_controller.game.game_over) {
      if (_isGameOver) return;
      if (_isThinking) setState(() => _isThinking = false);
      _showGameOver();
      return;
    }

    // Leaving the live tip (history navigation, jumps) is read-only review:
    // cancel any in-flight Pippo computation so its reply can never be
    // applied to a navigated position, and stop the thinking indicator.
    if (!_isLiveGamePosition) {
      _engineRequestId++;
      if (_isThinking) setState(() => _isThinking = false);
    }

    final fen = _controller.game.fen;
    final node = _controller.currentNode;

    // Track last analyzed fen for change detection (as in AnalysisScreen)
    final bool fenChanged = fen != _lastAnalyzedFen;
    if (fenChanged) {
      _lastAnalyzedFen = fen;
      // Pippo only ever talks about the move his line was written for: a
      // threat warning, praise for a great move, a missed win. As soon as the
      // board moves on, that line is retired — the events belonging to the NEW
      // move (see _onPippoMovePlayed / _onClassificationApplied) are the only
      // thing that may put something back. When they have nothing to say, the
      // bubble stays empty instead of repeating an old remark.
      if (_pippoBubbleMessage != null) {
        setState(() => _pippoBubbleMessage = null);
      }
      // A position change means the previous hint no longer applies. Clear it
      // without re-entering the board listener synchronously.

      scheduleMicrotask(() {
        if (mounted) {
          _controller.clearHints();
          if (_pausedForBlunder || _blunderPauseNode != null) {
            setState(() {
              _pausedForBlunder = false;
              _blunderPauseNode = null;
            });
          }
        }
      });
      // The engine service invalidates the previous search generation when a
      // new position is requested. No timer may restart it later.
      _classificationSearchFen = null;
      _classificationSearchNode = null;

      if (node.isRoot) {
        _bookEnded = false;
        _lastBookFen = null;
      }

      if (!node.isRoot && !node.hasClassification) {
        final bool shouldClassifyForNode = _shouldClassifyNode(node);
        if (shouldClassifyForNode) {
          _attemptBookClassification(node);
          _scheduleReflowClassifications();
          if (!node.hasClassification) {
            _controller.setPendingClassificationForNode(node, true);
            _ensureClassificationAnalyses(node);
          }
        } else {
          if (node.isPendingClassification) {
            _controller.setPendingClassificationForNode(node, false);
          }
        }
      }

      final PositionAnalysis? terminalAnalysis = MoveClassificationService
          .instance
          .terminalPositionAnalysis(fen);
      if (terminalAnalysis != null) {
        MoveClassificationService.instance.cachePositionAnalysis(
          fen,
          terminalAnalysis,
        );
        if (!node.isRoot && node.isPendingClassification) {
          _ensureClassificationAnalyses(node);
        }
        _scheduleReflowClassifications();
      } else if (StockfishEngineService.instance.isReady) {
        if (!node.isRoot && node.isPendingClassification) {
          _ensureClassificationAnalyses(node);
        } else {
          _scheduleEngineSearch(fen);
        }
      }
    }

    final isEngineTurn =
        (_isPlayingAsWhite && _controller.game.turn == chess.Chess.BLACK) ||
        (!_isPlayingAsWhite && _controller.game.turn == chess.Chess.WHITE);

    if (isEngineTurn && !_pausedForBlunder) {
      // History review: this node already has Pippo's real reply after it.
      // Never treat navigating here as a fresh position to move in.
      if (!_isLiveGamePosition) {
        if (_isThinking) setState(() => _isThinking = false);
        return;
      }
      if (!_isThinking) {
        setState(() {
          _isThinking = true;
          _thinkingMessage = _randomFrom(_thinkingMessages());
        });
      }
      final lastNode = _controller.currentNode;
      final bool userPendingForEngineTurn = lastNode.isPendingClassification &&
          _isUserMoveNode(lastNode) &&
          _classifyUserMoves;
      if (userPendingForEngineTurn) {
        return;
      }
      _makeEngineMove();
    }
  }

  Future<void> _makeEngineMove() async {
    if (!_isGameStarted || _engineMoveInProgress || _controller.game.game_over || _pausedForBlunder) {
      return;
    }

    final isEngineTurn =
        (_isPlayingAsWhite && _controller.game.turn == chess.Chess.BLACK) ||
        (!_isPlayingAsWhite && _controller.game.turn == chess.Chess.WHITE);
    if (!isEngineTurn) return;
    // Defense in depth: Pippo only ever moves at the live tip of the game,
    // never while the user is replaying history.
    if (!_isLiveGamePosition) return;

    _engineMoveInProgress = true;
    final requestId = _engineRequestId;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      _engineMoveInProgress = false;
      return;
    }
    if (requestId != _engineRequestId) {
      _engineMoveInProgress = false;
      if (_isThinking) setState(() => _isThinking = false);
      return;
    }
    if (!_isGameStarted || _controller.game.game_over) {
      _engineMoveInProgress = false;
      if (mounted) setState(() => _isThinking = false);
      return;
    }

    try {
      final bestMove = await PippoEngineService.instance.getBestMove(
        _controller.game,
        _elo.toInt(),
      );

      if (!mounted || requestId != _engineRequestId || !_isGameStarted || _pausedForBlunder) return;

      if (bestMove != null && bestMove.length >= 4) {
        final from = bestMove.substring(0, 2);
        final to = bestMove.substring(2, 4);
        final promo = bestMove.length > 4 ? bestMove.substring(4, 5) : 'q';

        final fenBefore = _controller.game.fen;
        _controller.makeMove(from, to, promotion: promo);
        // Check whether Pippo's just-played move left a material-winning
        // threat behind (analysis-screen red-arrow integration）.

        _onPippoMovePlayed(fenBefore: fenBefore, moveUci: bestMove);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Engine error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      _engineMoveInProgress = false;
      if (mounted) {
        setState(() => _isThinking = false);
      }
    }
  }

  void _startGame() {
    bool white;
    if (_isRandomColor) {
      white = DateTime.now().millisecondsSinceEpoch.isEven;
    } else {
      white = _isPlayingAsWhite;
    }

    _engineRequestId++;
    // Clear previous game state but keep classification toggles as-is
    MoveClassificationService.instance.clearCache();
    _bookEnded = false;
    _lastBookFen = null;
    _lastAnalyzedFen = null;
    _classificationSearchFen = null;
    _classificationSearchNode = null;
    _bookCheckInFlight.clear();
    // Clear any pending flags left over (controller reset will create fresh nodes)
    setState(() {
      _isPlayingAsWhite = white;
      _isGameStarted = true;
      _isGameOver = false;
      _gameOverMessage = null;
      _lastMovePly = 0;
      _boardOrientation = white
          ? BoardOrientation.white
          : BoardOrientation.black;
      _isThinking = false;
      _threatArrowsVisible = false;
      _pausedForBlunder = false;
      _blunderPauseNode = null;
    });

    _controller.reset();

    // Spin up Stockfish in background no matter what, keep warm even if disabled
    _ensureStockfishRunning();
    // If subscription already exists (engine was already warm), make sure throttle/lines are set
    if (StockfishEngineService.instance.isReady) {
      StockfishEngineService.instance.setThrottle(minDepth: 6, depthInterval: 4);
      StockfishEngineService.instance.setLines(_engineLines);
      // Re-attach listener if needed (in case it was cancelled)
      _engineSubscription ??=
          StockfishEngineService.instance.analysisStream
              .listen(_handleEngineUpdate);
      _lastAnalyzedFen = null;
      _scheduleEngineSearch(_controller.game.fen);
    }
  }

  void _resign() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.resignDialogTitle),
        content: Text(
          l10n.resignDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endGameByResignation();
            },
            child: Text(
              l10n.resignConfirm,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _endGameByResignation() {
    _saveGame(
      resultType: 'resignation',
      result: _isPlayingAsWhite ? '0-1' : '1-0',
    );
    setState(() {
      _isThinking = false;
      _isGameOver = true;
      _gameOverIsDraw = false;
      final l10n = AppLocalizations.of(context);
      _gameOverMessage = _isPlayingAsWhite
          ? l10n.gameOverResignBlack
          : l10n.gameOverResignWhite;
      _pippoBubbleMessage = _randomFrom(_finishedMessages());
    });
  }

  void _showGameOver() {
    final game = _controller.game;
    final l10n = AppLocalizations.of(context);
    String message = l10n.gameOverDefault;
    String resultType;
    String result;

    if (game.in_checkmate) {
      message = game.turn == chess.Chess.WHITE
          ? l10n.gameOverMateBlack
          : l10n.gameOverMateWhite;
      resultType = 'checkmate';
      result = game.turn == chess.Chess.WHITE ? '0-1' : '1-0';
    } else if (game.in_stalemate) {
      message = l10n.gameOverStalemate;
      resultType = 'stalemate';
      result = '1/2-1/2';
    } else if (game.in_threefold_repetition) {
      message = l10n.gameOverRepetition;
      resultType = 'repetition';
      result = '1/2-1/2';
    } else if (game.insufficient_material) {
      message = l10n.gameOverInsufficient;
      resultType = 'insufficient_material';
      result = '1/2-1/2';
    } else if (game.in_draw) {
      message = l10n.gameOverDrawn;
      resultType = 'draw';
      result = '1/2-1/2';
    } else {
      resultType = 'draw';
      result = '1/2-1/2';
    }

    _saveGame(resultType: resultType, result: result);
    setState(() {
      _isThinking = false;
      _isGameOver = true;
      _gameOverIsDraw = resultType != 'checkmate';
      _gameOverMessage = message;
      _pippoBubbleMessage = _randomFrom(_finishedMessages());
      _threatArrowsVisible = false;
      _pausedForBlunder = false;
      _blunderPauseNode = null;
    });
  }

  void _startNewGameFromResult() {
    _engineRequestId++;
    MoveClassificationService.instance.clearCache();
    setState(() {
      _isGameStarted = false;
      _isGameOver = false;
      _gameOverMessage = null;
      _gameOverIsDraw = false;
      _finishedGame = null;
      _pippoBubbleMessage = null;
      _controller.reset();
      _lastMovePly = 0;
      _bookEnded = false;
      _lastBookFen = null;
      _lastAnalyzedFen = null;
      _threatArrowsVisible = false;
    });
  }

  void _goHomeFromResult() => Navigator.pop(context);

  /// Hands the just-finished game to the Analysis screen, pre-loaded the same
  /// way a stored game is: the [SavedGame] recorded when the game ended is
  /// passed as the `/analysis` route arguments, and that screen loads its moves
  /// into the shared board/move tree — the identical path a normal PGN import
  /// takes (see `AnalysisScreen._loadInitialSavedGame`).
  void _analyzeGameFromResult() {
    final finished = _finishedGame;
    if (finished == null) return;
    Navigator.pushNamed(context, '/analysis', arguments: finished);
  }

  Future<void> _saveGame({required String resultType, required String result}) async {
    final game = SavedGame(
      moves: _playedSanMoves(),
      result: result,
      resultType: resultType,
      playerColor: _isPlayingAsWhite ? 'white' : 'black',
      elo: _elo.toInt(),
      opponent: _pippoName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    // Remember the exact game that was recorded, so the result panel's Analyze
    // action sends this game to the Analysis screen rather than rebuilding it
    // from the board (where browsing history could change what it looks like).
    _finishedGame = game;

    await GameStorageService.saveGame(game);

    // The game ended properly: hand it to the background puzzle generator.
    // It classifies the game with its own dedicated Stockfish instance
    // (completely invisible to the user) and turns the user's mistakes into
    // puzzles, then deletes the game itself.
    BackgroundPuzzleService.instance.onGameSaved(game);
  }

  /// The moves of the game as it was actually played: the path from the start
  /// position down to the node the board ended on.
  ///
  /// Walking the tree this way (instead of always following each node's first
  /// child) matters when the player went back to an earlier position and
  /// continued from there — that continuation is the real game line, while the
  /// abandoned branch is not part of the game that was played.
  List<String> _playedSanMoves() => _controller.currentPath
      .where((node) => !node.isRoot && node.san.isNotEmpty)
      .map((node) => node.san)
      .toList();

  // =========================================================================
  // BOARD CONTROLS
  // =========================================================================

  void _goToStart() => _controller.goToStart();

  void _goBack() {
    if (_controller.canUndo) _controller.undo();
  }

  void _goForward() {
    if (_controller.canRedo) _controller.redo();
  }

  void _goToEnd() => _controller.goToEnd();

  void _flipBoard() {
    setState(() {
      _boardOrientation = _boardOrientation == BoardOrientation.white
          ? BoardOrientation.black
          : BoardOrientation.white;
    });
  }

  // =========================================================================
  // TAKEBACK & CLASSIFICATION SETTINGS
  // =========================================================================

  MoveNode? _findLastUserMoveNode() {
    MoveNode? node = _controller.currentNode;
    while (node != null && !node.isRoot) {
      if (_isUserMoveNode(node)) return node;
      node = node.parent;
    }
    return null;
  }

  void _handleTakeback() {
    if (!_isGameStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).playStartFirst),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_mode == PippoGameMode.challenge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).takebackTrainingOnly),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    final lastUser = _findLastUserMoveNode();
    if (lastUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).takebackNoMoves),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    _engineRequestId++;
    setState(() => _isThinking = false);
    final bool deleted = _controller.deleteSubtree(lastUser);
    if (!deleted) {
      if (_controller.canUndo) _controller.undo();
    }
    _lastAnalyzedFen = null;
    if (_isGameStarted && StockfishEngineService.instance.isReady) {
      _scheduleEngineSearch(_controller.game.fen);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).takebackDone),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Training-mode helper: pause the game the moment the player's move is
  /// classified as a blunder, so they can review the position (and take
  /// back if they want) before the game moves on.

  void _onClassificationApplied(MoveNode node, ClassificationResult classification) {

    // A verdict always belongs to the move on the board when it arrives. A
    // late answer for a move the user (or Pippo) has already moved past must
    // not speak: the bubble was cleared when the position changed, and this
    // guard keeps it quiet rather than resurrecting an old line.
    if (!identical(node, _controller.currentNode)) {
      return;
    }

    if (_isUserMoveNode(node)) {
      final messages = switch (classification.classification) {
        MoveClassification.great => _greatMoveMessages(),
        MoveClassification.brilliant => _brilliantMoveMessages(),
        _ => null,
      };
      if (messages != null && mounted) {
        setState(() => _pippoBubbleMessage = _randomFrom(messages));
      } else if (classification.classification == MoveClassification.miss &&
          mounted) {
        // A miss means the user left a better move on the table: name it.
        final bestSan = _bestMoveSanFor(classification, node);
        final l10n = AppLocalizations.of(context);
        setState(() {
          _pippoBubbleMessage = bestSan.isEmpty
              ? l10n.pippoMissBare
              : l10n.pippoMissWithMove(bestSan);
        });
      }
    }

    if (_mode != PippoGameMode.training) {
      return;
    }
    if (!_isUserMoveNode(node) ||
        classification.classification != MoveClassification.blunder) {
      return;
    }
    if (_pausedForBlunder) {
      return;
    }
    if (!mounted) {
      return;
    }
    _engineRequestId++;
    setState(() {
      _pausedForBlunder = true;
      _blunderPauseNode = node;
      _isThinking = false;
      _pippoBubbleMessage =
          AppLocalizations.of(context).pippoBlunderPause;
    });
  }

  /// The engine's best move for the position before a miss, rendered in
  /// readable SAN (with a UCI fallback for malformed data). The
  /// classification result carries that move in UCI notation.
  String _bestMoveSanFor(ClassificationResult classification, MoveNode node) {
    final uci = classification.bestMove;
    final cleanMove = uci.trim().toLowerCase();
    if (cleanMove.length < 4) return uci;

    final parentFen = node.parent?.fen;
    if (parentFen == null) return uci;

    try {
      final board = chess.Chess.fromFEN(parentFen);
      final from = cleanMove.substring(0, 2);
      final to = cleanMove.substring(2, 4);
      final promotion = cleanMove.length > 4 ? cleanMove[4] : null;
      for (final move in board.generate_moves()) {
        if (move.fromAlgebraic == from &&
            move.toAlgebraic == to &&
            (move.promotion == null || move.promotion!.name == promotion)) {
          return board.move_to_san(move);
        }
      }
    } catch (_) {
      // Fall back to the raw UCI if the move cannot be resolved.
    }
    return uci;
  }

  void _resumeFromBlunderPause() {


    if (!mounted) return;
    setState(() {
      _pausedForBlunder = false;
      _blunderPauseNode = null;
      _pippoBubbleMessage = null;
    });
    // The engine may be waiting on its turn now (the board listener only
    // fires on move changes), so re-enter it after the rebuild.



    WidgetsBinding.instance.addPostFrameCallback((_) {



      if (mounted) _onBoardUpdate();



    });



  }

/// "Take back" from the blunder bubble: delete the blunder node (same flow
  /// as the Takeback button, minus the Challenge-mode gate — this only ever
  /// fires in Training mode) and resume play from the position before it.
 void _takeBackBlunder() {

    if (!mounted) return;
    _engineRequestId++;
    setState(() {
      _pausedForBlunder = false;
      _blunderPauseNode = null;
      _pippoBubbleMessage = null;
    });
    final lastUser = _findLastUserMoveNode();
    if (lastUser != null) {
      final bool deleted = _controller.deleteSubtree(lastUser);
      if (!deleted && _controller.canUndo) _controller.undo();
    }
    _lastAnalyzedFen = null;
    if (_isGameStarted && StockfishEngineService.instance.isReady) {

      _scheduleEngineSearch(_controller.game.fen);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).takebackDone),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  void _toggleThreatArrows() {



    if (!_hasPippoThreatOnCurrentNode) return;



    setState(() => _threatArrowsVisible = !_threatArrowsVisible);



  }

  void _handleHint() {



    if (!_isGameStarted) {
      _showQuickSnack(AppLocalizations.of(context).playStartFirst);
      return;
    }
    if (_mode != PippoGameMode.training) {
      _showQuickSnack(AppLocalizations.of(context).hintTrainingOnly);
      return;
    }
    final bool isUsersTurn =
        (_isPlayingAsWhite && _controller.game.turn == chess.Chess.WHITE) ||
        (!_isPlayingAsWhite && _controller.game.turn == chess.Chess.BLACK);
    if (!isUsersTurn) {
      _showQuickSnack(AppLocalizations.of(context).hintYourTurnOnly);
      return;
    }
    final analysis = MoveClassificationService.instance
        .getCachedAnalysis(_controller.game.fen);
    if (analysis == null || analysis.bestMoveUci.isEmpty || analysis.bestMoveUci.length < 4
        || analysis.bestMoveUci.length > 5) {
      _showQuickSnack(AppLocalizations.of(context).hintStillAnalyzing);
      return;
    }
    final hintUci = analysis.bestMoveUci;

    // Mark only the piece to move (the source square of Stockfish's top move),
    // as requested: no destination highlight, no arrow.

    final from = hintUci.substring(0, 2);
    _controller.setHintSquare(from);
    final piece = _controller.game.get(from);
    final l10n = AppLocalizations.of(context);
    final pieceName = piece == null
        ? l10n.pieceGeneric
        : switch (piece.type) {
            chess.Chess.KNIGHT => l10n.pieceKnight,
            chess.Chess.BISHOP => l10n.pieceBishop,
            chess.Chess.ROOK => l10n.pieceRook,
            chess.Chess.QUEEN => l10n.pieceQueen,
            chess.Chess.KING => l10n.pieceKing,
            _ => l10n.piecePawn,
          };
    setState(() {
      _pippoBubbleMessage = l10n.hintLookForPiece(pieceName, from);
    });
  }

  void _showQuickSnack(String message, {Duration? duration}) {



    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  void _showPlayTools() {
    if (_mode != PippoGameMode.training) return;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: Text(l10n.playToolTakeback),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleTakeback();
              },
            ),
            if (_mode == PippoGameMode.training)
              ListTile(
                leading: const Icon(Icons.lightbulb_rounded),
                title: Text(l10n.playToolAskHint),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleHint();
                },
              ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: Text(
                l10n.playToolClassifyHeader,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _buildSwitchTile(
              l10n.classifyYourMoves,
              _classifyUserMoves,
              (value) {
                setState(() => _classifyUserMoves = value);
                setSheetState(() {});
              },
              Theme.of(context),
            ),
            _buildSwitchTile(
              l10n.classifyPippoMoves,
              _classifyPippoMoves,
              (value) {
                setState(() => _classifyPippoMoves = value);
                setSheetState(() {});
              },
              Theme.of(context),
            ),
            const SizedBox(height: 12),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        // Pre-game settings screen (Elo / mode): just a back arrow that
        // always returns home. Once the game starts, the top bar shows the
        // title plus Resign and no back navigation.
        leading: _isGameStarted
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
        title: _isGameStarted
            ? Text(
                AppLocalizations.of(context).playingPippoTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                ),
              )
            : null,
        actions: [
          if (_isGameStarted && !_isGameOver)
            TextButton.icon(
              onPressed: _resign,
              icon: const Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppColors.error,
              ),
              label: Text(
                AppLocalizations.of(context).resignButton,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isGameStarted ? _buildGameView(theme) : _buildPreGameView(theme),
    );
  }

  // =========================================================================
  // PRE-GAME VIEW — Clean options layout
  // =========================================================================

  Widget _buildPreGameView(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Pip PO logo, centered.
        const Center(
          child: Column(
            children: [
              PippoAvatar(size: 72, cornerRadius: 18),
              SizedBox(height: 6),
              Text(
                'Pippo',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          l10n.playAsHeader,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final sideChipWidth = (constraints.maxWidth - 24) / 3;
            final iconBoxSize = (sideChipWidth - 20).clamp(36.0, 48.0);
            final labelSize = (sideChipWidth - 20).clamp(12.0, 13.0);
            return Row(
              children: [
                Expanded(
                  child: _buildSideChip(
                    icon: SizedBox(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      child: _kingIcon(isWhite: true),
                    ),
                    label: l10n.sideWhite,
                    labelSize: labelSize,
                    isSelected: _isPlayingAsWhite && !_isRandomColor,
                    onTap: () => setState(() {
                      _isPlayingAsWhite = true;
                      _isRandomColor = false;
                    }),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSideChip(
                    icon: SizedBox(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      child: _kingIcon(isWhite: false),
                    ),
                    label: l10n.sideBlack,
                    labelSize: labelSize,
                    isSelected: !_isPlayingAsWhite && !_isRandomColor,
                    onTap: () => setState(() {
                      _isPlayingAsWhite = false;
                      _isRandomColor = false;
                    }),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSideChip(
                    icon: SizedBox(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      child: _randomKingIcon(),
                    ),
                    label: l10n.sideRandom,
                    labelSize: labelSize,
                    isSelected: _isRandomColor,
                    onTap: () => setState(() {
                      _isRandomColor = true;
                    }),
                    theme: theme,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          l10n.strengthHeader,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtleOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                '${_elo.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _elo,
                  min: 400,
                  max: 3000,
                  divisions: (3000 - 400) ~/ 50,
                  label: '${_elo.toInt()}',
                  onChanged: (val) => setState(() => _elo = val),
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.optionsHeader,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtleOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.modeLabel,
                      style: TextStyle(
                        fontSize:    13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildModeChip(theme, mode: PippoGameMode.challenge, label: l10n.modeChallenge),
                  const SizedBox(width: 8),
                  _buildModeChip(theme, mode: PippoGameMode.training, label: l10n.modeTraining),
                ],
              ),
              const SizedBox(height: 10),
              ..._modePerks(context, theme),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.startGameButton,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip(ThemeData theme, {required PippoGameMode mode, required String label}) {
    final bool selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  List<Widget> _modePerks(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (_mode == PippoGameMode.training) {
      return [
        _PerkRow(icon: Icons.feedback_rounded, label: l10n.perkFeedback),
        _PerkRow(icon: Icons.visibility_rounded, label: l10n.perkSeeThreats),
        _PerkRow(icon: Icons.undo_rounded, label: l10n.perkTakeback),
        _PerkRow(icon: Icons.pause_circle_rounded, label: l10n.perkBlunderPause),
        _PerkRow(icon: Icons.lightbulb_rounded, label: l10n.perkHintsAllowed),
      ];
    }
    return [
      _PerkRow(icon: Icons.feedback_outlined, label: l10n.perkNoFeedback),
      _PerkRow(icon: Icons.visibility_off_rounded, label: l10n.perkHiddenThreats),
      _PerkRow(icon: Icons.undo_rounded, label: l10n.perkNoTakebacks),
      _PerkRow(icon: Icons.play_circle_outline_rounded, label: l10n.perkNoBlunderPause),
      _PerkRow(icon: Icons.lightbulb_outline_rounded, label: l10n.perkNoHints),
    ];
  }

  Widget _buildSideChip({
    required Widget icon,
    required String label,
    required double labelSize,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceSubtleOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Loads the king piece SVG at its native colors (white king with dark
  /// outline, black king with dark outline) -- no tinting, so it looks like a
  /// real chess piece in both themes.
  ///
  /// [package] is required: the SVGs are declared in the atlas_ui package,
  /// so the plain path only resolves when the package qualifier is passed
  /// (same pattern as ChessBoard.dart / PippoAvatar.dart).
  Widget _kingIcon({required bool isWhite}) {
    return SvgPicture.asset(
      isWhite
          ? 'assets/pieces/spatial/wK.svg'
          : 'assets/pieces/spatial/bK.svg',
      package: 'atlas_ui',
      fit: BoxFit.contain,
      placeholderBuilder: (context) => const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.crop_square),
      ),
    );
  }

  /// One king split down the middle: white on the left half, black on the
  /// right half. Fills its parent box, so it can never overflow the chip.
  Widget _randomKingIcon() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _kingIcon(isWhite: true),
        ClipRect(
          clipper: const _RightHalfClipper(),
          child: _kingIcon(isWhite: false),
        ),
      ],
    );
  }



  // =========================================================================
  // GAME VIEW
  // =========================================================================

  Widget _buildGameView(ThemeData theme) {
    final isPlayerTurn =
        (_isPlayingAsWhite && _controller.game.turn == chess.Chess.WHITE) ||
        (!_isPlayingAsWhite && _controller.game.turn == chess.Chess.BLACK);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _buildOpponentHeader(theme),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IgnorePointer(
              ignoring:
                  !isPlayerTurn || _isGameOver || _controller.game.game_over || _isThinking || _pausedForBlunder,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final node = _controller.currentNode;
                  final bool boardEnabled = _mode == PippoGameMode.training &&
                      !node.isRoot &&
                      (_isUserMoveNode(node)
                          ? _classifyUserMoves
                          : _classifyPippoMoves);
                  final Set<String> filter = boardEnabled
                      ? {
                          for (var v in MoveClassification.values)
                            MoveClassificationUI.getLabel(v)
                        }
                      : <String>{};
                  return ChessBoard(
                    controller: _controller,
                    settings:
                        ChessboardSettings(orientation: _boardOrientation),
                    classificationEnabled: boardEnabled,
                    classificationFilter: filter,
                    threatDetectorEnabled: _threatArrowsVisible,
                    showSettingsButton:
                        !_isGameOver && _mode != PippoGameMode.training,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (_hasPippoThreatOnCurrentNode) ...[
            _buildThreatToggleRow(theme),
            const SizedBox(height: 4),
          ],
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildBoardControls(theme),
          ),
          if (_isGameOver) _buildGameResultPanel(theme),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildTakebackAndClassRow(theme),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              _maybeAutoScrollMoves();
              return _buildMovesSection(theme);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOpponentHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PippoAvatar(size: 52, cornerRadius: 16),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context).pippoEloLabel(_elo.toInt()),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PippoChatBubble(
                  message: _pippoBubbleMessage ??
                      (_isThinking ? _thinkingMessage : null),
                  showAvatar: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOARD CONTROLS
  // =========================================================================

  Widget _buildBoardControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            Icons.first_page,
            _controller.canUndo ? _goToStart : null,
            theme,
          ),
          _controlButton(
            Icons.chevron_left,
            _controller.canUndo ? _goBack : null,
            theme,
          ),
          _controlButton(Icons.sync, _flipBoard, theme),
          _controlButton(
            Icons.chevron_right,
            _controller.canRedo ? _goForward : null,
            theme,
          ),
          _controlButton(
            Icons.last_page,
            _controller.canRedo ? _goToEnd : null,
            theme,
          ),
        ],
      ),
    );
  }

  /// Under-the-board toggle that appears only when Pippo's just-played move
  /// creates a real material-winning threat (same red arrows as the analysis
  /// screen). It starts hidden and reads "Show threat" until the player taps it.
  Widget _buildThreatToggleRow(ThemeData theme) {
    final bool showThreats = _threatArrowsVisible;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: _buildActionButton(
        icon: showThreats ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        label: showThreats
            ? AppLocalizations.of(context).hideThreats
            : AppLocalizations.of(context).showThreat,
        onTap: _toggleThreatArrows,
        theme: theme,
      ),
    );
  }

  Widget _buildBlunderPauseBanner(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: _takeBackBlunder,
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: Text(AppLocalizations.of(context).playToolTakeback),
        ),
        FilledButton.icon(
          onPressed: _resumeFromBlunderPause,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(AppLocalizations.of(context).blunderContinue),
        ),
      ],
    );
  }

  Widget _buildGameResultPanel(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isDraw = _gameOverIsDraw;
    final accent = isDraw ? AppColors.primary : AppColors.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtleOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Icon(
              isDraw ? Icons.handshake_rounded : Icons.emoji_events_rounded,
              color: accent,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              _gameOverMessage ?? l10n.gameOverFallback,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goHomeFromResult,
                    child: Text(l10n.resultHome),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _startNewGameFromResult,
                    child: Text(l10n.resultNewGame),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _analyzeGameFromResult,
              child: Text(
                l10n.resultAnalyzeGame,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakebackAndClassRow(ThemeData theme) {
    if (_mode != PippoGameMode.training) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (_pausedForBlunder) _buildBlunderPauseBanner(theme),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: AppLocalizations.of(context).gameToolsTooltip,
            onPressed: _showPlayTools,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtleOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback? onTap, ThemeData theme) {
    final bool isEnabled = onTap != null;
    return IconButton(
      icon: Icon(
        icon,
        color: isEnabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
        size: 28,
      ),
      onPressed: onTap,
    );
  }

  // =========================================================================
  // MOVES SECTION
  // =========================================================================

  Widget _buildMovesSection(ThemeData theme) {
    final moveCount = (_mainLineLength + 1) ~/ 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AtlasCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).movesHeader,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_controller.root.children.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context).moveCountLabel(moveCount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _controller.root.children.isEmpty
                  ? _buildEmptyMoves(theme)
                  : _buildMovesList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMoves(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtleOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 26,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).movesEmptyPlay,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovesList(ThemeData theme) {
    final pairs = <Map<String, dynamic>>[];
    MoveNode? whiteNode = _controller.root.children.isNotEmpty
        ? _controller.root.children.first
        : null;

    int moveNum = 1;
    while (whiteNode != null) {
      final blackNode = whiteNode.children.isNotEmpty
          ? whiteNode.children.first
          : null;
      pairs.add({'number': moveNum, 'white': whiteNode, 'black': blackNode});
      moveNum++;
      whiteNode = blackNode?.children.isNotEmpty == true
          ? blackNode!.children.first
          : null;
    }

    return ListView.builder(
      controller: _movesScrollController,
      padding: EdgeInsets.zero,
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        final wNode = pair['white'] as MoveNode;
        final bNode = pair['black'] as MoveNode?;
        final num = pair['number'] as int;

        final isWhiteSelected = identical(_controller.currentNode, wNode);
        final isBlackSelected =
            bNode != null && identical(_controller.currentNode, bNode);

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (isWhiteSelected || isBlackSelected)
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$num.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildMoveTap(wNode, theme, isWhiteSelected)),
                const SizedBox(width: 12),
                Expanded(
                  child: bNode == null
                      ? const SizedBox.shrink()
                      : _buildMoveTap(bNode, theme, isBlackSelected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoveTap(MoveNode node, ThemeData theme, bool selected) {
    final bool isUserMove = _isUserMoveNode(node);
    final bool sideEnabled = isUserMove ? _classifyUserMoves : _classifyPippoMoves;
    final bool showPending =
        node.isPendingClassification && sideEnabled && !node.isRoot;
    final bool showIcon =
        node.hasClassification && sideEnabled && !showPending;

    return InkWell(
      onTap: () => _controller.jumpToNode(node),
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                node.san,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (showPending) ...[
              const SizedBox(width: 4),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else if (showIcon) ...[
              const SizedBox(width: 4),
              Image.asset(
                MoveClassificationUI.getAssetName(
                  node.classification!.classification,
                ),
                width: 15,
                height: 15,
                package: MoveClassificationUI.package,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MOVE-LIST HELPERS (auto-scroll)
  // =========================================================================

  int get _mainLineLength {
    var count = 0;
    MoveNode? node = _controller.root.children.isNotEmpty
        ? _controller.root.children.first
        : null;
    while (node != null) {
      count++;
      node = node.children.isNotEmpty ? node.children.first : null;
    }
    return count;
  }

  void _maybeAutoScrollMoves() {
    final mainLineLength = _mainLineLength;
    if (mainLineLength > _lastMovePly) {
      _lastMovePly = mainLineLength;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_movesScrollController.hasClients) return;
        _movesScrollController.animateTo(
          _movesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    } else if (mainLineLength < _lastMovePly) {
      _lastMovePly = mainLineLength;
    }
  }
}

/// Clips its child to the right half of its box (used by the random-color
/// king icon to overlay the black half on top of the white half).
class _RightHalfClipper extends CustomClipper<Rect> {
  const _RightHalfClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant _RightHalfClipper oldClipper) => false;
}
/// One line of the pre-game Mode perk list (e.g. "See all threats").
class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size:   15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
