import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chess/chess.dart' as chess;
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/AppBottomNav.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/AtlasTextField.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/features/analysis/widgets/EngineAnalysisPanel.dart';
import 'package:atlas_ui/features/analysis/widgets/GameListDialog.dart';
import 'package:atlas_ui/features/analysis/widgets/AnalyzeMenuDialog.dart';
import 'package:atlas_ui/features/analysis/widgets/MoveClassificationUI.dart';
import 'package:atlas_ui/features/analysis/widgets/OpeningExplorerUI.dart';
import 'package:atlas_ui/features/analysis/board_setup_screen.dart';
import 'package:atlas_ui/shared/widgets/PippoChatBubble.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnalysisScreen extends StatefulWidget {
  /// Optional stored game (from the Home screen's game review list) that is
  /// pre-loaded into the board and move tree when the screen opens.
  final SavedGame? initialSavedGame;

  const AnalysisScreen({super.key, this.initialSavedGame});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  // Session-level owner of the loaded game and full-game analysis state. This
  // must be shared (not owned by this widget) so an analysis run survives
  // navigating away and completes in the background.
  GameAnalysisService get _analysisService => GameAnalysisService.instance;

  /// The shared board/move-tree controller, owned by [GameAnalysisService].
  ChessboardController get _controller => _analysisService.controller;

  final TextEditingController _importController = TextEditingController();
  final TextEditingController _fenController = TextEditingController();
  String _activeImportSource = 'Lichess';
  String _activeImportSection = 'Game'; // 'Game' or 'FEN'
  bool _isEngineEnabled = false;
  ChessboardSettings _settings = const ChessboardSettings(
    showCoordinates: true,
  );

  // Engine State. The visible eval bar/engine panel owns its own analysis
  // state (see _EnginePanel); this screen only tracks loading/enabled flags.
  bool _isEngineLoading = false;
  StreamSubscription<AnalysisResult>? _engineUpdateSubscription;
  StreamSubscription<void>? _engineAvailabilitySubscription;

  // Engine Settings. Depth 18 is the sweet spot for low-end mobile: it is
  // deep enough for reliable classification (D13 milestone) while the search
  // actually terminates in reasonable time, so the engine does not pin both
  // fast cores forever and starve the UI thread on every interaction.
  double _engineDepth = 18;
  int _engineLines = 2;

  /// Depth used by the full-game analysis run, chosen in the Analyze menu
  /// (range 7-20). Defaults to 13, the depth the analysis pipeline is tuned
  /// for on low-end mobile.
  int _gameAnalysisDepth = 13;

  // Classification reflow is deferred to the end of the current frame (see
  // _scheduleReflowClassifications). This flag coalesces multiple engine
  // publishes that land in the same frame into a single pass.
  bool _classificationReflowScheduled = false;
  bool _classificationReflowRunning = false;
  bool _classificationReflowQueued = false;

  // Game Loading State (backed by the session service).
  Map<String, String>? get _loadedHeaders => _analysisService.loadedHeaders;
  List<String>? get _loadedSanMoves => _analysisService.loadedSanMoves;
  bool get _isGameLoaded => _analysisService.isGameLoaded;
  int _selectedTab = 0; // 0 = Moves, 1 = Explorer
  bool _isLoading = false;
  String? _importError;
  Future<OpeningExplorerResult?>? _explorerFuture;
  ExplorerDatabase _explorerDb = ExplorerDatabase.masters;
  Set<String> _explorerSpeeds = const {'blitz', 'rapid', 'classical'};
  Set<int> _explorerRatings = const {1600, 1800, 2000, 2200, 2500};
  String? _lastAnalyzedFen;
  String? _classificationSearchFen;
  MoveNode? _classificationSearchNode;

  // Move Classification State
  bool _isClassifying = false;
  bool get _isGameAnalyzed => _analysisService.isGameAnalyzed;

  /// Phase the screen last saw, so a transition INTO or OUT of
  /// [GameReviewPhase.failed] can re-arm the generic failure message.
  GameReviewPhase _lastReviewPhase = GameReviewPhase.idle;

  /// Set once a failed Game Review has been spoken for. A failure parks
  /// "Server Error, Please try again later" in the Pippo bubble, where it used
  /// to sit until the user ran another review. As soon as they start analyzing
  /// again — playing a move, walking the game, diverging — the stale error is
  /// retired and the bubble goes back to the normal per-move commentary
  /// ("e4 is a book move"), while "Retry review" stays available underneath.
  bool _reviewFailureDismissed = false;

  /// The compact (board-centric) view is only offered for games that have
  /// been ANALYZED or REVIEWED — a plain interactive session (moves played
  /// by hand) has no classification results worth compacting the screen
  /// for, so the compact-view option is hidden there.
  bool get _compactViewAvailable =>
      _isGameAnalyzed || _analysisService.reviewPhase == GameReviewPhase.ready;

  // -------------------------------------------------------------------------
  // Compact view & Game Review state.
  // -------------------------------------------------------------------------

  /// Whether the screen shows the compact (board-centric) view instead of the
  /// classic full analysis view. Reached by tapping the up arrow in the full
  /// view, or automatically when a Game Review completes.
  bool _isCompactView = false;

  /// Drives the white shimmer sweep over the "Your game is being reviewed"
  /// text while a Game Review is in flight. Only animating during that phase.
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Horizontal scroll controller for the compact main-game PGN strip.
  final ScrollController _pgnScrollController = ScrollController();

  /// Tap targets for the compact PGN strip, cached per tree version so the
  /// current move can be scrolled into view (keys must be stable across
  /// builds to resolve their contexts).
  final Map<int, GlobalKey> _pgnChipKeys = {};
  int _pgnChipKeysVersion = -1;

  // Full-Game Analysis State (backed by the session service).
  bool get _isAnalyzing => _analysisService.isAnalyzing;
  (int, int)? get _analysisProgress => _analysisService.analysisProgress;

  // Book Move State (backed by the session service).
  // The FEN of the position from which the last book move was played.
  String? get _lastBookPositionFen => _analysisService.lastBookPositionFen;
  // Whether the game has left the opening book (a non-book move was played).
  bool get _bookEnded => _analysisService.bookEnded;
  // Nodes that already have a book check in flight, to avoid duplicate
  // requests when the user navigates back and forth quickly.
  final Set<MoveNode> _bookCheckInFlight = {};

  // UI State Sync
  StateSetter? _sheetSetter;

  void _syncState([VoidCallback? fn]) {
    if (mounted) {
      setState(fn ?? () {});
      _sheetSetter?.call(() {});
    }
  }

  // Move Classification Settings
  bool _moveClassificationEnabled = true;
  bool _threatDetectorEnabled = false;
  bool _classificationsExpanded = false;
  final Map<String, bool> _classifications = {
    for (var v in MoveClassification.values)
      MoveClassificationUI.getLabel(v): true,
  };

  // Moves-tree cache: the move list is rebuilt only when the tree STRUCTURE
  // changes (a move is added or the game is loaded/reset). Each row is a
  // self-updating ListenableBuilder, so navigation and classification updates
  // re-render only the affected rows instead of re-walking the whole tree
  // (hundreds of widgets for a long game) on every controller notification.
  List<Widget>? _movesTreeCache;
  int _movesTreeCacheVersion = -1;
  Brightness? _movesTreeCacheBrightness;

  // Engine-search debounce: rapid navigation through moves restarts the
  // engine on every intermediate position. Waiting 200ms coalesces a burst
  // of board changes into a single search of the final position, so the
  // engine does not thrash while the user flips through the game.
  Timer? _engineSearchDebounce;
  static const Duration _engineSearchDebounceDuration = Duration(
    milliseconds: 200,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onBoardChanged);
    // Rebuild when the session analysis state changes (progress, active run,
    // completion) even for runs that keep going in the background.
    _analysisService.addListener(_onAnalysisServiceChanged);
    _restoreLichessSession();
    _explorerFuture = OpeningExplorerService.fetchOpeningData(
      _controller.game.fen,
      database: _explorerDb,
      speeds: _explorerSpeeds.toList(),
      ratings: _explorerRatings.toList(),
    );

    // Orchestrate Single-Engine Analysis & Classification. Interval 4 (with
    // the engine's own depth-13 milestone publish) keeps the UI informed while
    // cutting the number of stream emissions per search by ~30%.
    StockfishEngineService.instance.setThrottle(minDepth: 6, depthInterval: 4);
    _engineUpdateSubscription = StockfishEngineService.instance.analysisStream
        .listen(_handleEngineUpdate);
    _engineAvailabilitySubscription = StockfishEngineService
        .instance
        .exclusiveAvailabilityStream
        .listen((_) => _handleEngineAvailabilityChanged());

    // If a full-game analysis finished in the background while this screen was
    // away (e.g. the user navigated off mid-run), surface the finished report
    // once when the user returns so the analyzed game is clearly displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialSavedGame();
      // A Game Review that finished while this screen was away (or before a
      // rebind) lands directly in the compact review view.
      if (_analysisService.reviewPhase == GameReviewPhase.ready) {
        setState(() => _isCompactView = true);
      }
      if (_analysisService.completedInBackground) {
        _analysisService.completedInBackground = false;
        setState(() {});
        if (_analysisService.isGameAnalyzed) {
          _showGameReportDialog();
        }
      }
    });
  }

  /// Restores a previously saved Lichess OAuth session from the device and
  /// refetches explorer data once the token is available.
  Future<void> _restoreLichessSession() async {
    await LichessAuthService.instance.loadFromStorage();
    if (!mounted) return;
    if (LichessAuthService.instance.isSignedIn) {
      setState(() {
        _explorerFuture = OpeningExplorerService.fetchOpeningData(
          _controller.game.fen,
          database: _explorerDb,
          speeds: _explorerSpeeds.toList(),
          ratings: _explorerRatings.toList(),
        );
      });
    }
  }

  /// Runs the "Sign in with Lichess" OAuth flow and refreshes the explorer.
  Future<void> _handleExplorerSignIn() async {
    try {
      await LichessAuthService.instance.signIn();
      if (!mounted) return;
      setState(() {
        _explorerFuture = OpeningExplorerService.fetchOpeningData(
          _controller.game.fen,
          database: _explorerDb,
          speeds: _explorerSpeeds.toList(),
          ratings: _explorerRatings.toList(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      final msg =
          e.toString().contains('CANCELED') || e.toString().contains('cancel')
          ? AppLocalizations.of(context).lichessSignInCancelled
          : 'Sign-in failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      setState(() {});
    }
  }

  void _handleEngineUpdate(AnalysisResult result) {
    if (!mounted) return;
    if (StockfishEngineService.instance.hasExclusiveOwner) return;

    // 1. (Removed) Updating the visible eval bar/engine panel is owned by the
    // self-contained _EnginePanel widget, which subscribes to the analysis
    // stream directly and rebuilds only itself. No full-screen setState here.

    // 2. Cache Depth 13 data for classification.
    // Skipped while a full-game analysis run owns the engine: the run's own
    // classification searches publish through this same stream, and the
    // screen must not inject partial engine state into the classification
    // cache behind the run's back.
    if (!_isAnalyzing && (result.depth >= 13 || result.isFinal)) {
      // Classifier expects evaluations in PAWNS (1.0 = 100cp). For mate
      // scores, evaluation is the mate-in-N count (e.g. 3 = mate in 3), so
      // normalize to a saturated +-100.0 pawn value consistent with
      // MoveClassificationService.analyzePosition.
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
            lineEval = MoveClassificationService.instance.parseEngineEvaluation(
              l.eval,
            );
          } else {
            lineEval = MoveClassificationService.instance.parseEngineEvaluation(
              l.eval,
            );
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

      // 3. Global Reflow Trigger:
      // When any node hits D13, scan the game path to fill any gaps.
      // Deferred to after the frame so a publish that lands mid-interaction
      // never stalls the move animation / navigation rebuild.
      _scheduleReflowClassifications();

      if (result.fen == _classificationSearchFen) {
        _classificationSearchFen = null;
        _classificationSearchNode = null;
      }
    }

    if (_isAnalyzing) return;

    // A classification needs both the parent and destination analyses. Once
    // one search reaches the cache threshold, immediately queue the other one
    // instead of relying on a timer that can restart a healthy search.
    final node = _controller.currentNode;
    if (!node.isRoot &&
        node.isPendingClassification &&
        !node.hasClassification &&
        (result.fen == node.parent!.fen || result.fen == node.fen)) {
      _ensureClassificationAnalyses(node);
    }

    // Keep a pending move alive when a search finishes with a partial result;
    // the coordinator above will either use the cached final result or leave
    // the current search's result untouched for the next engine event.
    if (result.isFinal &&
        result.fen == node.fen &&
        !node.isRoot &&
        node.isPendingClassification &&
        !node.hasClassification) {
      _ensureClassificationAnalyses(node);
    }
  }

  void _handleEngineAvailabilityChanged() {
    if (!mounted ||
        !_isEngineEnabled ||
        _isAnalyzing ||
        StockfishEngineService.instance.hasExclusiveOwner) {
      return;
    }
    _lastAnalyzedFen = null;
    _onBoardChanged();
  }

  Future<void> _reflowClassifications() async {
    if (_classificationReflowRunning) return;
    if (!_moveClassificationEnabled) return;
    // The full-game analyzer classifies nodes sequentially from its own
    // searches; interactive reflow must not race it or classify nodes from
    // partial cache entries while it runs.
    if (_isAnalyzing) return;

    PerfTrace.start('reflow');
    _classificationReflowRunning = true;
    try {
      final path = _controller.currentPath;

      // Iterate through the game path and classify any node that has cached data
      // for both itself AND its parent. Notifications go through the controller
      // so the board and moves tree (which listen to it) refresh themselves
      // without a full-page rebuild.
      for (int i = 1; i < path.length; i++) {
        if (!mounted) return;
        final node = path[i];
        if (node.hasClassification) continue;

        final cachedCurrent = MoveClassificationService.instance
            .getCachedAnalysis(node.fen);
        final cachedParent = MoveClassificationService.instance
            .getCachedAnalysis(node.parent!.fen);

        if (cachedCurrent != null && cachedParent != null) {
          final moveObj = node.move!;
          final moveUci =
              '${moveObj.fromAlgebraic}${moveObj.toAlgebraic}'
              '${moveObj.promotion?.name ?? ''}';

          // Classification runs expensive synchronous work; dispatch each job
          // to the background scheduler so the UI thread stays responsive.
          final classification = await ClassificationScheduler.instance
              .classify(
                fenBefore: node.parent!.fen,
                moveUci: moveUci,
                analysisBefore: cachedParent,
                analysisAfter: cachedCurrent,
              );
          if (!mounted) return;
          if (node.hasClassification) continue;

          _controller.updateClassificationForNode(node, classification);
        }
      }
    } finally {
      _classificationReflowRunning = false;
      PerfTrace.end('reflow');
      if (_classificationReflowQueued) {
        _classificationReflowQueued = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _reflowClassifications();
        });
      }
    }
  }

  /// Defers [reflowClassifications] to the end of the current frame and
  /// coalesces multiple calls within one frame into a single pass.
  ///
  /// Classification runs expensive synchronous work (SEE-based brilliant
  /// detection, FEN parsing, legal-move generation); each job runs on the
  /// background [ClassificationScheduler] and is awaited in order. When an
  /// engine publish lands at the same moment the user makes a move or
  /// navigates the tree, running the scheduling after the frame completes
  /// keeps interactions smooth; the classification result simply appears one
  /// frame later.
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

  /// Fast-path book move detection.
  ///
  /// Called right after a move is made on the board. Asks the book move
  /// service whether the move that produced [node] is a book move, and if so
  /// classifies the node as [MoveClassification.book] immediately — without
  /// waiting for Stockfish. When the move is definitively NOT a book move,
  /// the book is considered over: from that point the existing engine-based
  /// classification flow takes over and the book service is not consulted
  /// again, unless the user tries another move from the exact same position
  /// from where the last book move was played.
  Future<void> _attemptBookClassification(MoveNode node) async {
    if (!_moveClassificationEnabled) return;
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
      return;
    }

    // Once the book is over, only re-consult the service when the user tries
    // another move from the exact position where the last book move was played.
    if (_bookEnded && parentFen != _lastBookPositionFen) return;

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
          // A book verdict makes the Stockfish request unnecessary. Stop the
          // interactive search so it cannot consume CPU or publish a stale
          // result after the move has already been classified.
          if (!StockfishEngineService.instance.hasExclusiveOwner) {
            StockfishEngineService.instance.stop();
          }
          _classificationSearchFen = null;
          _classificationSearchNode = null;
          // Record where this book move was played from so that backtracking
          // to this exact position re-enables book checking.
          _analysisService.lastBookPositionFen = parentFen;
          _analysisService.bookEnded = false;
        }
        _controller.updateClassificationForNode(
          node,
          ClassificationResult(
            classification: MoveClassification.book,
            comment: 'A move from the opening book.',
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
        // Definitively not in the book: the opening book is over from here.
        // Transient request failures keep the book "open" so a network blip
        // does not permanently disable book detection.
        _analysisService.bookEnded = true;
      }
    } finally {
      _bookCheckInFlight.remove(node);
    }
  }

  /// Ensures the parent and destination positions required for classifying
  /// [node] are analyzed in order. The shared engine can search one position
  /// at a time; keeping this coordinator explicit prevents a child request
  /// from interrupting a still-missing parent request.
  void _ensureClassificationAnalyses(MoveNode node) {
    if (!mounted ||
        !_moveClassificationEnabled ||
        !_isEngineEnabled ||
        !StockfishEngineService.instance.isReady ||
        StockfishEngineService.instance.hasExclusiveOwner ||
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

  void _scheduleEngineSearchForNode(String fen, {MoveNode? classificationNode}) {
    _engineSearchDebounce?.cancel();
    _engineSearchDebounce = Timer(_engineSearchDebounceDuration, () {
      _engineSearchDebounce = null;
      if (!mounted ||
          !_isEngineEnabled ||
          !StockfishEngineService.instance.isReady ||
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

  void _onAnalysisServiceChanged() {
    if (!mounted) return;
    final phase = _analysisService.reviewPhase;
    if (phase != _lastReviewPhase) {
      _lastReviewPhase = phase;
      // Any phase change makes a previous dismissal obsolete: a fresh failure
      // gets to speak again, and a new run starts from a clean slate.
      _reviewFailureDismissed = false;
    }
    // Keep the shimmer running while the whole review is in flight (the
    // waiting text is shown from the moment a review starts).
    if (phase == GameReviewPhase.classifying ||
        phase == GameReviewPhase.awaitingCoach) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else if (_shimmerController.isAnimating) {
      _shimmerController.stop();
    }
    // A finished review lands in the compact view where the explanations
    // live (Pippo bubble above the board).
    if (phase == GameReviewPhase.ready && !_isCompactView) {
      _isCompactView = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _analysisService.removeListener(_onAnalysisServiceChanged);
    _engineUpdateSubscription?.cancel();
    _engineAvailabilitySubscription?.cancel();
    _engineSearchDebounce?.cancel();
    _controller.removeListener(_onBoardChanged);
    _importController.dispose();
    _fenController.dispose();
    _shimmerController.dispose();
    _pgnScrollController.dispose();
    // If a full-game analysis is still running in the background, keep the
    // shared engine alive so it can finish. Otherwise stop it as before.
    if (!_analysisService.isAnalyzing) {
      StockfishEngineService.instance.stop();
    }
    super.dispose();
  }

  void _onBoardChanged() {
    final fen = _controller.game.fen;
    if (fen != _lastAnalyzedFen) {
      _lastAnalyzedFen = fen;
      // The user moved on, so a review-failure message parked in the Pippo
      // bubble is stale: drop it and let the per-move commentary for the
      // position now on the board speak instead.
      if (_analysisService.reviewPhase == GameReviewPhase.failed) {
        _reviewFailureDismissed = true;
      }
      // The active search is invalidated by StockfishEngineService when the
      // next position is requested; no timer is allowed to restart it.
      _classificationSearchFen = null;
      _classificationSearchNode = null;
      // Fetch opening-explorer data only while the Explorer tab is visible;
      // the moves tree and board refresh themselves via their own listeners
      // on the controller, so no full-page setState is needed here.
      if (_selectedTab == 1) {
        _explorerFuture = OpeningExplorerService.fetchOpeningData(
          fen,
          database: _explorerDb,
          speeds: _explorerSpeeds.toList(),
          ratings: _explorerRatings.toList(),
        );
      }

      final node = _controller.currentNode;
      if (node.isRoot) {
        // The user navigated back to the start of the line: reset the book
        // state so a fresh session of book detection starts on the next move.
        _analysisService.bookEnded = false;
        _analysisService.lastBookPositionFen = null;
      }

      // While a full-game analysis run is active it owns both the engine and
      // the classification state; interactive triggers fired from here
      // (classification updates also notify this listener) would interrupt
      // the run's sequential searches and pollute in-flight results.
      if (_isAnalyzing) return;

      // When the user finishes Board Setup, classification and engine analysis
      // must not start until they actually play a move in the created position.
      // This flag (set by the setup screen) makes the freshly-loaded root inert
      // (no engine search, no cached analysis) and clears itself the moment the
      // first move is played.
      if (_analysisService.suppressEngineUntilMove) {
        if (node.isRoot) return;
        _analysisService.suppressEngineUntilMove = false;
      }

      if (!node.isRoot && !node.hasClassification) {
        // Book move fast-path: ask the opening book first so book moves are
        // classified immediately, without waiting for Stockfish.
        _attemptBookClassification(node);

        // Immediate check: can we classify any moves in the current path from
        // cache? Deferred to after this frame so the board/navigation rebuild
        // for the position change is never delayed by classification work.
        _scheduleReflowClassifications();

        // if still not classified, show spinner (only when classification is
        // enabled, so a disabled feature never leaves a stuck spinner)
        if (_moveClassificationEnabled && !node.hasClassification) {
          _controller.setPendingClassificationForNode(node, true);
        }
      }

      // Terminal positions (checkmate / stalemate) produce no engine output,
      // so the move that ends the game would otherwise never be classified
      // and its spinner would spin forever. Resolve them deterministically,
      // cache the analysis and let the reflow classify the game-ending move.
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
      } else if (_isEngineEnabled && StockfishEngineService.instance.isReady) {
        if (!node.isRoot && node.isPendingClassification) {
          _ensureClassificationAnalyses(node);
        } else {
          // Debounced so a burst of navigation/moves searches only the final
          // position instead of restarting the engine on every step.
          _scheduleEngineSearch(fen);
        }
      }
    }
  }

  /// Coalesces engine restarts during rapid board changes into a single
  /// search of the final position. The search starts [Duration]ms after the
  /// last board change and only runs if the board is still on [fen].
  void _scheduleEngineSearch(String fen) {
    _scheduleEngineSearchForNode(fen);
  }

  Future<void> _checkAndStartEngine({bool silent = false}) async {
    try {
      if (!StockfishEngineService.instance.isReady) {
        setState(() => _isEngineLoading = true);
        await StockfishEngineService.instance.start();
        setState(() {
          _isEngineLoading = false;
          _isEngineEnabled = true;
        });
        _lastAnalyzedFen = null;
        StockfishEngineService.instance.setLines(_engineLines);
        _onBoardChanged();
      } else {
        setState(() => _isEngineEnabled = true);
        _lastAnalyzedFen = null;
        StockfishEngineService.instance.setLines(_engineLines);
        _onBoardChanged();
      }
    } catch (e) {
      setState(() => _isEngineLoading = false);
      if (!silent) {
        _showErrorDialog('Failed to start engine', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogOk),
          ),
        ],
      ),
    );
  }

  void _toggleEngine() {
    if (_isEngineEnabled) {
      _classificationSearchFen = null;
      _classificationSearchNode = null;
      setState(() {
        _isEngineEnabled = false;
        _isClassifying = false;
      });
      StockfishEngineService.instance.stop();
    } else {
      _checkAndStartEngine();
    }
  }

  void _flipBoard() {
    setState(() {
      _settings = _settings.copyWith(
        orientation: _settings.orientation == BoardOrientation.white
            ? BoardOrientation.black
            : BoardOrientation.white,
      );
    });
  }

  Future<void> _importGame() async {
    final input = _importController.text.trim();
    if (input.isEmpty) {
      _syncState(() => _importError = 'Please enter a PGN, URL, or FEN');
      return;
    }

    _syncState(() {
      _isLoading = true;
      _importError = null;
    });

    GameImportResult result;

    switch (_activeImportSource) {
      case 'PGN':
        result = await GameImportService.importFromPgn(input);
        break;
      case 'Lichess':
        await _searchUserGames(input, 'Lichess');
        return;
      case 'Chess.com':
        await _searchUserGames(input, 'Chess.com');
        return;
      default:
        result = GameImportResult.error('Unknown import source');
    }

    if (!mounted) return;

    if (result.success) {
      _onImportSuccess(result);
    } else {
      _importError = result.error;
    }

    _syncState(() => _isLoading = false);
  }

  void _onImportSuccess(GameImportResult result) {
    if (result.fen != null && result.pgn == null) {
      // FEN only - load position only, clear game state
      _controller.loadFen(result.fen!);
      _onBoardChanged();
      _fenController.clear();
      _analysisService.clearLoadedGameData();
      setState(() {});
      return;
    }

    // Full game loaded
    if (!_loadFullGame(result)) return;

    // Imports are initiated from the add sheet. Dismiss it once the game is
    // ready so the moves tree and game-analysis action are immediately visible.
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              result.fen != null
                  ? AppLocalizations.of(context).positionLoadedOk
                  : AppLocalizations.of(context).gameImportedOk,
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Loads a full game (PGN + headers + moves) into the board and move tree.
  /// Returns true if the game was loaded. The actual session state lives in
  /// [GameAnalysisService] so it survives leaving this screen.
  bool _loadFullGame(GameImportResult result) {
    if (result.pgn == null) return false;

    // Build the full history of the game.
    final game = chess.Chess();
    final fens = [game.fen];
    if (result.sanMoves != null) {
      for (final move in result.sanMoves!) {
        game.move(move);
        fens.add(game.fen);
      }
    }

    _analysisService.loadFullGame(
      pgn: result.pgn!,
      headers: result.headers,
      sanMoves: result.sanMoves,
      fens: fens,
    );
    _selectedTab = 0;
    _importController.clear();
    _onBoardChanged();
    setState(() {});
    return true;
  }

  /// Pre-loads a stored game (e.g. tapped from the Home screen's game review
  /// list) into the board and move tree so the user lands directly on it.
  void _loadInitialSavedGame() {
    final saved = widget.initialSavedGame;
    if (saved == null || saved.moves.isEmpty) return;

    final userIsWhite = saved.playerColor == 'white';
    final l10n = AppLocalizations.of(context);
    final headers = <String, String>{
      'Event': l10n.savedEventTitle(saved.opponent),
      'White': userIsWhite ? l10n.youLabel : saved.opponent,
      'Black': userIsWhite ? saved.opponent : l10n.youLabel,
      'Result': saved.result,
    };

    _loadFullGame(
      GameImportResult.success(
        pgn: _buildSavedGamePgn(headers, saved.moves, saved.result),
        headers: headers,
        sanMoves: saved.moves,
      ),
    );
  }

  String _buildSavedGamePgn(
    Map<String, String> headers,
    List<String> sanMoves,
    String result,
  ) {
    final buffer = StringBuffer();
    for (final entry in headers.entries) {
      buffer.writeln('[${entry.key} "${entry.value}"]');
    }
    buffer.writeln();
    for (int i = 0; i < sanMoves.length; i++) {
      if (i.isEven) buffer.write('${(i ~/ 2) + 1}. ');
      buffer.write('${sanMoves[i]} ');
    }
    buffer.write(result);
    return buffer.toString();
  }

  /// Loads a game from the opening explorer (top/recent game tap) into the
  /// board — same flow as importing a PGN manually.
  Future<void> _handleExplorerGameSelected(TopGame game) async {
    try {
      final pgn = await OpeningExplorerService.fetchGamePgn(
        game.id,
        database: _explorerDb,
      );
      if (!mounted) return;

      if (pgn == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load the game PGN'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await GameImportService.importFromPgn(pgn);
      if (!mounted) return;

      if (result.success) {
        _loadFullGame(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .explorerGameLoaded(game.whiteName, game.blackName)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to parse game'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load game: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importFen() async {
    final fen = _fenController.text.trim();
    if (fen.isEmpty) return;

    final result = GameImportService.loadFromFen(fen);
    if (result.success) {
      _onImportSuccess(result);
    } else {
      _syncState(() => _importError = result.error);
    }
  }

  void _clearLoadedGame() {
    // Clears the loaded game + analysis state and resets the shared board;
    // cancels any running analysis first. Kept on the session service so it
    // survives leaving the screen.
    _analysisService.clearLoadedGame();
    setState(() {
      _isEngineEnabled = false;
      _selectedTab = 0;
      _importController.clear();
      _fenController.clear();
      _importError = null;
      _isClassifying = false;
    });
    StockfishEngineService.instance.stop();
    _onBoardChanged();
  }

  /// Bumps the session analysis generation counter and aborts any in-flight
  /// engine search (see [GameAnalysisService.cancelRunningAnalysis]). When a
  /// Game Review is in its classification step, the cancel must stop the
  /// whole review instead of only the analysis pass.
  void _cancelRunningAnalysis() {
    if (_analysisService.reviewPhase == GameReviewPhase.classifying ||
        _analysisService.reviewPhase == GameReviewPhase.awaitingCoach) {
      _analysisService.cancelRunningReview();
    } else {
      _analysisService.cancelRunningAnalysis();
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Cancels a Game Review in any phase (used by the review-waiting state).
  void _cancelRunningReview() {
    _analysisService.cancelRunningReview();
    if (mounted) {
      setState(() {});
    }
  }

  /// Runs the full two-step Game Review on the loaded game.
  ///
  /// From the moment the review starts the screen shows the "your game is
  /// being reviewed" waiting state (no percentage ring). The classification
  /// step reuses the analysis pipeline of a plain full-game analysis at the
  /// depth chosen in the Analyze menu; then the Enhanced PGN built from those
  /// results is sent to the coach service. When everything completes, the
  /// screen switches to the compact view.
  Future<void> _startGameReview() async {
    // A new run always re-arms the generic failure message, so a retry that
    // fails again speaks up instead of being swallowed by an earlier dismissal
    // (the phase stays [GameReviewPhase.failed] when the engine cannot start,
    // so no phase change would do it for us).
    _reviewFailureDismissed = false;
    final sanMoves = _loadedSanMoves;
    if (sanMoves == null || sanMoves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reviewNoGame),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (!StockfishEngineService.instance.isReady || !_isEngineEnabled) {
      // Silent: any engine failure is folded into the single generic review
      // failure message shown in the Pippo bubble, never an error dialog.
      await _checkAndStartEngine(silent: true);
      if (!mounted || !_isEngineEnabled) {
        _analysisService.markReviewFailed();
        return;
      }
    }

    // Re-check immediately before starting. Usage is committed only after the
    // review result is successfully received below.
    if (!await DailyUsageService.canStartGameReview()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).reviewQuotaUsed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final received = await _analysisService.startGameReview(
        depth: _gameAnalysisDepth,
      );
      if (received) {
        await DailyUsageService.recordGameReview();
      }
    } catch (e) {
      // The review state itself carries the single generic failure message
      // shown in the Pippo bubble; nothing else is surfaced to the user.
      if (mounted) _analysisService.markReviewFailed();
    }
  }

  // =========================================================================
  // COMPACT VIEW INTERACTIONS
  // =========================================================================

  /// Advances to the next move of the main game PGN (variations are never
  /// part of the strip). From the root position it jumps to the first move.
  void _goToNextMainlineMove() {
    final mainline = GameReviewAnalyzer.extractMainline(_controller);
    if (mainline.isEmpty) return;
    final currentNode = _controller.currentNode;
    final index = mainline.indexWhere((n) => identical(n, currentNode));
    if (index == -1) {
      _controller.jumpToNode(mainline.first);
    } else if (index < mainline.length - 1) {
      _controller.jumpToNode(mainline[index + 1]);
    }
  }

  /// Returns from a diverged line to the exact mainline position the user
  /// diverted from, so Next can continue along the main game PGN.
  void _resumeMainline() {
    final diversion = GameReviewAnalyzer.mainlineDiversionNode(_controller);
    if (diversion != null) {
      _controller.jumpToNode(diversion);
    }
  }

  /// The Best button is enabled only when the played move on screen is NOT
  /// itself the best move and NOT a book (theory) move — i.e. whenever there
  /// is a meaningful engine alternative to show.
  bool _canShowBestMove() {
    final node = _controller.currentNode;
    if (node.isRoot) return false;
    final classification = node.classification;
    if (classification == null) return false;
    if (classification.classification == MoveClassification.best ||
        classification.classification == MoveClassification.book) {
      return false;
    }
    return _bestMoveUciFor(node) != null;
  }

  static final RegExp _uciMovePattern = RegExp(r'^[a-h][1-8][a-h][1-8]$');

  bool _isValidUciMove(String uci) => _uciMovePattern.hasMatch(uci);

  /// The engine's best move (UCI) for the position before the current move:
  /// the classification result carries it, with the cached parent analysis
  /// as fallback.
  ///
  /// The UCI is strictly validated — Stockfish answers `bestmove (none)` with
  /// the sentinel `0000` on mate-in-N replies, which must never reach the
  /// arrow painter (it would silently draw nothing).
  String? _bestMoveUciFor(MoveNode node) {
    final classification = node.classification;
    if (classification != null && _isValidUciMove(classification.bestMove)) {
      return classification.bestMove;
    }
    if (node.parent == null) return null;
    final parentAnalysis = MoveClassificationService.instance.getCachedAnalysis(
      node.parent!.fen,
    );
    if (parentAnalysis != null && _isValidUciMove(parentAnalysis.bestMoveUci)) {
      return parentAnalysis.bestMoveUci;
    }
    return null;
  }

  /// Shows / hides the yellow best-move arrow on the board.
  void _toggleBestMoveArrow() {
    if (_controller.bestMoveFrom != null) {
      _controller.setBestMoveArrow(null, null);
      return;
    }
    final node = _controller.currentNode;
    if (node.isRoot) return;
    final uci = _bestMoveUciFor(node);
    if (uci == null || uci.length < 4) return;
    _controller.setBestMoveArrow(uci.substring(0, 2), uci.substring(2, 4));
  }

  /// Runs the full-game analysis over the mainline: book moves first (no
  /// engine), then sequential engine classification at the depth chosen in
  /// the Analyze menu. The run itself is owned by the session service so it
  /// continues in the background even if the user leaves this screen.
  Future<void> _startGameAnalysis() async {
    final sanMoves = _loadedSanMoves;
    if (sanMoves == null || sanMoves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).analysisNoMoves),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (!StockfishEngineService.instance.isReady || !_isEngineEnabled) {
      await _checkAndStartEngine();
      // Bail only if the engine process genuinely failed to start. We do NOT
      // require `isReady` yet: that flag flips asynchronously once Stockfish
      // replies `readyok`, while its stdin queues commands, so the analyzer's
      // first search will run as soon as it initialises.
      if (!mounted || !_isEngineEnabled) {
        setState(() {});
        return;
      }
    }

    // Kick off the background run on the shared service. It completes even
    // when this screen is disposed (navigation away), at which point the
    // analyzed game is restored the next time Analysis is opened.
    final bool completed;
    try {
      completed = await _analysisService.startGameAnalysis(
        depth: _gameAnalysisDepth,
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Analysis failed', e.toString());
      }
      return;
    }

    // Only when the run finishes while this screen is visible do we
    // immediately surface the report and resume interactive engine analysis.
    if (!mounted) return;
    if (completed) {
      StockfishEngineService.instance.setLines(_engineLines);
      if (_controller.game.fen == _lastAnalyzedFen &&
          StockfishEngineService.instance.isReady &&
          _isEngineEnabled) {
        StockfishEngineService.instance.analyze(
          _controller.game.fen,
          depth: _engineDepth.toInt(),
        );
      }
      setState(() {});
      _showGameReportDialog();
    }
  }

  // =========================================================================
  // ANALYZE MENU
  // =========================================================================

  /// Centered Analyze menu: choose between a full-game Analysis (Stockfish
  /// classification of every move) and a Game Review (move-by-move
  /// explanations on top), plus the engine depth for the run.
  Future<void> _showAnalyzeMenuDialog() async {
    final plan = await DailyUsageService.currentPlanStatus();
    final usage = await DailyUsageService.getUsage();
    final limit = plan.isAdmin
        ? 0
        : (plan.isPro
            ? DailyUsageLimits.proGameReviews
            : DailyUsageLimits.freeGameReviews);
    final left = plan.isAdmin
        ? 0
        : (usage == null
            ? 0
            : (limit - usage.gameReviewsDone).clamp(0, limit).toInt());
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AnalyzeMenuDialog(
        reviewsLeftToday: left,
        reviewLimit: limit,
        isAdmin: plan.isAdmin,
        canReview: plan.isAdmin || left > 0,
        initialDepth: _gameAnalysisDepth,
        onDepthChanged: (depth) => _gameAnalysisDepth = depth,
        onAnalysisSelected: () {
          Navigator.pop(dialogContext);
          _startGameAnalysis();
        },
        onReviewSelected: () {
          Navigator.pop(dialogContext);
          _startGameReview();
        },
      ),
    );
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _syncState(() {
        controller.text = data!.text!;
        _importError = null;
      });
    }
  }

  Future<void> _searchUserGames(String username, String source) async {
    try {
      List<GameSummary> games;
      if (source == 'Lichess') {
        games = await GameImportService.fetchUserGamesFromLichess(username);
      } else {
        games = await GameImportService.fetchUserGamesFromChessCom(username);
      }

      if (!mounted) return;
      _syncState(() => _isLoading = false);

      if (games.isEmpty) {
        _syncState(() => _importError = 'No games found for this user.');
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GameListDialog(
          games: games,
          onGameSelected: (game) async {
            if (game.pgn != null) {
              final result = await GameImportService.importFromPgn(game.pgn!);
              _onImportSuccess(result);
            } else if (game.url != null) {
              // Fallback to URL import if PGN wasn't in summary
              GameImportResult result;
              if (source == 'Lichess') {
                result = await GameImportService.importFromLichessUrl(
                  game.url!,
                );
              } else {
                result = await GameImportService.importFromChessComUrl(
                  game.url!,
                );
              }
              _onImportSuccess(result);
            }
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _syncState(() {
        _isLoading = false;
        _importError = 'Failed to search games: $e';
      });
    }
  }

  void _showEngineSettings(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  top: 12,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSettingsHeader(Icons.memory, AppLocalizations.of(context).settingsEngineHeader),
                    const SizedBox(height: 16),
                    _buildSwitchTile(AppLocalizations.of(context).settingsEnableEngine, _isEngineEnabled, (val) {
                      _toggleEngine();
                      setSheetState(() {});
                    }, theme),
                    _buildSliderTile(
                      AppLocalizations.of(context).settingsDepth,
                      _engineDepth,
                      10,
                      30,
                      (val) => setState(() {
                        _engineDepth = val;
                        setSheetState(() {});
                        _lastAnalyzedFen = null;
                        _onBoardChanged();
                      }),
                      theme,
                    ),
                    _buildLinesSelector(theme, setSheetState),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildSettingsHeader(
                      Icons.auto_awesome,
                      AppLocalizations.of(context).settingsClassificationHeader,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      AppLocalizations.of(context).settingsEnableClassification,
                      _moveClassificationEnabled,
                      (val) => setState(() {
                        _moveClassificationEnabled = val;
                        setSheetState(() {});
                      }),
                      theme,
                    ),
                    if (_moveClassificationEnabled) ...[
                      const SizedBox(height: 8),
                      _buildClassificationList(theme, setSheetState),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildSettingsHeader(
                      Icons.warning_amber_rounded,
                      AppLocalizations.of(context).settingsThreatHeader,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      AppLocalizations.of(context).settingsThreatToggle,
                      _threatDetectorEnabled,
                      (val) => setState(() {
                        _threatDetectorEnabled = val;
                        setSheetState(() {});
                      }),
                      theme,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
      ],
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

  Widget _buildSliderTile(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              value.round().toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLinesSelector(ThemeData theme, StateSetter setSheetState) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.settingsLinesLabel,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Row(
          children: [1, 2, 3].map((lines) {
            final isSelected = _engineLines == lines;
            return GestureDetector(
              onTap: () => setState(() {
                _engineLines = lines;
                setSheetState(() {});
                // Always calculate at least two candidates: classification
                // needs the second line even when the UI only shows one.
                StockfishEngineService.instance.setLines(lines);
                _lastAnalyzedFen = null;
                _onBoardChanged();
              }),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lines.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildClassificationList(ThemeData theme, StateSetter setSheetState) {
    final keys = _classifications.keys.toList();
    final l10n = AppLocalizations.of(context);
    final visibleKeys = _classificationsExpanded
        ? keys
        : ['Book', 'Brilliant', 'Blunder'];

    return Column(
      children: [
        ...visibleKeys.map(
          (key) => _buildClassificationToggle(key, theme, setSheetState),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setSheetState(() {
            _classificationsExpanded = !_classificationsExpanded;
          }),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _classificationsExpanded ? l10n.showLess : l10n.showAll,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              Icon(
                _classificationsExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationToggle(
    String key,
    ThemeData theme,
    StateSetter setSheetState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _classificationDisplayLabel(key),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _classifications[key] ?? false,
              onChanged: (val) => setState(() {
                _classifications[key] = val;
                setSheetState(() {});
              }),
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Display label of a classification filter row in the on-screen language.
  ///
  /// [key] stays the English `MoveClassificationUI.getLabel` output on
  /// purpose: the same string is the backend-facing filter key handed to
  /// `ChessBoard.classificationFilter`.
  String _classificationDisplayLabel(String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'Best':
        return l10n.clsBest;
      case 'Brilliant':
        return l10n.clsBrilliant;
      case 'Great':
        return l10n.clsGreat;
      case 'Excellent':
        return l10n.clsExcellent;
      case 'Good':
        return l10n.clsGood;
      case 'Inaccuracy':
        return l10n.clsInaccuracy;
      case 'Mistake':
        return l10n.clsMistake;
      case 'Blunder':
        return l10n.clsBlunder;
      case 'Book':
        return l10n.clsBook;
      case 'Forced':
        return l10n.clsForced;
      case 'Miss':
        return l10n.clsMiss;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_controller.isInVariation,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // A visible best-move arrow always belongs to the shown position;
        // the first back gesture just dismisses it.
        if (_controller.bestMoveFrom != null) {
          setState(() => _controller.setBestMoveArrow(null, null));
          return;
        }

        if (_controller.isSecondOrderVariation) {
          setState(() => _controller.jumpToDiversion());
        } else if (_controller.isInVariation) {
          setState(() => _controller.undo());
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          // Tab screen: users switch via the bottom nav, so no back arrow.
          automaticallyImplyLeading: false,
          titleSpacing: 8,
          title: Text(
            AppLocalizations.of(context).analysisTitle,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            if (!_isGameLoaded)
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: AppLocalizations.of(context).addGameTooltip,
                onPressed: _showAddAnalysisSheet,
              ),
            if (_isGameLoaded)
              TextButton.icon(
                onPressed: _clearLoadedGame,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                label: Text(
                  AppLocalizations.of(context).closeGameButton,
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_isEngineLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  _isEngineEnabled
                      ? Icons.psychology
                      : Icons.psychology_outlined,
                ),
                color: !_isAnalyzing && _isEngineEnabled
                    ? AppColors.accent
                    : theme.colorScheme.onSurface.withValues(
                        alpha: !_isAnalyzing ? 0.5 : 0.2,
                      ),
                onPressed: _isAnalyzing ? null : _toggleEngine,
              ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: _isAnalyzing ? 0.2 : 1,
                ),
              ),
              onPressed: _isAnalyzing
                  ? null
                  : () => _showEngineSettings(context),
            ),
          ],
        ),
        // The compact view only exists for games with analysis/review
        // results — fall back to the full view otherwise (e.g. the game was
        // reset while the compact view was open).
        body: _isCompactView && _compactViewAvailable
            ? _buildCompactBody(theme)
            : _buildFullBody(theme),
        bottomNavigationBar: const AppBottomNav(active: AppTab.analysis),
      ),
    );
  }

  /// The classic full analysis view: engine panel, board, navigation
  /// controls, tabs and report — unchanged except the move classification
  /// text now lives in the Pippo bubble above the board.
  Widget _buildFullBody(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineBanner(),
          const SizedBox(height: 10),
          const SizedBox(height: 12),
          EngineAnalysisPanel(
            controller: _controller,
            engineEnabled: _isEngineEnabled,
            lines: _engineLines,
          ),
          const SizedBox(height: 12),
          // Pippo (logo + speech bubble) carries the move classification
          // text — and, once a Game Review is ready, the coach's
          // explanation for the move on screen. The up arrow compacts
          // the screen down to the board-centric view.
          _buildPippoBubbleRow(theme, compact: false),
          IgnorePointer(
            ignoring: _isAnalyzing,
            child: ChessBoard(
              controller: _controller,
              settings: _settings,
              onSettingsChanged: (newSettings) {
                setState(() => _settings = newSettings);
              },
              classificationEnabled: _moveClassificationEnabled,
              threatDetectorEnabled: _threatDetectorEnabled,
              classificationFilter: {
                for (final e in _classifications.entries)
                  if (e.value) e.key,
              },
            ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildAnalysisControls(theme),
          ),
          if (_isGameLoaded) ...[
            const SizedBox(height: 12),
            // Rebuild this block whenever the session analysis state
            // changes (start, progress, cancel, completion) so the banner
            // and the Cancel/progress control appear the instant the user
            // taps Analyze — including for runs finishing in the background.
            ListenableBuilder(
              listenable: _analysisService,
              builder: (context, _) => _buildSessionRunUi(theme),
            ),
          ],
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              children: [
                _buildGameTabs(theme),
                const SizedBox(height: 12),
                _buildTabContent(theme),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnalyzingBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sync_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              AppLocalizations.of(context).analyzingBanner,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.3,
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisControls(ThemeData theme) {
    // Full freeze while the game analysis runs: navigation stays inert.
    if (_isAnalyzing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(Icons.first_page, null, theme),
            _controlButton(Icons.chevron_left, null, theme),
            _controlButton(Icons.restart_alt, null, theme),
            _controlButton(Icons.sync, null, theme),
            _controlButton(Icons.chevron_right, null, theme),
            _controlButton(Icons.last_page, null, theme),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            Icons.first_page,
            _controller.canUndo ? () => _controller.goToStart() : null,
            theme,
          ),
          _controlButton(
            Icons.chevron_left,
            _controller.canUndo ? () => _controller.undo() : null,
            theme,
          ),
          _controlButton(
            Icons.restart_alt,
            () => setState(() {
              _controller.reset();
              MoveClassificationService.instance.clearCache();
            }),
            theme,
          ),
          _controlButton(Icons.sync, _flipBoard, theme),
          _controlButton(
            Icons.chevron_right,
            _controller.canRedo ? () => _controller.redo() : null,
            theme,
          ),
          _controlButton(
            Icons.last_page,
            _controller.canRedo ? () => _controller.goToEnd() : null,
            theme,
          ),
        ],
      ),
    );
  }

  /// The compact, board-centric view: Pippo (logo + speech bubble) above the
  /// board, the board big in the middle, the main game PGN with Next / Best
  /// (or Resume) underneath and a plain down arrow back to the full view.
  Widget _buildCompactBody(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildPippoBubbleRow(theme, compact: true),
          Expanded(
            child: Center(
              // The board widget is aspect-ratio driven off its WIDTH, so when
              // the remaining height is smaller than the width (long
              // explanation, PGN strip, etc.) it would overflow. Constrain it
              // to a square of the SMALLER dimension instead.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double side =
                      constraints.maxHeight.isFinite &&
                          constraints.maxHeight < constraints.maxWidth
                      ? constraints.maxHeight
                      : constraints.maxWidth;
                  return SizedBox(
                    width: side,
                    height: side,
                    child: IgnorePointer(
                      ignoring: _isAnalyzing,
                      child: ChessBoard(
                        controller: _controller,
                        settings: _settings,
                        onSettingsChanged: (newSettings) {
                          setState(() => _settings = newSettings);
                        },
                        showSettingsButton: false,
                        classificationEnabled: _moveClassificationEnabled,
                        threatDetectorEnabled: _threatDetectorEnabled,
                        classificationFilter: {
                          for (final e in _classifications.entries)
                            if (e.value) e.key,
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Review run UI: the shimmer waiting text for the whole review.
          ListenableBuilder(
            listenable: _analysisService,
            builder: (context, _) => _buildSessionRunUi(theme),
          ),
          // Main game PGN (mainline only — never branches) + Next / Best /
          // Resume.
          _buildCompactPgnRow(theme),
          // Plain down arrow back to the full view. No special styling.
          IconButton(
            tooltip: AppLocalizations.of(context).fullViewTooltip,
            onPressed: () => setState(() => _isCompactView = false),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Pippo's logo on the left with a speech bubble on the right. In the full
  /// view an up arrow on the end compacts the screen.
  ///
  /// The row listens to BOTH the board controller (navigation / move plays
  /// change which explanation applies) and the session service (review phase
  /// changes and arriving explanations), so the bubble always reflects the
  /// position currently on the board. Coach explanations get a FIXED
  /// 3-line-high bubble that scrolls inside (with a small down-arrow hint);
  /// every other text keeps its natural size.
  Widget _buildPippoBubbleRow(ThemeData theme, {required bool compact}) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _analysisService]),
      builder: (context, _) {
        final content = _pippoBubbleContent();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PippoChatBubble(
                  message: content.$1,
                  // ~3 visible lines (13px font, 1.3 height, 3 lines of text).
                  fixedHeight: content.$2 ? 51.0 : null,
                ),
              ),
              if (!compact && _compactViewAvailable)
                IconButton(
                  tooltip: AppLocalizations.of(context).compactViewTooltip,
                  onPressed: () => setState(() => _isCompactView = true),
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 26,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                    maxWidth: 36,
                    maxHeight: 36,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The text Pippo is currently saying, plus whether it is a coach
  /// explanation (which gets the fixed 3-line scrollable bubble).
  ///
  /// - With a finished Game Review and the board on a mainline move: the
  ///   coach explanation for that move (with the engine's best alternative
  ///   appended for bad moves — also in the compact review view).
  /// - Otherwise: the interactive move classification text ("Nxe5 is a
  ///   blunder, f3 was the best move"), which also covers moves played on
  ///   diverged lines.
  /// - `null` text hides the bubble (Pippo's logo still stays visible).
  (String?, bool) _pippoBubbleContent() {
    final node = _controller.currentNode;
    final phase = _analysisService.reviewPhase;

    if (phase == GameReviewPhase.awaitingCoach) {
      // The dedicated waiting state carries the message.
      return (null, false);
    }
    if (phase == GameReviewPhase.failed && !_reviewFailureDismissed) {
      // The failure is only worth showing while the user is still where it
      // happened; once they start analyzing again the stale error is dropped
      // and the code below produces the usual move commentary instead.
      return ('Server Error, Please try again later', false);
    }

    // Coach explanation for the current mainline move. For moves that are
    // NOT one of the clean categories (best / book / brilliant / great) the
    // engine's best alternative is appended — in the full view AND the
    // compact review view alike.
    if (phase == GameReviewPhase.ready &&
        GameReviewAnalyzer.isOnMainline(_controller)) {
      final mainline = GameReviewAnalyzer.extractMainline(_controller);
      final index = mainline.indexWhere((n) => identical(n, node));
      if (index != -1 &&
          index < _analysisService.reviewExplanations.length &&
          _analysisService.reviewExplanations[index].isNotEmpty) {
        return (
          _withBestMoveHint(node, _analysisService.reviewExplanations[index]),
          true,
        );
      }
      // No explanation for this move — fall through to the classification.
    }

    if (!_moveClassificationEnabled) return (null, false);
    if (node.isPendingClassification) {
      return (AppLocalizations.of(context).classifyingMove, false);
    }

    final classification = node.classification;
    if (classification == null || node.isRoot) return (null, false);

    return (_classificationSentence(node), false);
  }

  // ---------------------------------------------------------------------------
  // Classification sentence building (Pippo bubble).
  // ---------------------------------------------------------------------------

  /// The categories that already ARE the answer — for these the engine's
  /// best alternative is never mentioned.
  static const Set<MoveClassification> _selfExplanatoryClassifications = {
    MoveClassification.best,
    MoveClassification.book,
    MoveClassification.brilliant,
    MoveClassification.great,
  };

  /// Grammar-correct classification sentence for the current move, e.g.
  /// "Qxc7 is a blunder", "e4 is a book move", "Qxc7 is the best move".
  ///
  /// For moves outside [_selfExplanatoryClassifications] the engine's best
  /// alternative is appended when known: "Qxc7 is a blunder, f3 was the
  /// best move."
  String _classificationSentence(MoveNode node) {
    final type = node.classification!.classification;
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer(
      l10n.classificationSentence(node.san, _classificationPhrase(type)),
    );
    if (!_selfExplanatoryClassifications.contains(type)) {
      final bestSan = _bestMoveSanFor(node);
      if (bestSan != null) {
        buffer.write(l10n.sentenceBestSuffix(bestSan));
      }
    }
    buffer.write('.');
    return buffer.toString();
  }

  /// Article-correct phrase for a classification, e.g. "the best move",
  /// "a blunder", "an excellent move".
  String _classificationPhrase(MoveClassification type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case MoveClassification.best:
        return l10n.phraseBest;
      case MoveClassification.brilliant:
        return l10n.phraseBrilliant;
      case MoveClassification.great:
        return l10n.phraseGreat;
      case MoveClassification.excellent:
        return l10n.phraseExcellent;
      case MoveClassification.good:
        return l10n.phraseGood;
      case MoveClassification.inaccuracy:
        return l10n.phraseInaccuracy;
      case MoveClassification.mistake:
        return l10n.phraseMistake;
      case MoveClassification.blunder:
        return l10n.phraseBlunder;
      case MoveClassification.miss:
        return l10n.phraseMiss;
      case MoveClassification.book:
        return l10n.phraseBook;
      case MoveClassification.forced:
        return l10n.phraseForced;
    }
  }

  /// Appends "f3 was the best move." to a coach explanation for moves that
  /// are not one of the clean categories — unless the explanation already
  /// mentions the best move itself.
  String _withBestMoveHint(MoveNode node, String explanation) {
    final type = node.classification?.classification;
    if (type == null || _selfExplanatoryClassifications.contains(type)) {
      return explanation;
    }
    final bestSan = _bestMoveSanFor(node);
    if (bestSan == null) return explanation;
    final alreadyMentions = RegExp(
      '\\b${RegExp.escape(bestSan)}\\b',
      caseSensitive: false,
    ).hasMatch(explanation);
    if (alreadyMentions) return explanation;
    return AppLocalizations.of(context).reviewBestHint(explanation, bestSan);
  }

  /// The engine's best move for the position BEFORE [node]'s move, as SAN
  /// (the classification's best move is UCI, resolved against the parent
  /// position). Returns `null` when it cannot be determined.
  String? _bestMoveSanFor(MoveNode node) {
    final uci = _bestMoveUciFor(node);
    if (uci == null || node.parent == null) return null;
    try {
      final board = chess.Chess.fromFEN(node.parent!.fen);
      final from = uci.substring(0, 2);
      final to = uci.substring(2, 4);
      final promotion = uci.length > 4 ? uci.substring(4, 5) : null;
      for (final m in board.generate_moves()) {
        if (m.fromAlgebraic == from &&
            m.toAlgebraic == to &&
            (m.promotion == null || m.promotion!.name == promotion)) {
          return board.move_to_san(m);
        }
      }
    } catch (_) {
      // Malformed data — the hint is simply omitted.
    }
    return null;
  }

  /// What the session shows while a full-game analysis or Game Review runs:
  ///
  /// - Plain analysis: the banner + percentage-ring widgets, driven by the
  ///   session state.
  /// - Game Review (any in-flight step): the shimmer waiting text from the
  ///   very start — no percentage ring.
  /// - Review failure: the normal action row with a Retry entry (the error
  ///   itself is shown in the Pippo bubble).
  Widget _buildSessionRunUi(ThemeData theme) {
    switch (_analysisService.reviewPhase) {
      case GameReviewPhase.classifying:
      case GameReviewPhase.awaitingCoach:
        return _buildReviewWaiting(theme);
      case GameReviewPhase.failed:
        return Column(
          children: [
            _buildGameAnalysisAction(theme),
            TextButton.icon(
              onPressed: _startGameReview,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                AppLocalizations.of(context).retryReview,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            if (_isAnalyzing) _buildAnalyzingBanner(theme),
            _buildGameAnalysisAction(theme),
          ],
        );
    }
  }

  /// Game Review in flight: a single modern waiting line with a white shimmer
  /// sweep passing through the text, shown for the WHOLE review (from the
  /// moment it starts until it completes) — no percentage ring.
  Widget _buildReviewWaiting(ThemeData theme) {
    final baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              final shift = -2.0 + 4.0 * _shimmerController.value;
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [baseColor, Colors.white, baseColor],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(shift - 1, 0),
                  end: Alignment(shift + 1, 0),
                ).createShader(bounds),
                child: child,
              );
            },
            child: Text(
              AppLocalizations.of(context).reviewWaiting,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancelRunningReview,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context).cancelButton,
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The compact bottom strip: a single-line, mainline-only PGN of the game
  /// (no branches, unlike the Moves tab) with the Next button — replaced by
  /// Resume whenever the board sits on a diverged line — and the Best button
  /// that draws the yellow best-move arrow.
  Widget _buildCompactPgnRow(ThemeData theme) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final mainline = GameReviewAnalyzer.extractMainline(_controller);
        final currentNode = _controller.currentNode;
        final offMainline = !GameReviewAnalyzer.isOnMainline(_controller);
        final diversion = offMainline
            ? GameReviewAnalyzer.mainlineDiversionNode(_controller)
            : null;
        final currentIndex = mainline.indexWhere(
          (n) => identical(n, currentNode),
        );

        // Next is enabled when there is a mainline move ahead of the board
        // (from the root position it jumps to the first move).
        final bool canGoNext =
            !offMainline &&
            mainline.isNotEmpty &&
            (currentIndex == -1 || currentIndex < mainline.length - 1);
        final bool canShowBest = _canShowBestMove();

        // Keep the current move visible in the strip.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pgnScrollController.hasClients) return;
          if (mainline.isEmpty || currentIndex < 0) return;
          final clamped = currentIndex.clamp(0, mainline.length - 1);
          final keyContext = _pgnChipKeys[clamped]?.currentContext;
          if (keyContext != null) {
            Scrollable.ensureVisible(
              keyContext,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: 0.5,
            );
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: mainline.isEmpty
                  ? Text(
                      AppLocalizations.of(context).pgnEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _pgnScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < mainline.length; i++)
                            _buildPgnChip(
                              mainline[i],
                              i,
                              identical(mainline[i], currentNode),
                              theme,
                            ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  // Previous move — the exact chevron the board controls use.
                  _controlButton(
                    Icons.chevron_left,
                    _controller.canUndo ? _controller.undo : null,
                    theme,
                  ),
                  if (offMainline && diversion != null)
                    _compactActionButton(
                      theme,
                      label: AppLocalizations.of(context).pgnResume,
                      icon: Icons.replay_rounded,
                      onTap: _resumeMainline,
                    )
                  else
                    // Next move — same board-control chevron, mainline only.
                    _controlButton(
                      Icons.chevron_right,
                      canGoNext ? _goToNextMainlineMove : null,
                      theme,
                    ),
                  const Spacer(),
                  // Best move: an outline magnifying glass with the Best
                  // star inside its lens, drawn fully in code — grayish
                  // (not the brand amber) and dimmed when disabled.
                  IconButton(
                    tooltip: AppLocalizations.of(context).showBestTooltip,
                    onPressed: canShowBest ? _toggleBestMoveArrow : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                      maxWidth: 40,
                      maxHeight: 40,
                    ),
                    icon: _BestSearchGlyph(
                      size: 28,
                      color: canShowBest
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// One tappable move in the compact PGN strip. White moves carry their
  /// move number; the move on screen is highlighted. Keys are cached per
  /// tree version so the strip can scroll the current move into view.
  Widget _buildPgnChip(
    MoveNode node,
    int index,
    bool selected,
    ThemeData theme,
  ) {
    if (_pgnChipKeysVersion != _controller.treeVersion) {
      _pgnChipKeys.clear();
      _pgnChipKeysVersion = _controller.treeVersion;
    }
    final key = _pgnChipKeys.putIfAbsent(index, GlobalKey.new);

    final isWhiteMove = index.isEven;
    final moveNumber = (index ~/ 2) + 1;
    final label = isWhiteMove ? '$moveNumber. ${node.san}' : node.san;

    return GestureDetector(
      key: key,
      onTap: () => _controller.jumpToNode(node),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  /// Small pill button used in the compact strip (Next / Resume / Best).
  ///
  /// [iconOverride] replaces the default [Icon] — e.g. the desaturated
  /// Best-move classification glyph on the Best button.
  Widget _compactActionButton(
    ThemeData theme, {
    required String label,
    IconData? icon,
    Widget? iconOverride,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final bool enabled = onTap != null;
    final Color accent = color ?? AppColors.primary;
    final Widget leading =
        iconOverride ??
        Icon(
          icon ?? Icons.chevron_right_rounded,
          size: 18,
          color: enabled
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.25),
        );
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: enabled ? accent : null,
        backgroundColor: enabled ? accent.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: leading,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: enabled
              ? accent
              : theme.colorScheme.onSurface.withValues(alpha: 0.25),
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

  Widget _buildGameTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              theme,
              label: AppLocalizations.of(context).tabMoves,
              icon: Icons.menu_book,
              index: 0,
            ),
          ),
          Container(width: 1, height: 24, color: theme.dividerColor),
          Expanded(
            child: _buildTabButton(
              theme,
              label: AppLocalizations.of(context).tabExplorer,
              icon: Icons.explore_rounded,
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
          // Fetch fresh opening data when switching to the Explorer tab: the
          // per-move fetch is gated to this tab, so the data must be pulled
          // here for the current position.
          if (index == 1) {
            _explorerFuture = OpeningExplorerService.fetchOpeningData(
              _controller.game.fen,
              database: _explorerDb,
              speeds: _explorerSpeeds.toList(),
              ratings: _explorerRatings.toList(),
            );
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    if (_selectedTab == 0) {
      return _buildMovesTab(theme);
    }
    return _buildExplorerTab(theme);
  }

  Widget _buildMovesTab(ThemeData theme) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).moveTreeHeader,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (_isClassifying)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_loadedHeaders != null)
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
                    _loadedHeaders!['Result'] ?? '*',
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
            height: 310,
            child: _controller.root.children.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).moveTreeEmpty,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: _getCachedMoves(theme),
                  ),
          ),
        ],
      ),
    );
  }

  /// Returns the moves list from the structure-versioned cache. Rebuilds the
  /// list only when the tree shape changes (a move is added / game loaded or
  /// reset). Individual rows are self-updating [ListenableBuilder]s, so
  /// navigation and classification updates re-render only the affected rows
  /// instead of re-walking the entire tree on every controller notification.
  List<Widget> _getCachedMoves(ThemeData theme) {
    final version = _controller.treeVersion;
    if (_movesTreeCache == null ||
        _movesTreeCacheVersion != version ||
        _movesTreeCacheBrightness != theme.brightness) {
      _movesTreeCache = _buildCompactMoves(_controller.root, 0, theme);
      _movesTreeCacheVersion = version;
      _movesTreeCacheBrightness = theme.brightness;
    }
    return _movesTreeCache!;
  }

  /// Preferred line uses one row per full move. Immediate alternatives stay
  /// directly underneath their parent row; deeper alternatives are summarized
  /// in brackets so nested analysis remains compact.
  List<Widget> _buildCompactMoves(
    MoveNode parent,
    int completedPlies,
    ThemeData theme,
  ) {
    if (parent.children.isEmpty) return [];
    final white = parent.children.first;
    final black = white.children.isEmpty ? null : white.children.first;
    final widgets = <Widget>[
      _buildMovePairRow(white, black, completedPlies + 1, theme),
    ];

    for (final variation in [
      ...parent.children.skip(1),
      ...white.children.skip(1),
    ]) {
      final startPly = identical(variation.parent, parent)
          ? completedPlies + 1
          : completedPlies + 2;
      widgets.add(_buildVariationRow(variation, startPly, theme));
    }
    if (black != null) {
      widgets.addAll(_buildCompactMoves(black, completedPlies + 2, theme));
    }
    return widgets;
  }

  Widget _buildMovePairRow(
    MoveNode white,
    MoveNode? black,
    int whitePly,
    ThemeData theme,
  ) {
    // Row-local listener: only the rows whose selection/classification state
    // actually changed rebuild, instead of the whole moves list, on notify.
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final whiteSelected = identical(_controller.currentNode, white);
          final blackSelected =
              black != null && identical(_controller.currentNode, black);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (whiteSelected || blackSelected)
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${((whitePly + 1) ~/ 2)}.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildMoveTap(white, theme, whiteSelected)),
                const SizedBox(width: 12),
                Expanded(
                  child: black == null
                      ? const SizedBox.shrink()
                      : _buildMoveTap(black, theme, blackSelected),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoveTap(MoveNode node, ThemeData theme, bool selected) {
    final asset = node.classification == null
        ? null
        : MoveClassificationUI.getAssetName(
            node.classification!.classification,
          );
    return InkWell(
      onTap: () => _controller.jumpToNode(node),
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Flexible(
              child: Text(
                node.san,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (asset != null) ...[
              const SizedBox(width: 4),
              Image.asset(
                asset,
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

  Widget _buildVariationRow(
    MoveNode variation,
    int startingPly,
    ThemeData theme,
  ) {
    // Row-local listener so branch highlight updates don't rebuild the list.
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final selected = _isInBranch(variation, _controller.currentNode);
          return InkWell(
            onTap: () => _controller.jumpToNode(variation),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.11)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _variationSummary(variation, startingPly),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isInBranch(MoveNode branchStart, MoveNode current) {
    MoveNode? node = current;
    while (node != null) {
      if (identical(node, branchStart)) return true;
      node = node.parent;
    }
    return false;
  }

  String _variationSummary(
    MoveNode start,
    int startingPly, {
    int remaining = 6,
  }) {
    final buffer = StringBuffer(_plyLabel(startingPly));
    MoveNode? node = start;
    var ply = startingPly;
    while (node != null && remaining-- > 0) {
      buffer.write(' ${node.san}');
      final alternatives = node.children.skip(1).toList();
      if (alternatives.isNotEmpty) {
        final nested = alternatives
            .map((item) => _variationSummary(item, ply + 1, remaining: 2))
            .join(' / ');
        buffer.write(' [$nested]');
      }
      node = node.children.isEmpty ? null : node.children.first;
      ply++;
    }
    return buffer.toString();
  }

  String _plyLabel(int ply) =>
      ply.isOdd ? '${((ply + 1) ~/ 2)}.' : '${(ply ~/ 2)}...';

  Widget _buildGameAnalysisAction(ThemeData theme) {
    final progress = _analysisProgress;
    final isAnalyzing = _isAnalyzing;

    // Percentage done, used to drive the circular progress ring while the
    // full-game analysis is running.
    final double? percent = (isAnalyzing && progress != null && progress.$2 > 0)
        ? (progress.$1 / progress.$2).clamp(0.0, 1.0)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isAnalyzing)
            // While analyzing, the title is replaced by a tap-to-cancel button
            // that stops the run and wipes any classifications produced so far.
            TextButton.icon(
              onPressed: _cancelRunningAnalysis,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.error,
              ),
              label: Text(
                AppLocalizations.of(context).cancelButton,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            )
          else if (_isGameAnalyzed) ...[
            // Game already analyzed / reviewed: no Analyze entry point anymore
            // — the report is the only action here.
            TextButton.icon(
              onPressed: _showGameReportDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.analytics_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              label: Text(
                AppLocalizations.of(context).gameReportButton,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ] else
            Text(
              AppLocalizations.of(context).gameAnalysisTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          const Spacer(),
          if (isAnalyzing)
            // Play-Store-style circular ring that fills in with the percent
            // of moves classified so far, instead of an "m/n" counter.
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 3.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.12,
                      ),
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${((percent ?? 0) * 100).round()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!_isGameAnalyzed) ...[
            TextButton(
              onPressed: _showAnalyzeMenuDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context).analyzeButton,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: AppLocalizations.of(context).viewReportTooltip,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).noReportYet),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: AppColors.textPrimaryOf(context),
                  ),
                );
              },
              icon: Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
                maxWidth: 32,
                maxHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplorerTab(ThemeData theme) {
    return AtlasCard(
      child: FutureBuilder<OpeningExplorerResult?>(
        future: _explorerFuture,
        builder: (context, snapshot) {
          final isPending = snapshot.connectionState == ConnectionState.waiting;
          final hasError =
              snapshot.hasError ||
              (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data == null);
          return OpeningExplorerView(
            data: snapshot.data,
            database: _explorerDb,
            isLoading: isPending,
            hasError: hasError,
            isSignedIn: LichessAuthService.instance.isSignedIn,
            onSignIn: _handleExplorerSignIn,
            selectedSpeeds: _explorerSpeeds,
            selectedRatings: _explorerRatings,
            onRetry: () {
              setState(() {
                _explorerFuture = OpeningExplorerService.fetchOpeningData(
                  _controller.game.fen,
                  database: _explorerDb,
                  speeds: _explorerSpeeds.toList(),
                  ratings: _explorerRatings.toList(),
                );
              });
            },
            onSpeedsChanged: (speeds) {
              setState(() {
                _explorerSpeeds = speeds;
                _explorerFuture = OpeningExplorerService.fetchOpeningData(
                  _controller.game.fen,
                  database: _explorerDb,
                  speeds: _explorerSpeeds.toList(),
                  ratings: _explorerRatings.toList(),
                );
              });
            },
            onRatingsChanged: (ratings) {
              setState(() {
                _explorerRatings = ratings;
                _explorerFuture = OpeningExplorerService.fetchOpeningData(
                  _controller.game.fen,
                  database: _explorerDb,
                  speeds: _explorerSpeeds.toList(),
                  ratings: _explorerRatings.toList(),
                );
              });
            },
            onMoveSelected: (san) {
              if (_controller.makeMoveFromSan(san)) {
                setState(() {});
              }
            },
            onGameSelected: _handleExplorerGameSelected,
            onDatabaseChanged: (newDb) {
              setState(() {
                _explorerDb = newDb;
                _explorerFuture = OpeningExplorerService.fetchOpeningData(
                  _controller.game.fen,
                  database: _explorerDb,
                  speeds: _explorerSpeeds.toList(),
                  ratings: _explorerRatings.toList(),
                );
              });
            },
          );
        },
      ),
    );
  }

  void _showAddAnalysisSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSetState) {
          _sheetSetter = sheetSetState;
          final theme = Theme.of(context);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).addToAnalysisTitle,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context).addToAnalysisSubtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Import + FEN switch the in-sheet panel, so they
                        // share one segmented control.
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'Game',
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(AppLocalizations.of(context).importSegment),
                              ),
                              ButtonSegment(
                                value: 'FEN',
                                icon: const Icon(Icons.data_object_rounded),
                                label: Text(AppLocalizations.of(context).fenSegment),
                              ),
                            ],
                            selected: {_activeImportSection},
                            onSelectionChanged: (value) {
                              _syncState(() {
                                _activeImportSection = value.first;
                                _importError = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Setup opens a full-screen editor (a navigation, not
                        // an in-sheet panel), so it sits apart on the right
                        // with its own styling.
                        _buildSetupSegmentButton(theme),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_activeImportSection == 'Game')
                      _buildPlatformImportForm(theme)
                    else
                      _buildFenImportForm(theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _sheetSetter = null);
  }

  /// Closes the add sheet and pushes the dedicated full-screen board setup.
  /// The analysis screen stays in the stack beneath, so Cancel simply pops
  /// back to the exact same state (loaded game, move tree, tabs, etc.).
  void _openBoardSetup() {
    Navigator.of(context, rootNavigator: true).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute<void>(builder: (_) => const BoardSetupScreen()));
    });
  }

  /// The separated "Setup" entry of the add-sheet: sits to the right of the
  /// Import/FEN segmented control with its own outlined style, because it
  /// navigates to the board editor instead of switching the in-sheet panel.
  Widget _buildSetupSegmentButton(ThemeData theme) {
    return InkWell(
      onTap: _openBoardSetup,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor, width: 1.5),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).setupButton,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // GAME REPORT DIALOG
  // =========================================================================

  // Classification categories shown in the Chess.com-style report.
  static const List<MoveClassification> _reportCategories = [
    MoveClassification.brilliant,
    MoveClassification.great,
    MoveClassification.best,
    MoveClassification.excellent,
    MoveClassification.good,
    MoveClassification.inaccuracy,
    MoveClassification.mistake,
    MoveClassification.blunder,
    MoveClassification.book,
  ];

  // Width reserved for the icon column between the two players' counts.
  static const double _iconColumnWidth = 40;

  Map<MoveClassification, Map<chess.Color, int>>
  _countClassificationsByPlayer() {
    final counts = <MoveClassification, Map<chess.Color, int>>{};
    void walk(MoveNode node) {
      final c = node.classification;
      if (c != null && node.move != null) {
        final byColor = counts.putIfAbsent(c.classification, () => {});
        final color = node.move!.color;
        byColor[color] = (byColor[color] ?? 0) + 1;
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    walk(_controller.root);
    return counts;
  }

  void _showGameReportDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        String playerName(String key, String fallback) {
          final value = _loadedHeaders?[key]?.trim();
          return value != null && value.isNotEmpty ? value : fallback;
        }

        final whiteName = playerName(
          'White',
          AppLocalizations.of(dialogContext).sideWhite,
        );
        final blackName = playerName(
          'Black',
          AppLocalizations.of(dialogContext).sideBlack,
        );
        final counts = _countClassificationsByPlayer();

        final accuracies = _analysisService.computeGameAccuracy();
        final whiteAccuracy = accuracies?['white'];
        final blackAccuracy = accuracies?['black'];

        final bool hasAccuracy = whiteAccuracy != null && blackAccuracy != null;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(dialogContext).gameReportTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildAccuraciesSection(
                        theme,
                        whiteName,
                        blackName,
                        hasAccuracy: hasAccuracy,
                        whiteAccuracy: whiteAccuracy,
                        blackAccuracy: blackAccuracy,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildPlayerHeaderRow(theme, whiteName, blackName),
                      const SizedBox(height: 8),
                      ..._reportCategories.map(
                        (c) => _buildClassificationRow(
                          theme,
                          c,
                          counts[c] ?? const {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccuraciesSection(
    ThemeData theme,
    String whiteName,
    String blackName, {
    required bool hasAccuracy,
    required double? whiteAccuracy,
    required double? blackAccuracy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context).accuraciesHeader,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAccuracyBox(
                theme,
                playerName: whiteName,
                isWhite: true,
                accuracy: whiteAccuracy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccuracyBox(
                theme,
                playerName: blackName,
                isWhite: false,
                accuracy: blackAccuracy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasAccuracy)
          Center(
            child: Text(
              AppLocalizations.of(context).accuracyRerunHint,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccuracyBox(
    ThemeData theme, {
    required String playerName,
    required bool isWhite,
    required double? accuracy,
  }) {
    final background = isWhite ? Colors.white : const Color(0xFF161616);
    final foreground = isWhite ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWhite
              ? theme.dividerColor.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            playerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            accuracy != null ? accuracy.toStringAsFixed(1) : '—',
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeaderRow(
    ThemeData theme,
    String whiteName,
    String blackName,
  ) {
    return Row(
      children: [
        const Expanded(flex: 3, child: SizedBox.shrink()),
        Expanded(
          flex: 2,
          child: Text(
            whiteName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        SizedBox(width: _iconColumnWidth),
        Expanded(
          flex: 2,
          child: Text(
            blackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationRow(
    ThemeData theme,
    MoveClassification classification,
    Map<chess.Color, int> counts,
  ) {
    final label = _classificationDisplayLabel(
      MoveClassificationUI.getLabel(classification),
    );
    final color = MoveClassificationUI.getColor(classification);
    final asset = MoveClassificationUI.getAssetName(classification);
    final whiteCount = counts[chess.Color.WHITE] ?? 0;
    final blackCount = counts[chess.Color.BLACK] ?? 0;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Image.asset(
                    asset,
                    width: 20,
                    height: 20,
                    package: MoveClassificationUI.package,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$whiteCount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: _iconColumnWidth,
              child: Center(
                child: Image.asset(
                  asset,
                  width: 18,
                  height: 18,
                  package: MoveClassificationUI.package,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$blackCount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformImportForm(ThemeData theme) {
    return Column(
      key: const ValueKey('platform_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildModernSourceItem('Lichess', Icons.public_rounded, theme),
              const SizedBox(width: 12),
              _buildModernSourceItem(
                'Chess.com',
                Icons.grid_view_rounded,
                theme,
              ),
              const SizedBox(width: 12),
              _buildModernSourceItem('PGN', Icons.description_outlined, theme),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AtlasTextField(
          controller: _importController,
          label: _getInputLabel(),
          hint: _getInputHint(),
          errorText: _importError,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildPlatformIcon(
              _activeImportSource,
              _getIconForSource(_activeImportSource),
              size: 22,
            ),
          ),
          suffixIcon: _activeImportSource == 'PGN'
              ? IconButton(
                  icon: const Icon(
                    Icons.paste_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _pasteFromClipboard(_importController),
                  tooltip: AppLocalizations.of(context).pastePgnTooltip,
                )
              : null,
          onChanged: (_) => _syncState(() => _importError = null),
        ),
        if (_activeImportSource == 'PGN') ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _pasteFromClipboard(_importController),
            icon: const Icon(Icons.content_paste_go_rounded, size: 16),
            label: Text(
              AppLocalizations.of(context).pastePgnButton,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
        const SizedBox(height: 16),
        AtlasButton(
          label: _isLoading
              ? (_activeImportSource != 'PGN'
                  ? AppLocalizations.of(context).searchingLabel
                  : AppLocalizations.of(context).importingLabel)
              : (_activeImportSource != 'PGN'
                  ? AppLocalizations.of(context).searchGamesButton
                  : AppLocalizations.of(context).startAnalysisButton),
          onPressed: _isLoading ? null : _importGame,
          isLoading: _isLoading,
          icon: _activeImportSource != 'PGN'
              ? Icons.search_rounded
              : Icons.rocket_launch_rounded,
        ),
      ],
    );
  }

  Widget _buildFenImportForm(ThemeData theme) {
    return Column(
      key: const ValueKey('fen_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtlasTextField(
          controller: _fenController,
          label: AppLocalizations.of(context).fenFieldLabel,
          hint: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          errorText: _importError,
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.reorder_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.paste_rounded, color: AppColors.primary),
            onPressed: () => _pasteFromClipboard(_fenController),
            tooltip: AppLocalizations.of(context).pasteFenTooltip,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _pasteFromClipboard(_fenController),
          icon: const Icon(Icons.content_paste_go_rounded, size: 16),
          label: Text(
            AppLocalizations.of(context).pasteFenButton,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 16),
        AtlasButton(
          label: AppLocalizations.of(context).loadPositionButton,
          onPressed: _importFen,
          icon: Icons.refresh_rounded,
        ),
      ],
    );
  }

  Widget _buildModernSourceItem(String label, IconData icon, ThemeData theme) {
    final isActive = _activeImportSource == label;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _syncState(() {
        _activeImportSource = label;
        _importController.clear();
        _importError = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark
                    ? AppColors.surfaceSubtleDark
                    : AppColors.surfaceSubtle),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlatformIcon(
              label,
              icon,
              size: 20,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            // Lichess and Chess.com are recognizable by their logos alone —
            // show the logo without the website name. PGN (no logo) keeps
            // its text label.
            if (label == 'PGN') ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformIcon(
    String label,
    IconData fallbackIcon, {
    required double size,
    Color? color,
  }) {
    String? assetPath;
    if (label == 'Lichess') {
      assetPath = 'assets/logos/lichess.svg';
    } else if (label == 'Chess.com') {
      assetPath = 'assets/logos/chesscom.svg';
    }

    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath,
        package: 'atlas_ui',
        width: size,
        height: size,
        placeholderBuilder: (_) =>
            Icon(fallbackIcon, size: size, color: color ?? AppColors.primary),
      );
    }

    return Icon(fallbackIcon, size: size, color: color ?? AppColors.primary);
  }

  IconData _getIconForSource(String source) {
    switch (source) {
      case 'PGN':
        return Icons.description_outlined;
      case 'Lichess':
        return Icons.public_rounded;
      case 'Chess.com':
        return Icons.grid_view_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _getInputLabel() {
    final l10n = AppLocalizations.of(context);
    switch (_activeImportSource) {
      case 'PGN':
        return l10n.inputPgnText;
      case 'Lichess':
      case 'Chess.com':
        return l10n.inputUsername;
      default:
        return l10n.inputGameUrl;
    }
  }

  String _getInputHint() {
    final l10n = AppLocalizations.of(context);
    switch (_activeImportSource) {
      case 'PGN':
        return l10n.hintPastePgn;
      case 'Lichess':
      case 'Chess.com':
        return l10n.hintEnterUsername;
      default:
        return '';
    }
  }
}

/// An outline magnifying glass with the Best-move star inside its lens —
/// the compact view's "show me the best move" control.
///
/// Drawn entirely in code (no raster asset) so the star shares the
/// magnifier's exact colour. The glyph is deliberately NOT filled: only
/// the magnifier's outline is drawn (like a real icon), with the Best-move
/// star inside the lens.
class _BestSearchGlyph extends StatelessWidget {
  final Color color;
  final double size;

  const _BestSearchGlyph({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BestSearchGlyphPainter(color: color)),
    );
  }
}

class _BestSearchGlyphPainter extends CustomPainter {
  final Color color;

  _BestSearchGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry proportional to the Material `search` icon (24dp grid):
    // lens centre (9.5, 9.5), lens radius 6.5, stroke 2, handle to ~20.5.
    final double s = size.width;
    final Offset lensCenter = Offset(s * 9.5 / 24, s * 9.5 / 24);
    final double lensRadius = s * 6.5 / 24;
    final double stroke = s * 2 / 24;

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Lens.
    canvas.drawCircle(lensCenter, lensRadius, strokePaint);

    // Handle: from the lens edge towards the bottom-right corner.
    final Offset handleStart = Offset(
      lensCenter.dx + lensRadius / math.sqrt2,
      lensCenter.dy + lensRadius / math.sqrt2,
    );
    final Offset handleEnd = Offset(s * 20.5 / 24, s * 20.5 / 24);
    canvas.drawLine(handleStart, handleEnd, strokePaint);

    // The Best-move star inside the lens — outline magnifier only, no
    // filled disc, so it reads like a real glyph. The star carries the
    // same (grayish) colour as the magnifier strokes.
    final Path star = _starPath(
      lensCenter,
      lensRadius * 0.85,
      lensRadius * 0.36,
    );
    canvas.drawPath(star, Paint()..color = color);
  }

  /// Five-point star path (point up) around [center].
  static Path _starPath(Offset center, double outer, double inner) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final double radius = i.isEven ? outer : inner;
      final Offset point =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_BestSearchGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
