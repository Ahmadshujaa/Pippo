import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:atlas_core/core/engine/StockfishEngineService.dart';
import 'package:atlas_core/core/engine/engine_handle.dart';
import 'package:chess/chess.dart' as chess;

// =============================================================================
// ENUMS & DATA MODELS
// =============================================================================

enum MoveClassification {
  brilliant,
  great,
  best,
  excellent,
  good,
  inaccuracy,
  mistake,
  blunder,
  miss,
  book,
  forced,
}

class CandidateLine {
  final String moveUci;
  final double evalInPawns;
  final int? mateIn;
  final double expectedPoints;

  CandidateLine({
    required this.moveUci,
    required this.evalInPawns,
    this.mateIn,
    required this.expectedPoints,
  });
}

class PositionAnalysis {
  final double evalInPawns;
  final int? mateIn;
  final double expectedPoints;
  final String bestMoveUci;
  final List<String> principalVariation;
  final List<CandidateLine> candidateLines;

  PositionAnalysis({
    required this.evalInPawns,
    this.mateIn,
    required this.expectedPoints,
    required this.bestMoveUci,
    required this.principalVariation,
    required this.candidateLines,
  });
}

class ClassificationResult {
  final MoveClassification classification;
  final String comment;
  final double evalBefore;
  final double evalAfter;
  final double epBefore;
  final double epAfter;
  final double loss;
  final String bestMove;
  final String? playedMoveUci;
  final bool isSacrifice;
  final bool isPassiveSacrifice;
  final String? sacrificedSquare;

  ClassificationResult({
    required this.classification,
    required this.comment,
    required this.evalBefore,
    required this.evalAfter,
    required this.epBefore,
    required this.epAfter,
    required this.loss,
    required this.bestMove,
    this.playedMoveUci,
    this.isSacrifice = false,
    this.isPassiveSacrifice = false,
    this.sacrificedSquare,
  });

  Map<String, dynamic> toJson() => {
        'classification': classification.name,
        'comment': comment,
        'evalBefore': evalBefore,
        'evalAfter': evalAfter,
        'epBefore': epBefore,
        'epAfter': epAfter,
        'loss': loss,
        'bestMove': bestMove,
        'playedMoveUci': playedMoveUci,
        'isSacrifice': isSacrifice,
        'isPassiveSacrifice': isPassiveSacrifice,
        'sacrificedSquare': sacrificedSquare,
      };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    MoveClassification parseClassification(dynamic v) {
      final name = v?.toString();
      for (final c in MoveClassification.values) {
        if (c.name == name) return c;
      }
      return MoveClassification.good;
    }

    return ClassificationResult(
      classification: parseClassification(json['classification']),
      comment: json['comment']?.toString() ?? '',
      evalBefore: (json['evalBefore'] as num?)?.toDouble() ?? 0.0,
      evalAfter: (json['evalAfter'] as num?)?.toDouble() ?? 0.0,
      epBefore: (json['epBefore'] as num?)?.toDouble() ?? 0.0,
      epAfter: (json['epAfter'] as num?)?.toDouble() ?? 0.0,
      loss: (json['loss'] as num?)?.toDouble() ?? 0.0,
      bestMove: json['bestMove']?.toString() ?? '',
      playedMoveUci: json['playedMoveUci']?.toString(),
      isSacrifice: json['isSacrifice'] as bool? ?? false,
      isPassiveSacrifice: json['isPassiveSacrifice'] as bool? ?? false,
      sacrificedSquare: json['sacrificedSquare']?.toString(),
    );
  }

  @override
  String toString() {
    return 'ClassificationResult(classification: $classification, loss: ${loss.toStringAsFixed(3)}, eval: ${evalBefore.toStringAsFixed(2)} -> ${evalAfter.toStringAsFixed(2)}, comment: "$comment")';
  }
}

// =============================================================================
// MAIN MOVE CLASSIFICATION SERVICE
// =============================================================================

class MoveClassificationService {
  static MoveClassificationService? _instance;

  final Map<String, PositionAnalysis> _analysisCache = {};

  MoveClassificationService._();

  static MoveClassificationService get instance {
    _instance ??= MoveClassificationService._();
    return _instance!;
  }

  /// Pure-Dart entry point used by the background classification worker
  /// isolate.
  ///
  /// The computation is entirely stateless with respect to the caller's own
  /// singleton/caches, so a fresh local instance (created here and discarded)
  /// produces the same result as `instance.classifyWithData` while never
  /// touching the UI isolate's caches.
  static ClassificationResult runClassificationJob({
    required String fenBefore,
    required String moveUci,
    required PositionAnalysis analysisBefore,
    required PositionAnalysis analysisAfter,
    PositionAnalysis? analysisPrevious,
  }) {
    final service = MoveClassificationService._();
    return service.classifyWithData(
      fenBefore: fenBefore,
      moveUci: moveUci,
      analysisBefore: analysisBefore,
      analysisAfter: analysisAfter,
      analysisPrevious: analysisPrevious,
    );
  }

  void cachePositionAnalysis(String fen, PositionAnalysis analysis) {
    final existing = _analysisCache[fen];
    // Interactive engine updates can publish a single stable PV before all
    // requested MultiPV lines have arrived. Never let that partial result
    // replace a complete analysis already used for classification.
    if (existing != null &&
        existing.candidateLines.length > analysis.candidateLines.length) {
      return;
    }
    _analysisCache[fen] = analysis;
  }

  PositionAnalysis? getCachedAnalysis(String fen) => _analysisCache[fen];

  void clearCache() {
    _analysisCache.clear();
    BrilliantMoveEngine.clearCaches();
  }

  /// Removes one position from the engine-analysis cache without disturbing
  /// analyses for other positions currently being displayed or analyzed.
  ///
  /// Interactive classification uses this when its UI watchdog expires. A
  /// retry must not be allowed to consume an old partial result for the same
  /// position, while clearing the entire cache would unnecessarily invalidate
  /// every move in the current game.
  void clearCachedAnalysis(String fen) {
    _analysisCache.remove(fen);
  }

  // ===========================================================================
  // EXPECTED POINTS MODEL
  // ===========================================================================

  double calculateExpectedPoints(double evalInPawns, {int? mateIn}) {
    if (mateIn != null) {
      if (mateIn > 0) {
        return (1.0 - (mateIn * 0.001)).clamp(0.95, 1.0);
      } else if (mateIn < 0) {
        return (0.0 + ((-mateIn) * 0.001)).clamp(0.0, 0.05);
      } else {
        return 0.0;
      }
    }

    const double k = 0.368208;
    final double ep = 1.0 / (1.0 + math.exp(-k * evalInPawns));
    return ep.clamp(0.0, 1.0);
  }

  double calculateEpLoss(double epBest, double epPlayed) {
    final double loss = epBest - epPlayed;
    return loss < 0.0 ? 0.0 : loss;
  }

  /// Converts a Stockfish UCI score to the pawn units used by the classifier.
  double parseEngineEvaluation(String rawEvaluation) {
    final value = rawEvaluation.trim();
    if (value.startsWith('M')) {
      final mateIn = int.tryParse(value.substring(1)) ?? 0;
      return mateIn > 0 ? 100.0 : -100.0;
    }
    return (double.tryParse(value.replaceAll('+', '')) ?? 0.0) / 100.0;
  }

  ClassificationResult classifyWithData({
    required String fenBefore,
    required String moveUci,
    required PositionAnalysis analysisBefore,
    required PositionAnalysis analysisAfter,
    PositionAnalysis? analysisPrevious,
  }) {
    final String cleanMove = _normalizeUciMove(fenBefore, moveUci);

    final double evalAfter = -analysisAfter.evalInPawns;
    final int? mateAfter =
        analysisAfter.mateIn != null ? -analysisAfter.mateIn! : null;

    final double epAfter = calculateExpectedPoints(
      evalAfter,
      mateIn: mateAfter,
    );

    // A degenerate AFTER analysis (no scored engine line at all — best move
    // falls back to "0000" and no candidates exist) carries no trustworthy
    // eval. Every brilliant gate depends on that eval, so without it the
    // board-based sacrifice detector can label a plain blunder (e.g. hanging
    // a rook that leads to mate) as brilliant. The only legitimate
    // "degenerate-looking" after-analyses are terminal positions (checkmate /
    // stalemate), which are resolved synthetically and carry mate info or a
    // draw standing.
    final bool hasReliableAfterAnalysis = !(analysisAfter.bestMoveUci == "0000" &&
        analysisAfter.candidateLines.isEmpty &&
        analysisAfter.mateIn == null &&
        !_isTerminalPosition(_getFenAfterMove(fenBefore, cleanMove)));

    return determineClassification(
      fenBefore: fenBefore,
      moveUci: cleanMove,
      analysisBefore: analysisBefore,
      evalAfter: evalAfter,
      mateAfter: mateAfter,
      epAfter: epAfter,
      hasReliableAfterAnalysis: hasReliableAfterAnalysis,
      analysisPrevious: analysisPrevious,
    );
  }

  /// True when [fen] is a terminal position (no legal moves) — checkmate or
  /// stalemate. Such positions legitimately produce a synthetic analysis with
  /// no candidate lines, so they must not be treated as engine garbage.
  bool _isTerminalPosition(String fen) {
    try {
      return chess.Chess.fromFEN(fen).generate_moves().isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// True when playing [cleanMoveUci] (already normalized) from [fenBefore]
  /// delivers checkmate. Pure board logic — no engine eval involved.
  bool _isCheckmateMove(String fenBefore, String cleanMoveUci) {
    try {
      if (cleanMoveUci.length < 4) return false;
      final chess.Chess board = chess.Chess.fromFEN(fenBefore);
      final String from = cleanMoveUci.substring(0, 2);
      final String to = cleanMoveUci.substring(2, 4);
      final String? promo = cleanMoveUci.length > 4
          ? cleanMoveUci.substring(4, 5).toLowerCase()
          : null;
      final Map<String, dynamic> moveMap = {'from': from, 'to': to};
      if (promo != null && promo.isNotEmpty) {
        moveMap['promotion'] = promo;
      }
      final bool ok = board.move(moveMap);
      if (!ok) return false;
      return board.in_checkmate;
    } catch (_) {
      return false;
    }
  }

  String _normalizeUciMove(String fen, String moveUci) {
    String clean = moveUci.trim().replaceAll('-', '').replaceAll(' ', '');
    final chess.Chess board = chess.Chess.fromFEN(fen);

    if (clean.toUpperCase() == 'O-O') {
      return board.turn == chess.Color.WHITE ? 'e1g1' : 'e8g8';
    }
    if (clean.toUpperCase() == 'O-O-O') {
      return board.turn == chess.Color.WHITE ? 'e1c1' : 'e8c8';
    }

    return clean.toLowerCase();
  }

  String _getFenAfterMove(String fen, String moveUci) {
    final chess.Chess board = chess.Chess.fromFEN(fen);
    final String cleanMove = _normalizeUciMove(fen, moveUci);
    final String from = cleanMove.substring(0, 2);
    final String to = cleanMove.substring(2, 4);
    final String? promo = cleanMove.length > 4
        ? cleanMove.substring(4, 5).toLowerCase()
        : null;

    final Map<String, dynamic> moveMap = {'from': from, 'to': to};
    if (promo != null && promo.isNotEmpty) {
      moveMap['promotion'] = promo;
    }

    board.move(moveMap);
    return board.fen;
  }

  /// Resolves the only legal move before book, mate, or engine classifications.
  /// Promotion choices count as separate legal moves. No engine is required.
  ClassificationResult? tryClassifyForcedMove(
    String fen,
    String moveUci, {
    PositionAnalysis? analysisBefore,
  }) {
    final cleanMove = _normalizeUciMove(fen, moveUci);
    final moves = chess.Chess.fromFEN(fen).generate_moves();
    if (moves.length != 1) return null;
    final move = moves.single;
    final legalUci =
        '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
    if (cleanMove != legalUci) return null;

    final analysis = analysisBefore ?? getCachedAnalysis(fen);
    return ClassificationResult(
      classification: MoveClassification.forced,
      comment: 'Forced move (the only legal move available).',
      evalBefore: analysis?.evalInPawns ?? 0,
      evalAfter: analysis?.evalInPawns ?? 0,
      epBefore: analysis?.expectedPoints ?? 0.5,
      epAfter: analysis?.expectedPoints ?? 0.5,
      loss: 0,
      bestMove: legalUci,
      playedMoveUci: legalUci,
    );
  }

  ClassificationResult determineClassification({
    required String fenBefore,
    required String moveUci,
    required PositionAnalysis analysisBefore,
    required double evalAfter,
    int? mateAfter,
    required double epAfter,
    bool hasReliableAfterAnalysis = true,
    PositionAnalysis? analysisPrevious,
  }) {
    final String cleanMove = _normalizeUciMove(fenBefore, moveUci);
    final forced = tryClassifyForcedMove(
      fenBefore,
      cleanMove,
      analysisBefore: analysisBefore,
    );
    if (forced != null) return forced;

    final String bestMoveUci = analysisBefore.bestMoveUci.trim().toLowerCase();
    final double epBest = analysisBefore.expectedPoints;
    final double epLoss = calculateEpLoss(epBest, epAfter);
    final bool isBestMove = (cleanMove == bestMoveUci);

    // Non-forced checkmate is always the best move.
    // This is a pure board check (not engine eval): if the played move ends
    // the game by checkmate, it short-circuits brilliant / great / ordinary.
    if (_isCheckmateMove(fenBefore, cleanMove)) {
      return ClassificationResult(
        classification: MoveClassification.best,
        comment: "Checkmate — the best possible move.",
        evalBefore: analysisBefore.evalInPawns,
        evalAfter: evalAfter,
        epBefore: epBest,
        epAfter: epAfter,
        loss: epLoss,
        bestMove: bestMoveUci,
        playedMoveUci: cleanMove,
        isSacrifice: false,
        isPassiveSacrifice: false,
        sacrificedSquare: null,
      );
    }

    // ---------------------------------------------------------------------
    // Brilliant move detection.
    // ---------------------------------------------------------------------
    // Guards: brilliant is only meaningful when BOTH analyses are reliable.
    // - A degenerate parent analysis (no scored engine line — best move
    //   falls back to "0000" and no candidate lines exist) carries no
    //   trustworthy eval.
    // - A degenerate after analysis (same signature on a NON-terminal
    //   position) means the move's true outcome is unknown.
    // In either case every brilliant gate would be comparing against garbage,
    // so the board-based sacrifice detector could label a plain blunder (e.g.
    // hanging a rook into mate) as brilliant. Skip brilliant entirely.
    final bool hasReliableParentAnalysis =
        !(bestMoveUci == "0000" && analysisBefore.candidateLines.isEmpty);

    if (hasReliableParentAnalysis && hasReliableAfterAnalysis) {
      final brilliantCheck = BrilliantMoveEngine.evaluateBrilliantMove(
        fenBefore: fenBefore,
        moveUci: cleanMove,
        isBestMove: isBestMove,
        epLoss: epLoss,
        evalBefore: analysisBefore.evalInPawns,
        epBefore: epBest,
        evalAfter: evalAfter,
        epAfter: epAfter,
        candidateLines: analysisBefore.candidateLines,
        mateAfter: mateAfter,
        mateBefore: analysisBefore.mateIn,
      );

      if (brilliantCheck.isBrilliant) {
        return ClassificationResult(
          classification: MoveClassification.brilliant,
          comment: brilliantCheck.reason,
          evalBefore: analysisBefore.evalInPawns,
          evalAfter: evalAfter,
          epBefore: epBest,
          epAfter: epAfter,
          loss: epLoss,
          bestMove: bestMoveUci,
          playedMoveUci: cleanMove,
          isSacrifice: true,
          isPassiveSacrifice: brilliantCheck.isPassiveSacrifice,
          sacrificedSquare: brilliantCheck.sacrificedSquare,
        );
      }
    }

    // ---------------------------------------------------------------------
    // Great move detection.
    // ---------------------------------------------------------------------
    final GreatMoveEvaluation greatCheck = _isGreat(
      isBestMove: isBestMove,
      epLoss: epLoss,
      candidateLines: analysisBefore.candidateLines,
      evalBefore: analysisBefore.evalInPawns,
      epBefore: epBest,
      evalAfter: evalAfter,
      epAfter: epAfter,
      analysisPrevious: analysisPrevious,
    );

    if (greatCheck.isGreat) {
      return ClassificationResult(
        classification: MoveClassification.great,
        comment: greatCheck.reason,
        evalBefore: analysisBefore.evalInPawns,
        evalAfter: evalAfter,
        epBefore: epBest,
        epAfter: epAfter,
        loss: epLoss,
        bestMove: bestMoveUci,
        playedMoveUci: cleanMove,
        isSacrifice: false,
        isPassiveSacrifice: false,
        sacrificedSquare: null,
      );
    }

    // ---------------------------------------------------------------------
    // Ordinary classification.
    // ---------------------------------------------------------------------
    final OrdinaryClassification ordinary = _classifyOrdinary(
      isBestMove: isBestMove,
      epLoss: epLoss,
      epBefore: epBest,
      evalBefore: analysisBefore.evalInPawns,
    );

    return ClassificationResult(
      classification: ordinary.classification,
      comment: ordinary.comment,
      evalBefore: analysisBefore.evalInPawns,
      evalAfter: evalAfter,
      epBefore: epBest,
      epAfter: epAfter,
      loss: epLoss,
      bestMove: bestMoveUci,
      playedMoveUci: cleanMove,
      isSacrifice: false,
      isPassiveSacrifice: false,
      sacrificedSquare: null,
    );
  }

  // ===========================================================================
  // GREAT MOVE RULES
  // ===========================================================================

  GreatMoveEvaluation _isGreat({
    required bool isBestMove,
    required double epLoss,
    required List<CandidateLine> candidateLines,
    required double evalBefore,
    required double epBefore,
    required double evalAfter,
    required double epAfter,
    PositionAnalysis? analysisPrevious,
  }) {
    if (!isBestMove && epLoss > 0.005) {
      return GreatMoveEvaluation.notGreat();
    }

    // Only good move in the position.
    if (candidateLines.length >= 2) {
      final double secondBestEp = candidateLines[1].expectedPoints;
      final double epGap = epBefore - secondBestEp;
      final double evalGap = evalBefore - candidateLines[1].evalInPawns;

      if (epGap >= 0.12 || evalGap >= 1.50) {
        return GreatMoveEvaluation.great(
          "A great move! The only move that preserves your position's advantage.",
        );
      }
    }

    // Punishing opponent's mistake / saving resource.
    if (analysisPrevious != null) {
      final double evalBeforeOpponent = -analysisPrevious.evalInPawns;
      final double epBeforeOpponent = calculateExpectedPoints(
        evalBeforeOpponent,
      );

      final bool wasEqual =
          (epBeforeOpponent >= 0.42 && epBeforeOpponent <= 0.58) ||
              (evalBeforeOpponent >= -0.6 && evalBeforeOpponent <= 0.6);
      final bool isWinningNow = epAfter >= 0.72 || evalAfter >= 1.8;

      if (wasEqual && isWinningNow) {
        return GreatMoveEvaluation.great(
          "A great move! Capitalizing on the opponent's mistake to seize a winning advantage.",
        );
      }

      final bool wasLosing =
          epBeforeOpponent <= 0.30 || evalBeforeOpponent <= -2.0;
      final bool isSavedNow = epAfter >= 0.45 || evalAfter >= -0.75;

      if (wasLosing && isSavedNow) {
        return GreatMoveEvaluation.great(
          "A great move! Finding the critical defensive resource to save the game.",
        );
      }
    }

    // General turnaround.
    if (epBefore < 0.60 && epAfter >= 0.75 && (epAfter - epBefore) >= 0.18) {
      return GreatMoveEvaluation.great(
        "A great move that dramatically improves your winning chances.",
      );
    }

    return GreatMoveEvaluation.notGreat();
  }

  // ===========================================================================
  // ORDINARY CLASSIFICATION
  // ===========================================================================

  OrdinaryClassification _classifyOrdinary({
    required bool isBestMove,
    required double epLoss,
    required double epBefore,
    required double evalBefore,
  }) {
    if (isBestMove) {
      return OrdinaryClassification(
        MoveClassification.best,
        "The best move according to the engine.",
      );
    }

    if (epLoss < 0.02) {
      return OrdinaryClassification(
        MoveClassification.excellent,
        "An excellent move, keeping the strong position.",
      );
    }

    if (epLoss < 0.05) {
      return OrdinaryClassification(
        MoveClassification.good,
        "A good move, though slightly sub-optimal.",
      );
    }

    if (epLoss < 0.10) {
      return OrdinaryClassification(
        MoveClassification.inaccuracy,
        "An inaccuracy. There was a more precise continuation.",
      );
    }

    if (epLoss >= 0.15 && (epBefore >= 0.70 || evalBefore >= 2.0)) {
      return OrdinaryClassification(
        MoveClassification.miss,
        "You missed a winning tactical opportunity.",
      );
    }

    if (epLoss < 0.20) {
      return OrdinaryClassification(
        MoveClassification.mistake,
        "A mistake that noticeably weakens your position.",
      );
    }

    return OrdinaryClassification(
      MoveClassification.blunder,
      "A blunder that significantly harms your position.",
    );
  }

  // ===========================================================================
  // PUBLIC CLASSIFICATION ENTRY POINT
  // ===========================================================================

  Future<ClassificationResult> classifyMove(
    String fen,
    String moveUci, {
    String? previousFen,
    int depth = 13,
    EngineHandle? engineOverride,
  }) async {
    try {
      final String cleanMove = _normalizeUciMove(fen, moveUci);
      final forced = tryClassifyForcedMove(fen, cleanMove);
      if (forced != null) return forced;

      final PositionAnalysis analysisBefore = await analyzePosition(
        fen,
        depth: depth,
        multiPv: 2,
        engineOverride: engineOverride,
      );

      final String fenAfter = _getFenAfterMove(fen, cleanMove);

      final PositionAnalysis analysisAfterOpponent = await analyzePosition(
        fenAfter,
        depth: depth,
        multiPv: 1,
        engineOverride: engineOverride,
      );

      PositionAnalysis? analysisPrevious;
      if (previousFen != null) {
        try {
          analysisPrevious = await analyzePosition(
            previousFen,
            depth: depth,
            multiPv: 1,
            engineOverride: engineOverride,
          );
        } catch (_) {}
      }

      return classifyWithData(
        fenBefore: fen,
        moveUci: cleanMove,
        analysisBefore: analysisBefore,
        analysisAfter: analysisAfterOpponent,
        analysisPrevious: analysisPrevious,
      );
    } catch (e, stack) {
      dev.log("Error during move classification: $e\n$stack");
      rethrow;
    }
  }

  // ===========================================================================
  // STOCKFISH POSITION ANALYSIS
  // ===========================================================================

  /// [engineOverride] lets a caller drive classification through a DIFFERENT
  /// Stockfish process than the shared UI singleton (e.g. the background
  /// puzzle generator), so two engine instances can run side by side without
  /// their searches interleaving on one stream.
  Future<PositionAnalysis> analyzePosition(
    String fen, {
    int depth = 13,
    int multiPv = 2,
    EngineHandle? engineOverride,
  }) async {
    // Terminal positions (checkmate / stalemate) have no legal moves:
    // Stockfish answers `bestmove (none)` with no scored info lines, so an
    // engine search would stall until the timeout and return a degenerate
    // 0.0 eval. Resolve them deterministically instead.
    final PositionAnalysis? terminal = terminalPositionAnalysis(fen);
    if (terminal != null) return terminal;

    final Completer<PositionAnalysis> completer = Completer<PositionAnalysis>();
    final Map<int, CandidateLine> lines = {};

    String bestMoveFound = "";
    List<String> mainPv = [];
    double bestEvalInPawns = 0.0;
    int? bestMateIn;

    final engine = engineOverride ?? StockfishEngineService.instance;
    StreamSubscription<AnalysisResult>? subscription;
    Timer? timeout;

    PositionAnalysis buildAnalysis() {
      final ep = calculateExpectedPoints(bestEvalInPawns, mateIn: bestMateIn);

      final sortedLines = lines.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      final List<CandidateLine> candidateLines =
          sortedLines.map((e) => e.value).toList();

      String resolvedBestMove = bestMoveFound.trim();

      if (resolvedBestMove.isEmpty && candidateLines.isNotEmpty) {
        resolvedBestMove = candidateLines.first.moveUci;
      }

      if (resolvedBestMove.isEmpty) {
        resolvedBestMove = "0000";
      }

      return PositionAnalysis(
        evalInPawns: bestEvalInPawns,
        mateIn: bestMateIn,
        expectedPoints: ep,
        bestMoveUci: resolvedBestMove,
        principalVariation: mainPv,
        candidateLines: candidateLines,
      );
    }

    void completeNow() {
      if (completer.isCompleted) return;

      timeout?.cancel();

      try {
        engine.stop();
      } catch (_) {}

      completer.complete(buildAnalysis());
    }

    timeout = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completeNow();
      }
    });

    try {
      engine.setLines(multiPv);

      subscription = engine.analysisStream.listen((AnalysisResult result) {
        if (completer.isCompleted) return;
        if (result.fen != fen) return;

        final Map<int, int> lineDepths = result.lineDepths ?? const {};

        // The publish list is ordered by multipv number (1..N). A sparse or
        // incomplete publish simply leaves the map hole; the completion wait
        // below stays unsatisfied until every requested line is present.
        for (int i = 0; i < result.lines.length; i++) {
          final line = result.lines[i];
          final pvMoves = line.rawPv
              .split(' ')
              .where((m) => m.isNotEmpty)
              .toList();
          final String firstMove = pvMoves.isNotEmpty ? pvMoves.first : "";

          final ({double evalInPawns, int? mateIn}) parsedEval =
              _parseLineEval(line.eval);

          final int multipv = i + 1;
          final candidate = CandidateLine(
            moveUci: firstMove,
            evalInPawns: parsedEval.evalInPawns,
            mateIn: parsedEval.mateIn,
            expectedPoints: calculateExpectedPoints(
              parsedEval.evalInPawns,
              mateIn: parsedEval.mateIn,
            ),
          );

          lines[multipv] = candidate;

          if (multipv == 1) {
            bestEvalInPawns = parsedEval.evalInPawns;
            bestMateIn = parsedEval.mateIn;
            mainPv = pvMoves;
            if (firstMove.isNotEmpty) bestMoveFound = firstMove;
          }
        }

        // Completion: every requested MultiPV line has reached the target
        // depth in a single published result (the milestone publish is
        // exactly this shape for the default depth 13, and the depth-interval
        // throttle passes cover deeper/odd target depths).
        if (result.isFinal ||
            (lineDepths.isNotEmpty &&
                _haveAllLinesAtDepth(
                  requestedLines: multiPv,
                  requestedDepth: depth,
                  lineDepths: lineDepths,
                ))) {
          completeNow();
        }
      });

      engine.analyze(fen, depth: depth);
      final result = await completer.future;
      await subscription.cancel();
      return result;
    } catch (e) {
      timeout.cancel();

      try {
        engine.stop();
      } catch (_) {}

      await subscription?.cancel();
      rethrow;
    }
  }

  /// True when every requested MultiPV line (1..[requestedLines]) has reached
  /// [requestedDepth] per the depths recorded in a single published result.
  bool _haveAllLinesAtDepth({
    required int requestedLines,
    required int requestedDepth,
    required Map<int, int> lineDepths,
  }) {
    for (int i = 1; i <= requestedLines; i++) {
      if ((lineDepths[i] ?? 0) < requestedDepth) return false;
    }
    return true;
  }

  /// Converts a published [AnalysisLine.eval] string (`+0.34`, `M3`, ...) to
  /// the pawn-relative values used by the classifier, retaining the positive-
  /// favors-side-to-move sign convention of the engine output.
  ({double evalInPawns, int? mateIn}) _parseLineEval(String rawEvaluation) {
    final value = rawEvaluation.trim();
    if (value.startsWith('M')) {
      final mateIn = int.tryParse(value.substring(1)) ?? 0;
      return (evalInPawns: mateIn > 0 ? 100.0 : -100.0, mateIn: mateIn);
    }
    final val = double.tryParse(value.replaceAll('+', '')) ?? 0.0;
    // AnalysisLine.eval is already expressed in pawns (score / 100).
    return (evalInPawns: val, mateIn: null);
  }

  /// Returns a deterministic [PositionAnalysis] for positions where Stockfish
  /// produces no scored output, or null for normal positions.
  ///
  /// Terminal positions (checkmate / stalemate) have no legal moves, so the
  /// engine emits `bestmove (none)` without info lines. Resolving them here
  /// keeps classification working for game-ending moves and prevents
  /// degenerate 0.0-eval garbage from ever entering the analysis cache.
  ///
  /// Sign convention matches `_parseInfoLine`: positive eval / positive
  /// [PositionAnalysis.mateIn] favor the side to move. A checkmated side is
  /// therefore `-100.0` with `mateIn: -1` ("mated"); stalemate is a draw.
  PositionAnalysis? terminalPositionAnalysis(String fen) {
    try {
      final game = chess.Chess.fromFEN(fen);
      if (game.generate_moves().isNotEmpty) return null;

      if (game.in_checkmate) {
        return PositionAnalysis(
          evalInPawns: -100.0,
          mateIn: -1,
          expectedPoints: calculateExpectedPoints(-100.0, mateIn: -1),
          bestMoveUci: "0000",
          principalVariation: const [],
          candidateLines: const [],
        );
      }

      // Stalemate (or any other no-legal-moves draw): the game is drawn.
      return PositionAnalysis(
        evalInPawns: 0.0,
        mateIn: null,
        expectedPoints: 0.5,
        bestMoveUci: "0000",
        principalVariation: const [],
        candidateLines: const [],
      );
    } catch (_) {
      return null;
    }
  }
}

// =============================================================================
// BRILLIANT MOVE ENGINE
// =============================================================================

class BrilliantEvaluationResult {
  final bool isBrilliant;
  final bool isSacrifice;
  final bool isPassiveSacrifice;
  final String sacrificedSquare;
  final chess.PieceType? sacrificedPieceType;
  final String reason;

  const BrilliantEvaluationResult({
    required this.isBrilliant,
    this.isSacrifice = false,
    this.isPassiveSacrifice = false,
    this.sacrificedSquare = '',
    this.sacrificedPieceType,
    required this.reason,
  });

  factory BrilliantEvaluationResult.notBrilliant(String reason) =>
      BrilliantEvaluationResult(isBrilliant: false, reason: reason);

  factory BrilliantEvaluationResult.brilliant({
    required bool isPassive,
    required String square,
    required chess.PieceType pieceType,
    required String reason,
  }) =>
      BrilliantEvaluationResult(
        isBrilliant: true,
        isSacrifice: true,
        isPassiveSacrifice: isPassive,
        sacrificedSquare: square,
        sacrificedPieceType: pieceType,
        reason: reason,
      );
}

class _SacrificeContext {
  final bool isSacrifice;
  final bool isPassive;
  final String square;
  final chess.PieceType pieceType;
  final int materialInvested;

  const _SacrificeContext({
    required this.isSacrifice,
    this.isPassive = false,
    this.square = '',
    this.pieceType = chess.PieceType.PAWN,
    this.materialInvested = 0,
  });

  static const _SacrificeContext none = _SacrificeContext(isSacrifice: false);
}

class _SEEPiece {
  final String square;
  final chess.Piece piece;
  final int value;

  _SEEPiece(this.square, this.piece, this.value);
}

/// A profitable capture available to the side that just played a move if the
/// opponent were to pass.  The gain is expressed in the same centipawn-like
/// material units used by [BrilliantMoveEngine].
class ThreatArrow {
  final String fromSquare;
  final String toSquare;
  final int materialGain;

  const ThreatArrow({
    required this.fromSquare,
    required this.toSquare,
    required this.materialGain,
  });
}

class BrilliantMoveEngine {
  static const int valPawn = 100;
  static const int valKnight = 300;
  static const int valBishop = 300;
  static const int valRook = 500;
  static const int valQueen = 900;
  static const int valKing = 10000;

  static final Map<String, int> _bestMaterialOutcomeCache = {};
  static final Map<String, int> _moveOutcomeCache = {};
  static final Map<String, int> _effectiveCaptureCache = {};

  static final List<String> _squares = List<String>.generate(64, (i) {
    final file = String.fromCharCode(97 + (i % 8));
    final rank = (i ~/ 8) + 1;
    return '$file$rank';
  });

  static void clearCaches() {
    _bestMaterialOutcomeCache.clear();
    _moveOutcomeCache.clear();
    _effectiveCaptureCache.clear();
  }

  /// Finds captures the mover threatens immediately after [moveUci].
  ///
  /// This deliberately does not consult Stockfish or any positional
  /// evaluation. It temporarily gives the move back to the side that just
  /// played, enumerates only real captures, and scores every candidate with
  /// the same material outcome calculation used by brilliant-move detection.
  /// That calculation includes the multi-capture SEE sequence, pinned-piece
  /// legality, recaptures, and the opponent's best local punishment.
  static List<ThreatArrow> findThreats({
    required String fenBefore,
    required String moveUci,
    int minimumGain = 100,
  }) {
    try {
      final chess.Chess boardBefore = chess.Chess.fromFEN(fenBefore);
      final chess.Chess? boardAfter = _applyMove(
        boardBefore.fen,
        moveUci.trim().toLowerCase(),
      );
      if (boardAfter == null) return const [];

      final chess.Color moverColor = boardBefore.turn;
      final chess.Chess threatBoard = _withSideToMove(boardAfter, moverColor);
      final List<ThreatArrow> threats = [];

      // Ask the chess package for its real Move objects rather than SAN-like
      // or pretty maps. This gives us the authoritative capture flag and
      // preserves promotion information in the UCI string.
      for (final dynamic move in threatBoard.moves({'asObjects': true})) {
        if (move is! chess.Move || move.captured == null) continue;

        final String? uci = _uciFromVerbose(move);
        if (uci == null || uci.length < 4) continue;

        // An en-passant target left by the played move belongs to the
        // opponent's immediate reply and is not a valid capture for the mover
        // when we hypothetically give them the turn back. Requiring an actual
        // enemy piece on the destination square excludes it as well.
        final String targetSquare = uci.substring(2, 4);
        final chess.Piece? target = threatBoard.get(targetSquare);
        if (target == null || target.color == moverColor) continue;

        final int gain = _computeMoveNetMaterialOutcome(threatBoard, uci);
        if (gain < minimumGain) continue;

        threats.add(
          ThreatArrow(
            fromSquare: uci.substring(0, 2),
            toSquare: uci.substring(2, 4),
            materialGain: gain,
          ),
        );
      }

      threats.sort((a, b) => b.materialGain.compareTo(a.materialGain));
      return List<ThreatArrow>.unmodifiable(threats);
    } catch (e, stack) {
      dev.log('Threat detection failed safely: $e\n$stack');
      return const [];
    }
  }

  // ===========================================================================
  // MAIN EVALUATOR
  // ===========================================================================

  static BrilliantEvaluationResult evaluateBrilliantMove({
    required String fenBefore,
    required String moveUci,
    required bool isBestMove,
    required double epLoss,
    required double evalBefore,
    required double epBefore,
    required double evalAfter,
    required double epAfter,
    List<CandidateLine> candidateLines = const [],
    int? mateAfter,
    int? mateBefore,
  }) {
    final String cleanMove = moveUci.trim().toLowerCase();

    // 1. Quality tolerance.
    if (!isBestMove && epLoss > 0.035) {
      return BrilliantEvaluationResult.notBrilliant(
        "Move is not best or nearly best (EP loss > 0.035).",
      );
    }

    // 2. Outcome / evaluation transition filter.
    if (!_isOutcomeAcceptableForBrilliant(
      evalBefore: evalBefore,
      epBefore: epBefore,
      evalAfter: evalAfter,
      epAfter: epAfter,
      mateAfter: mateAfter,
    )) {
      return BrilliantEvaluationResult.notBrilliant(
        "Resulting evaluation transition does not justify a brilliant sacrifice.",
      );
    }

    try {
      final chess.Chess boardBefore = chess.Chess.fromFEN(fenBefore);

      // 3. Forced-loss / damage-control baseline.
      final int playedOutcome = _computeMoveNetMaterialOutcome(
        boardBefore,
        cleanMove,
      );
      final int bestOutcome = _computeBestMaterialOutcome(boardBefore);
      final int voluntaryDelta = math.max(0, bestOutcome - playedOutcome);

      final bool mateException = mateAfter != null && mateAfter > 0;

      // Without a mate exception, there must be extra voluntary material risk.
      if (voluntaryDelta < 100 && !mateException) {
        return BrilliantEvaluationResult.notBrilliant(
          "No voluntary material loss beyond forced/damage-control baseline.",
        );
      }

      // 4. Detect actual effective sacrifice.
      final _SacrificeContext sacContext = _detectSacrifice(
        boardBefore: boardBefore,
        moveUci: cleanMove,
        voluntaryDelta: voluntaryDelta,
        mateException: mateException,
      );

      if (!sacContext.isSacrifice) {
        return BrilliantEvaluationResult.notBrilliant(
          "No genuine effective voluntary sacrifice detected.",
        );
      }

      // 5. Overwhelming advantage filter.
      if (epBefore >= 0.94 || evalBefore >= 5.0) {
        final alternativeEps = candidateLines
            .skip(1)
            .map((l) => l.expectedPoints)
            .toList();
        if (alternativeEps.isNotEmpty && alternativeEps.first >= 0.90) {
          return BrilliantEvaluationResult.notBrilliant(
            "Position was already completely winning with simple alternative moves.",
          );
        }
      }

      // 6. Endgame uniqueness filter.
      if (_isEndgame(fenBefore)) {
        final alternativeEps = candidateLines
            .skip(1)
            .map((l) => l.expectedPoints)
            .toList();
        if (alternativeEps.isNotEmpty && alternativeEps.first >= 0.72) {
          return BrilliantEvaluationResult.notBrilliant(
            "In the endgame, simpler non-sacrificial moves also preserved the result.",
          );
        }
      }

      // 7. FINAL post-move standing gate (the last gate before brilliant is
      // awarded): no matter how elegant the sacrifice, a move that leaves the
      // mover at a clearly losing evaluation (<= -1.0 in player perspective)
      // cannot be brilliant. This runs even when the move was the engine's
      // top move and even when it did not change the eval at all — the only
      // thing that matters is the standing AFTER the move. The WDL model puts
      // -1.0 pawns around 0.41 expected points, just below the equal band.
      // Mate outcomes are handled explicitly so the engine's +/-100 pawn
      // sentinel never leaks into the pawn comparison.
      if (!_isPostMoveStandingAcceptable(evalAfter, mateAfter)) {
        return BrilliantEvaluationResult.notBrilliant(
          "After this move the evaluation is still clearly against you (<= -1.0); a sacrifice cannot be brilliant while the position stays lost.",
        );
      }

      // 8. FINAL hopeless-position gate: a side that is already being mated
      // (or was mated before the move, with no mate of its own in sight)
      // cannot earn a brilliant label. Sacrifices in a lost cause are damage
      // control, not brilliance.
      if (_isHopelessForBrilliant(mateBefore, mateAfter)) {
        return BrilliantEvaluationResult.notBrilliant(
          "The position is already lost (getting mated) — damage control does not qualify as brilliant.",
        );
      }

      final String comment = sacContext.isPassive
          ? "Brilliant! You left material en prise for a decisive tactical or positional purpose."
          : "A brilliant voluntary sacrifice that maintains or improves the position!";

      return BrilliantEvaluationResult.brilliant(
        isPassive: sacContext.isPassive,
        square: sacContext.square,
        pieceType: sacContext.pieceType,
        reason: comment,
      );
    } catch (e, stack) {
      dev.log("BrilliantMoveEngine error: $e\n$stack");
      return BrilliantEvaluationResult.notBrilliant(
        "Brilliant detection failed safely: $e",
      );
    }
  }

  // ===========================================================================
  // POST-MOVE STANDING & HOPELESS-POSITION GATES
  //
  // Both gates work purely in player-perspective space: positive eval / mate
  // favors the mover, negative favors the opponent. All comparisons are
  // NaN-safe and mate-aware so the engine's +/-100.0 pawn sentinel for mate
  // scores is never misread as a pawn value.
  // ===========================================================================

  /// Returns true when the post-move standing still allows a brilliant label.
  ///
  /// Rules:
  /// - If the move delivers mate to the opponent -> always acceptable.
  /// - If the move results in the mover being mated -> never acceptable.
  /// - Otherwise the raw pawn eval must be strictly better than -1.0.
  ///   A NaN eval (degenerate engine output) fails safe as unacceptable.
  static bool _isPostMoveStandingAcceptable(double evalAfter, int? mateAfter) {
    if (mateAfter != null) {
      if (mateAfter > 0) return true;  // mover delivers mate
      if (mateAfter < 0) return false; // mover gets mated
    }
    if (evalAfter.isNaN) return false;
    return evalAfter > -1.0;
  }

  /// Returns true when the situation is hopeless for the mover, which disqualifies
  /// a brilliant label regardless of how the move played out.
  ///
  /// Hopeless means one of:
  /// - After the move the mover is getting mated (mateAfter < 0).
  /// - Before the move the mover was already getting mated (mateBefore < 0)
  ///   and the move neither delivers mate itself nor escapes into a non-mate
  ///   standing.
  static bool _isHopelessForBrilliant(int? mateBefore, int? mateAfter) {
    // Being mated after the move is always hopeless.
    if (mateAfter != null && mateAfter < 0) return true;

    // If the mover was already getting mated before the move, the only escape
    // is a move that delivers its own mate or fully resolves the position to a
    // non-mate standing. Anything else is a lost cause.
    if (mateBefore != null && mateBefore < 0) {
      final bool deliversMate = mateAfter != null && mateAfter > 0;
      final bool escapedToNonMate = mateAfter == null;
      if (!deliversMate && !escapedToNonMate) return true;
    }

    return false;
  }

  // ===========================================================================
  // OUTCOME ACCEPTABILITY
  // ===========================================================================

  static bool _isOutcomeAcceptableForBrilliant({
    required double evalBefore,
    required double epBefore,
    required double evalAfter,
    required double epAfter,
    int? mateAfter,
  }) {
    if (mateAfter != null) {
      if (mateAfter > 0) return true;
      if (mateAfter < 0) return false;
    }

    if (evalAfter.isNaN || epAfter.isNaN) return false;

    const double losingEvalBefore = -1.50;
    const double winningEvalBefore = 1.50;

    const double afterWinningEval = 1.00;
    const double afterEqualishEval = -0.75;

    const double winningEpBefore = 0.68;
    const double losingEpBefore = 0.32;

    const double afterWinningEp = 0.62;
    const double afterEqualishEp = 0.40;
    const double afterSavedEp = 0.42;

    final bool wasWinning =
        evalBefore >= winningEvalBefore || epBefore >= winningEpBefore;
    final bool wasLosing =
        evalBefore <= losingEvalBefore || epBefore <= losingEpBefore;

    if (wasWinning) {
      // A brilliant move should not throw away a winning position.
      return evalAfter >= afterWinningEval || epAfter >= afterWinningEp;
    }

    if (wasLosing) {
      // A brilliant move from a losing position must significantly improve
      // the position, usually to a draw or win.
      final bool improved =
          evalAfter >= evalBefore + 0.75 || epAfter >= epBefore + 0.08;
      final bool saved =
          evalAfter >= afterEqualishEval || epAfter >= afterSavedEp;
      return improved && saved;
    }

    // Equal / unclear positions: must remain at least equalish.
    return evalAfter >= afterEqualishEval || epAfter >= afterEqualishEp;
  }

  // ===========================================================================
  // SACRIFICE DETECTION
  // ===========================================================================

  static _SacrificeContext _detectSacrifice({
    required chess.Chess boardBefore,
    required String moveUci,
    required int voluntaryDelta,
    required bool mateException,
  }) {
    try {
      final chess.Color playerColor = boardBefore.turn;
      final chess.Color opponentColor = _oppositeColor(playerColor);

      if (moveUci.length < 4) return _SacrificeContext.none;

      final String from = moveUci.substring(0, 2);
      final String to = moveUci.substring(2, 4);
      final String? promo = moveUci.length > 4
          ? moveUci.substring(4, 5).toLowerCase()
          : null;

      final chess.Piece? movedPiece = boardBefore.get(from);
      final chess.Chess? boardAfter = _applyMove(boardBefore.fen, moveUci);

      if (movedPiece == null || boardAfter == null) {
        return _SacrificeContext.none;
      }

      final chess.PieceType effectiveMovedType = promo != null
          ? _pieceTypeFromPromotion(promo)
          : movedPiece.type;

      // -----------------------------------------------------------------
      // ACTIVE SACRIFICE:
      // The moved piece itself can be effectively captured by the opponent
      // for a net material gain.
      // -----------------------------------------------------------------
      if (effectiveMovedType != chess.PieceType.KING) {
        final int activeMin =
            effectiveMovedType == chess.PieceType.PAWN ? 100 : 200;

        final int initialGain = _initialCaptureValue(boardBefore, moveUci);
        final int effectiveLossOnTarget = _effectiveGainForSideCapturingSquare(
          boardAfter,
          to,
          opponentColor,
        );

        final int netLoss = effectiveLossOnTarget - initialGain;

        if (netLoss >= activeMin &&
            (mateException || voluntaryDelta >= activeMin)) {
          return _SacrificeContext(
            isSacrifice: true,
            isPassive: false,
            square: to,
            pieceType: effectiveMovedType,
            materialInvested: netLoss,
          );
        }
      }

      // -----------------------------------------------------------------
      // PASSIVE SACRIFICE / RE-SACRIFICE:
      // Another piece remains hanging after the move and can be effectively
      // captured by the opponent.
      // -----------------------------------------------------------------
      int bestEffectiveGain = 0;
      String bestSquare = '';
      chess.PieceType bestPieceType = chess.PieceType.PAWN;

      for (final String sq in _squares) {
        if (sq == to) continue;

        final chess.Piece? piece = boardAfter.get(sq);
        if (piece == null || piece.color != playerColor) continue;
        if (piece.type == chess.PieceType.KING) continue;

        // Passive pawn sacrifices are usually too noisy for brilliant labels.
        if (piece.type == chess.PieceType.PAWN) continue;

        const int passiveMin = 200;

        // Mate exception may reduce the required voluntary delta,
        // but it must not remove it completely for passive sacrifices.
        final int passiveRequiredDelta = mateException ? 100 : passiveMin;

        final int localGain = evaluateSquareSEE(
          boardAfter,
          sq,
          opponentColor,
        );

        if (localGain < passiveMin) continue;

        final int effectiveGain = _effectiveGainForSideCapturingSquare(
          boardAfter,
          sq,
          opponentColor,
        );

        if (effectiveGain >= passiveMin &&
            voluntaryDelta >= passiveRequiredDelta) {
          if (effectiveGain > bestEffectiveGain) {
            bestEffectiveGain = effectiveGain;
            bestSquare = sq;
            bestPieceType = piece.type;
          }
        }
      }

      if (bestEffectiveGain > 0) {
        return _SacrificeContext(
          isSacrifice: true,
          isPassive: true,
          square: bestSquare,
          pieceType: bestPieceType,
          materialInvested: bestEffectiveGain,
        );
      }

      return _SacrificeContext.none;
    } catch (e) {
      dev.log("Error in _detectSacrifice: $e");
      return _SacrificeContext.none;
    }
  }

  // ===========================================================================
  // EFFECTIVE CAPTURE DETECTION
  //
  // This is stronger than plain SEE because it checks actual legal capture
  // moves and then scans for immediate punishments elsewhere on the board.
  // This handles relative pins, recapture deterrents, and similar tactics.
  // ===========================================================================

  static int _effectiveGainForSideCapturingSquare(
    chess.Chess board,
    String targetSquare,
    chess.Color sideColor,
  ) {
    try {
      final String cacheKey = "${board.fen}|$targetSquare|${sideColor.index}";
      if (_effectiveCaptureCache.containsKey(cacheKey)) {
        return _effectiveCaptureCache[cacheKey]!;
      }

      final chess.Chess activeBoard = _withSideToMove(board, sideColor);

      final chess.Piece? victim = activeBoard.get(targetSquare);
      if (victim == null || victim.color == sideColor) {
        _effectiveCaptureCache[cacheKey] = 0;
        return 0;
      }

      final List<dynamic> moves = activeBoard.moves({'verbose': true});
      int bestOutcome = 0;

      for (final dynamic m in moves) {
        final String? uci = _uciFromVerbose(m);
        if (uci == null || uci.length < 4) continue;

        final String moveToFile = uci.substring(2, 4);
        if (moveToFile != targetSquare) continue;

        final int directSEE = evaluateMoveSEE(activeBoard, uci);
        if (directSEE <= 0) {
          // If the local exchange is already not profitable, this capture
          // is unlikely to be an effective win. Still allow global scan
          // only when directSEE is positive.
          continue;
        }

        final chess.Chess? afterCapture = _applyMove(activeBoard.fen, uci);
        if (afterCapture == null) continue;

        final chess.Color responseColor = _oppositeColor(sideColor);

        // After sideColor captures on targetSquare, responseColor may have
        // immediate punishments elsewhere.
        final int responseGain = _maxLocalSEEForColor(
          board: afterCapture,
          vulnerableColor: sideColor,
          attackerColor: responseColor,
          excludeSquare: targetSquare,
        );

        final int outcome = directSEE - responseGain;
        if (outcome > bestOutcome) {
          bestOutcome = outcome;
        }
      }

      _effectiveCaptureCache[cacheKey] = bestOutcome;
      return bestOutcome;
    } catch (e) {
      dev.log("Error in _effectiveGainForSideCapturingSquare: $e");
      return 0;
    }
  }

  static int _maxLocalSEEForColor({
    required chess.Chess board,
    required chess.Color vulnerableColor,
    required chess.Color attackerColor,
    String? excludeSquare,
  }) {
    int maxGain = 0;

    for (final String sq in _squares) {
      if (excludeSquare != null && sq == excludeSquare) continue;

      final chess.Piece? piece = board.get(sq);
      if (piece == null || piece.color != vulnerableColor) continue;
      if (piece.type == chess.PieceType.KING) continue;

      final int gain = evaluateSquareSEE(board, sq, attackerColor);
      if (gain > maxGain) maxGain = gain;
    }

    return maxGain;
  }

  // ===========================================================================
  // MATERIAL BASELINE / DAMAGE CONTROL
  // ===========================================================================

  static int _computeBestMaterialOutcome(chess.Chess board) {
    try {
      final String fen = board.fen;
      if (_bestMaterialOutcomeCache.containsKey(fen)) {
        return _bestMaterialOutcomeCache[fen]!;
      }

      final List<dynamic> moves = board.moves({'verbose': true});
      int best = -1000000;

      for (final dynamic m in moves) {
        final String? uci = _uciFromVerbose(m);
        if (uci == null) continue;

        final int outcome = _computeMoveNetMaterialOutcome(board, uci);
        if (outcome > best) best = outcome;
      }

      if (best == -1000000) best = 0;

      _bestMaterialOutcomeCache[fen] = best;
      return best;
    } catch (e) {
      dev.log("Error in _computeBestMaterialOutcome: $e");
      return 0;
    }
  }

  static int _computeMoveNetMaterialOutcome(
    chess.Chess boardBefore,
    String moveUci,
  ) {
    try {
      final String key = "${boardBefore.fen}|$moveUci";
      if (_moveOutcomeCache.containsKey(key)) {
        return _moveOutcomeCache[key]!;
      }

      if (moveUci.length < 4) {
        _moveOutcomeCache[key] = 0;
        return 0;
      }

      final int directSEE = evaluateMoveSEE(boardBefore, moveUci);

      final chess.Chess? boardAfter = _applyMove(boardBefore.fen, moveUci);
      if (boardAfter == null) {
        _moveOutcomeCache[key] = directSEE;
        return directSEE;
      }

      final chess.Color playerColor = boardBefore.turn;
      final chess.Color opponentColor = _oppositeColor(playerColor);
      final String to = moveUci.substring(2, 4);

      int maxOtherGain = 0;

      for (final String sq in _squares) {
        if (sq == to) continue;

        final chess.Piece? piece = boardAfter.get(sq);
        if (piece == null || piece.color != playerColor) continue;
        if (piece.type == chess.PieceType.KING) continue;

        final int gain = evaluateSquareSEE(boardAfter, sq, opponentColor);
        if (gain > maxOtherGain) maxOtherGain = gain;
      }

      final int result = directSEE - maxOtherGain;
      _moveOutcomeCache[key] = result;
      return result;
    } catch (e) {
      dev.log("Error in _computeMoveNetMaterialOutcome: $e");
      return 0;
    }
  }

  // ===========================================================================
  // CORRECT SEE
  // ===========================================================================

  static int evaluateMoveSEE(chess.Chess boardBefore, String moveUci) {
    try {
      if (moveUci.length < 4) return 0;

      final String from = moveUci.substring(0, 2);
      final String to = moveUci.substring(2, 4);
      final String? promo = moveUci.length > 4
          ? moveUci.substring(4, 5).toLowerCase()
          : null;

      final chess.Piece? movedPiece = boardBefore.get(from);
      if (movedPiece == null) return 0;

      final int initialGain = _initialCaptureValue(boardBefore, moveUci);

      final chess.Chess simBoard = chess.Chess.fromFEN(boardBefore.fen);
      final Map<String, dynamic> moveMap = {'from': from, 'to': to};
      if (promo != null && promo.isNotEmpty) {
        moveMap['promotion'] = promo;
      }

      final bool moved = simBoard.move(moveMap);
      if (!moved) return 0;

      int currentVictimValue;
      if (promo != null && promo.isNotEmpty) {
        currentVictimValue = _getPieceValue(_pieceTypeFromPromotion(promo));
      } else {
        currentVictimValue = _getPieceValue(movedPiece.type);
      }

      final List<int> gain = [initialGain];
      chess.Color sideToMove = _oppositeColor(movedPiece.color);

      while (true) {
        final _SEEPiece? lva = _findLeastValuableAttacker(
          board: simBoard,
          targetSquare: to,
          attackerColor: sideToMove,
        );

        if (lva == null) break;

        gain.add(currentVictimValue);
        currentVictimValue = _getAttackerValueAfterCapture(lva.piece, to);

        final bool promoteToQueen =
            lva.piece.type == chess.PieceType.PAWN &&
                _isLastRankForColor(to, lva.piece.color);

        _simulateCaptureOnBoard(
          simBoard,
          lva.square,
          to,
          lva.piece,
          promoteToQueen,
        );

        sideToMove = _oppositeColor(sideToMove);
      }

      return _seeForcedInitialMove(gain);
    } catch (e) {
      dev.log("Error in evaluateMoveSEE: $e");
      return 0;
    }
  }

  static int evaluateSquareSEE(
    chess.Chess board,
    String targetSquare,
    chess.Color initiatorColor,
  ) {
    try {
      final chess.Piece? victim = board.get(targetSquare);
      if (victim == null) return 0;

      final chess.Chess simBoard = chess.Chess.fromFEN(board.fen);

      final List<int> gain = [];
      int currentVictimValue = _getPieceValue(victim.type);
      chess.Color sideToMove = initiatorColor;

      while (true) {
        final _SEEPiece? lva = _findLeastValuableAttacker(
          board: simBoard,
          targetSquare: targetSquare,
          attackerColor: sideToMove,
        );

        if (lva == null) break;

        gain.add(currentVictimValue);
        currentVictimValue = _getAttackerValueAfterCapture(
          lva.piece,
          targetSquare,
        );

        final bool promoteToQueen =
            lva.piece.type == chess.PieceType.PAWN &&
                _isLastRankForColor(targetSquare, lva.piece.color);

        _simulateCaptureOnBoard(
          simBoard,
          lva.square,
          targetSquare,
          lva.piece,
          promoteToQueen,
        );

        sideToMove = _oppositeColor(sideToMove);
      }

      return _seeOptionalInitiation(gain);
    } catch (e) {
      dev.log("Error in evaluateSquareSEE: $e");
      return 0;
    }
  }

  static int _seeForcedInitialMove(List<int> gain) {
    if (gain.isEmpty) return 0;

    int future = 0;
    for (int i = gain.length - 1; i >= 1; i--) {
      final bool initiatorTurn = i.isEven;
      if (initiatorTurn) {
        future = math.max(0, gain[i] + future);
      } else {
        future = math.min(0, -gain[i] + future);
      }
    }

    return gain.first + future;
  }

  static int _seeOptionalInitiation(List<int> gain) {
    if (gain.isEmpty) return 0;

    int future = 0;
    for (int i = gain.length - 1; i >= 0; i--) {
      final bool initiatorTurn = i.isEven;
      if (initiatorTurn) {
        future = math.max(0, gain[i] + future);
      } else {
        future = math.min(0, -gain[i] + future);
      }
    }

    return future;
  }

  static void _simulateCaptureOnBoard(
    chess.Chess board,
    String from,
    String to,
    chess.Piece attacker,
    bool promoteToQueen,
  ) {
    try {
      board.remove(from);
      board.remove(to);

      final chess.Piece placedPiece = promoteToQueen
          ? chess.Piece(chess.PieceType.QUEEN, attacker.color)
          : attacker;

      board.put(placedPiece, to);
    } catch (_) {
      // Ignore simulation failures; SEE should degrade safely.
    }
  }

  // ===========================================================================
  // ATTACKER DETECTION & PIN LEGALITY
  // ===========================================================================

  static _SEEPiece? _findLeastValuableAttacker({
    required chess.Chess board,
    required String targetSquare,
    required chess.Color attackerColor,
  }) {
    final int targetFile = _fileOf(targetSquare);
    final int targetRank = _rankOf(targetSquare);
    final List<_SEEPiece> attackers = [];

    void addIfLegal(String sq, chess.Piece p, int value) {
      if (_isPieceMoveLegalRegardingPin(board, sq, targetSquare, attackerColor)) {
        attackers.add(_SEEPiece(sq, p, value));
      }
    }

    // Pawns.
    final int pawnRankDelta = (attackerColor == chess.Color.WHITE) ? -1 : 1;
    final int pawnRank = targetRank + pawnRankDelta;
    for (final int fileOffset in [-1, 1]) {
      final int f = targetFile + fileOffset;
      if (_isValidCoord(f, pawnRank)) {
        final String sq = _squareFromCoords(f, pawnRank);
        final chess.Piece? p = board.get(sq);
        if (p != null &&
            p.color == attackerColor &&
            p.type == chess.PieceType.PAWN) {
          addIfLegal(sq, p, valPawn);
        }
      }
    }

    // Knights.
    const List<List<int>> knightOffsets = [
      [1, 2],
      [2, 1],
      [2, -1],
      [1, -2],
      [-1, -2],
      [-2, -1],
      [-2, 1],
      [-1, 2],
    ];
    for (final offset in knightOffsets) {
      final int f = targetFile + offset[0];
      final int r = targetRank + offset[1];
      if (_isValidCoord(f, r)) {
        final String sq = _squareFromCoords(f, r);
        final chess.Piece? p = board.get(sq);
        if (p != null &&
            p.color == attackerColor &&
            p.type == chess.PieceType.KNIGHT) {
          addIfLegal(sq, p, valKnight);
        }
      }
    }

    // Diagonal rays.
    const List<List<int>> diagDirs = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];
    for (final dir in diagDirs) {
      int step = 1;
      while (true) {
        final int f = targetFile + dir[0] * step;
        final int r = targetRank + dir[1] * step;
        if (!_isValidCoord(f, r)) break;

        final String sq = _squareFromCoords(f, r);
        final chess.Piece? p = board.get(sq);
        if (p != null) {
          if (p.color == attackerColor &&
              (p.type == chess.PieceType.BISHOP ||
                  p.type == chess.PieceType.QUEEN)) {
            final int val =
                (p.type == chess.PieceType.BISHOP) ? valBishop : valQueen;
            addIfLegal(sq, p, val);
          }
          break;
        }
        step++;
      }
    }

    // Orthogonal rays.
    const List<List<int>> orthoDirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];
    for (final dir in orthoDirs) {
      int step = 1;
      while (true) {
        final int f = targetFile + dir[0] * step;
        final int r = targetRank + dir[1] * step;
        if (!_isValidCoord(f, r)) break;

        final String sq = _squareFromCoords(f, r);
        final chess.Piece? p = board.get(sq);
        if (p != null) {
          if (p.color == attackerColor &&
              (p.type == chess.PieceType.ROOK ||
                  p.type == chess.PieceType.QUEEN)) {
            final int val =
                (p.type == chess.PieceType.ROOK) ? valRook : valQueen;
            addIfLegal(sq, p, val);
          }
          break;
        }
        step++;
      }
    }

    // King.
    for (int df = -1; df <= 1; df++) {
      for (int dr = -1; dr <= 1; dr++) {
        if (df == 0 && dr == 0) continue;
        final int f = targetFile + df;
        final int r = targetRank + dr;
        if (_isValidCoord(f, r)) {
          final String sq = _squareFromCoords(f, r);
          final chess.Piece? p = board.get(sq);
          if (p != null &&
              p.color == attackerColor &&
              p.type == chess.PieceType.KING) {
            addIfLegal(sq, p, valKing);
          }
        }
      }
    }

    if (attackers.isEmpty) return null;

    attackers.sort((a, b) => a.value.compareTo(b.value));
    return attackers.first;
  }

  static bool _isPieceMoveLegalRegardingPin(
    chess.Chess board,
    String from,
    String to,
    chess.Color color,
  ) {
    try {
      final String? kingSquare = _findKingSquare(board, color);
      if (kingSquare == null) return true;

      final chess.Color enemy = _oppositeColor(color);

      if (from == kingSquare) {
        return !_isSquareAttackedBy(
          board,
          to,
          enemy,
          ignoreSquares: <String>{from, to},
        );
      }

      final int kf = _fileOf(kingSquare);
      final int kr = _rankOf(kingSquare);
      final int ff = _fileOf(from);
      final int fr = _rankOf(from);

      final int df = ff - kf;
      final int dr = fr - kr;

      if (df == 0 && dr == 0) return true;

      final bool line = (df == 0 || dr == 0 || df.abs() == dr.abs());
      if (!line) return true;

      final int stepF = df.sign;
      final int stepR = dr.sign;

      bool seenFrom = false;
      String? pinningSquare;

      int step = 1;
      while (true) {
        final int curF = kf + stepF * step;
        final int curR = kr + stepR * step;
        if (!_isValidCoord(curF, curR)) break;

        final String sq = _squareFromCoords(curF, curR);
        final chess.Piece? p = board.get(sq);

        if (p != null) {
          if (!seenFrom) {
            if (sq == from) {
              seenFrom = true;
            } else {
              break;
            }
          } else {
            if (p.color == enemy && _isSliderAlong(p.type, stepF, stepR)) {
              pinningSquare = sq;
            }
            break;
          }
        }

        step++;
      }

      if (pinningSquare == null) return true;

      final int tf = _fileOf(to);
      final int tr = _rankOf(to);
      final int tdf = tf - kf;
      final int tdr = tr - kr;

      final bool toLine = (tdf == 0 || tdr == 0 || tdf.abs() == tdr.abs());
      if (!toLine) return false;

      if (tdf.sign != stepF || tdr.sign != stepR) return false;

      final int distTo = math.max(tdf.abs(), tdr.abs());

      final int pf = _fileOf(pinningSquare) - kf;
      final int pr = _rankOf(pinningSquare) - kr;
      final int distPin = math.max(pf.abs(), pr.abs());

      return distTo <= distPin;
    } catch (e) {
      dev.log("Error in _isPieceMoveLegalRegardingPin: $e");
      return true;
    }
  }

  static bool _isSliderAlong(chess.PieceType type, int stepF, int stepR) {
    final bool diagonal = stepF != 0 && stepR != 0;
    if (diagonal) {
      return type == chess.PieceType.BISHOP || type == chess.PieceType.QUEEN;
    }
    return type == chess.PieceType.ROOK || type == chess.PieceType.QUEEN;
  }

  static bool _isSquareAttackedBy(
    chess.Chess board,
    String targetSquare,
    chess.Color attackerColor, {
    Set<String> ignoreSquares = const <String>{},
  }) {
    final int targetFile = _fileOf(targetSquare);
    final int targetRank = _rankOf(targetSquare);

    bool ignored(String sq) => ignoreSquares.contains(sq);

    // Pawns.
    final int pawnRankDelta = (attackerColor == chess.Color.WHITE) ? -1 : 1;
    final int pawnRank = targetRank + pawnRankDelta;
    for (final int fileOffset in [-1, 1]) {
      final int f = targetFile + fileOffset;
      if (_isValidCoord(f, pawnRank)) {
        final String sq = _squareFromCoords(f, pawnRank);
        if (ignored(sq)) continue;
        final chess.Piece? p = board.get(sq);
        if (p != null &&
            p.color == attackerColor &&
            p.type == chess.PieceType.PAWN) {
          return true;
        }
      }
    }

    // Knights.
    const List<List<int>> knightOffsets = [
      [1, 2],
      [2, 1],
      [2, -1],
      [1, -2],
      [-1, -2],
      [-2, -1],
      [-2, 1],
      [-1, 2],
    ];
    for (final offset in knightOffsets) {
      final int f = targetFile + offset[0];
      final int r = targetRank + offset[1];
      if (_isValidCoord(f, r)) {
        final String sq = _squareFromCoords(f, r);
        if (ignored(sq)) continue;
        final chess.Piece? p = board.get(sq);
        if (p != null &&
            p.color == attackerColor &&
            p.type == chess.PieceType.KNIGHT) {
          return true;
        }
      }
    }

    // Diagonal rays.
    const List<List<int>> diagDirs = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];
    for (final dir in diagDirs) {
      int step = 1;
      while (true) {
        final int f = targetFile + dir[0] * step;
        final int r = targetRank + dir[1] * step;
        if (!_isValidCoord(f, r)) break;

        final String sq = _squareFromCoords(f, r);
        if (ignored(sq)) {
          step++;
          continue;
        }

        final chess.Piece? p = board.get(sq);
        if (p != null) {
          if (p.color == attackerColor &&
              (p.type == chess.PieceType.BISHOP ||
                  p.type == chess.PieceType.QUEEN)) {
            return true;
          }
          break;
        }
        step++;
      }
    }

    // Orthogonal rays.
    const List<List<int>> orthoDirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];
    for (final dir in orthoDirs) {
      int step = 1;
      while (true) {
        final int f = targetFile + dir[0] * step;
        final int r = targetRank + dir[1] * step;
        if (!_isValidCoord(f, r)) break;

        final String sq = _squareFromCoords(f, r);
        if (ignored(sq)) {
          step++;
          continue;
        }

        final chess.Piece? p = board.get(sq);
        if (p != null) {
          if (p.color == attackerColor &&
              (p.type == chess.PieceType.ROOK ||
                  p.type == chess.PieceType.QUEEN)) {
            return true;
          }
          break;
        }
        step++;
      }
    }

    // King.
    for (int df = -1; df <= 1; df++) {
      for (int dr = -1; dr <= 1; dr++) {
        if (df == 0 && dr == 0) continue;
        final int f = targetFile + df;
        final int r = targetRank + dr;
        if (_isValidCoord(f, r)) {
          final String sq = _squareFromCoords(f, r);
          if (ignored(sq)) continue;
          final chess.Piece? p = board.get(sq);
          if (p != null &&
              p.color == attackerColor &&
              p.type == chess.PieceType.KING) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static chess.Chess _withSideToMove(chess.Chess board, chess.Color sideColor) {
    if (board.turn == sideColor) return board;

    try {
      final parts = board.fen.split(' ');
      if (parts.length >= 2) {
        parts[1] = sideColor == chess.Color.WHITE ? 'w' : 'b';
        return chess.Chess.fromFEN(parts.join(' '));
      }
    } catch (_) {}

    return board;
  }

  static chess.Chess? _applyMove(String fen, String moveUci) {
    try {
      if (moveUci.length < 4) return null;

      final chess.Chess board = chess.Chess.fromFEN(fen);
      final String from = moveUci.substring(0, 2);
      final String to = moveUci.substring(2, 4);
      final String? promo = moveUci.length > 4
          ? moveUci.substring(4, 5).toLowerCase()
          : null;

      final Map<String, dynamic> moveMap = {'from': from, 'to': to};
      if (promo != null && promo.isNotEmpty) {
        moveMap['promotion'] = promo;
      }

      final bool ok = board.move(moveMap);
      return ok ? board : null;
    } catch (_) {
      return null;
    }
  }

  static String? _uciFromVerbose(dynamic m) {
    try {
      if (m is chess.Move) {
        final promotion = m.promotion?.name ?? '';
        return '${m.fromAlgebraic}${m.toAlgebraic}$promotion';
      }

      if (m is Map) {
        final from = m['from'];
        final to = m['to'];
        if (from == null || to == null) return null;

        String promo = '';
        if (m.containsKey('promotion') && m['promotion'] != null) {
          promo = m['promotion'].toString().toLowerCase();
        }

        return '$from$to$promo';
      }

      final s = m.toString().trim().replaceAll('-', '').toLowerCase();
      if (s.length >= 4) return s;
      return null;
    } catch (_) {
      return null;
    }
  }

  static int _initialCaptureValue(chess.Chess boardBefore, String moveUci) {
    try {
      if (moveUci.length < 4) return 0;

      final String from = moveUci.substring(0, 2);
      final String to = moveUci.substring(2, 4);

      final chess.Piece? captured = boardBefore.get(to);
      if (captured != null) {
        return _getPieceValue(captured.type);
      }

      final chess.Piece? moved = boardBefore.get(from);
      if (moved != null &&
          moved.type == chess.PieceType.PAWN &&
          from.isNotEmpty &&
          to.isNotEmpty &&
          from[0] != to[0]) {
        // En passant or diagonal pawn capture to an empty square.
        return valPawn;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  static int _getAttackerValueAfterCapture(chess.Piece piece, String to) {
    if (piece.type == chess.PieceType.PAWN &&
        _isLastRankForColor(to, piece.color)) {
      return valQueen;
    }
    return _getPieceValue(piece.type);
  }

  static bool _isLastRankForColor(String square, chess.Color color) {
    final rank = _rankOf(square);
    if (color == chess.Color.WHITE) return rank == 7;
    return rank == 0;
  }

  static chess.PieceType _pieceTypeFromPromotion(String promo) {
    switch (promo.toLowerCase()) {
      case 'q':
        return chess.PieceType.QUEEN;
      case 'r':
        return chess.PieceType.ROOK;
      case 'b':
        return chess.PieceType.BISHOP;
      case 'n':
        return chess.PieceType.KNIGHT;
      default:
        return chess.PieceType.QUEEN;
    }
  }

  static String? _findKingSquare(chess.Chess board, chess.Color color) {
    for (final String sq in _squares) {
      final chess.Piece? p = board.get(sq);
      if (p != null && p.color == color && p.type == chess.PieceType.KING) {
        return sq;
      }
    }
    return null;
  }

  static chess.Color _oppositeColor(chess.Color color) {
    return color == chess.Color.WHITE ? chess.Color.BLACK : chess.Color.WHITE;
  }

  static bool _isEndgame(String fen) {
    try {
      final chess.Chess board = chess.Chess.fromFEN(fen);
      int whiteMaterial = 0;
      int blackMaterial = 0;

      for (final String sq in _squares) {
        final chess.Piece? piece = board.get(sq);
        if (piece == null ||
            piece.type == chess.PieceType.PAWN ||
            piece.type == chess.PieceType.KING) {
          continue;
        }

        final val = _getPieceValue(piece.type);
        if (piece.color == chess.Color.WHITE) {
          whiteMaterial += val;
        } else {
          blackMaterial += val;
        }
      }

      return whiteMaterial <= 1300 && blackMaterial <= 1300;
    } catch (_) {
      return false;
    }
  }

  static int _getPieceValue(chess.PieceType? type) {
    if (type == null) return 0;
    switch (type) {
      case chess.PieceType.PAWN:
        return valPawn;
      case chess.PieceType.KNIGHT:
        return valKnight;
      case chess.PieceType.BISHOP:
        return valBishop;
      case chess.PieceType.ROOK:
        return valRook;
      case chess.PieceType.QUEEN:
        return valQueen;
      case chess.PieceType.KING:
        return valKing;
      default:
        return 0;
    }
  }

  static int _fileOf(String sq) => sq.codeUnitAt(0) - 97;
  static int _rankOf(String sq) => sq.codeUnitAt(1) - 49;
  static bool _isValidCoord(int f, int r) =>
      f >= 0 && f < 8 && r >= 0 && r < 8;

  static String _squareFromCoords(int f, int r) =>
      '${String.fromCharCode(97 + f)}${r + 1}';
}

// =============================================================================
// HELPER STRUCTS
// =============================================================================

class OrdinaryClassification {
  final MoveClassification classification;
  final String comment;

  OrdinaryClassification(this.classification, this.comment);
}

class GreatMoveEvaluation {
  final bool isGreat;
  final String reason;

  GreatMoveEvaluation._(this.isGreat, this.reason);

  factory GreatMoveEvaluation.great(String reason) =>
      GreatMoveEvaluation._(true, reason);

  factory GreatMoveEvaluation.notGreat() =>
      GreatMoveEvaluation._(false, "");
}
