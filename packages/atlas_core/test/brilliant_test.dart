import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';

void main() {
  final svc = MoveClassificationService.instance;

  test('engine candidate scores are converted from centipawns to pawns', () {
    expect(svc.parseEngineEvaluation('+35'), 0.35);
    expect(svc.parseEngineEvaluation('-125'), -1.25);
    expect(svc.parseEngineEvaluation('M3'), 100.0);
    expect(svc.parseEngineEvaluation('M-2'), -100.0);
  });

  test('complete MultiPV cache entries cannot be downgraded', () {
    const fen = '8/8/8/8/8/8/4K3/4k2R w - - 0 1';
    final complete = PositionAnalysis(
      evalInPawns: 1.0,
      mateIn: null,
      expectedPoints: 0.59,
      bestMoveUci: 'h1h2',
      principalVariation: const ['h1h2'],
      candidateLines: [
        CandidateLine(
          moveUci: 'h1h2',
          evalInPawns: 1.0,
          expectedPoints: 0.59,
        ),
        CandidateLine(
          moveUci: 'e2d2',
          evalInPawns: 0.8,
          expectedPoints: 0.57,
        ),
      ],
    );
    final partial = PositionAnalysis(
      evalInPawns: -5.0,
      mateIn: null,
      expectedPoints: 0.14,
      bestMoveUci: 'e2d2',
      principalVariation: const ['e2d2'],
      candidateLines: [
        CandidateLine(
          moveUci: 'e2d2',
          evalInPawns: -5.0,
          expectedPoints: 0.14,
        ),
      ],
    );

    svc.clearCache();
    svc.cachePositionAnalysis(fen, complete);
    svc.cachePositionAnalysis(fen, partial);

    expect(svc.getCachedAnalysis(fen), same(complete));
  });

  // FEN: black to move, eval ~ -6.19 (black down a rook), best move f8f4
  const fenBefore = '5r2/pp6/2p3R1/4p2p/7k/5PR1/PPP2P1P/2K5 b - - 0 1';
  const moveUci = 'f8f3'; // Rxf3 — the "brilliant" move the user reports

  // PositionAnalysis for the BEFORE position (from Stockfish depth 15):
  // multipv 1: score cp -619, pv f8f4 c1d2 f4c4 g6g8 c6c5 g3g7 b7b5 g8e8
  // multipv 2: score cp -635, pv e5e4 f3e4 f8f2 e4e5 f2f5 e5e6 f5f1 c1d2
  //
  // evalBefore = -6.19 (STSM = black perspective)
  // epBefore = 1/(1+exp(0.368208*6.19)) ≈ 0.093
  // best move = f8f4
  final analysisBefore = PositionAnalysis(
    evalInPawns: -6.19,
    mateIn: null,
    expectedPoints: 0.093,
    bestMoveUci: 'f8f4',
    principalVariation: ['f8f4', 'c1d2', 'f4c4', 'g6g8', 'c6c5', 'g3g7', 'b7b5', 'g8e8'],
    candidateLines: [
      CandidateLine(moveUci: 'f8f4', evalInPawns: -6.19, mateIn: null, expectedPoints: 0.093),
      CandidateLine(moveUci: 'e5e4', evalInPawns: -6.35, mateIn: null, expectedPoints: 0.088),
    ],
  );

  // PositionAnalysis for the AFTER position (after Rxf3, white to move):
  // Stockfish finds: score mate 5 (white mates in 5), best move g3f3
  // STSM = white perspective: evalInPawns = +100.0, mateIn = +5
  // After negation in classifyWithData: evalAfter = -100.0, mateAfter = -5
  final analysisAfter = PositionAnalysis(
    evalInPawns: 100.0,
    mateIn: 5,
    expectedPoints: 0.995,
    bestMoveUci: 'g3f3',
    principalVariation: ['g3f3', 'c6c5', 'f3e3', 'c5c4', 'e3e4', 'h4h3', 'g6g3', 'h3h2', 'e4h4'],
    candidateLines: [
      CandidateLine(moveUci: 'g3f3', evalInPawns: 100.0, mateIn: 5, expectedPoints: 0.995),
    ],
  );

  test('a non-top move is never labeled best when its loss is tiny', () {
    final result = svc.classifyWithData(
      fenBefore: fenBefore,
      moveUci: 'e5e4',
      analysisBefore: analysisBefore,
      analysisAfter: PositionAnalysis(
        evalInPawns: 6.19,
        mateIn: null,
        expectedPoints: 0.093,
        bestMoveUci: 'g3f3',
        principalVariation: const ['g3f3'],
        candidateLines: [
          CandidateLine(
            moveUci: 'g3f3',
            evalInPawns: 6.19,
            mateIn: null,
            expectedPoints: 0.093,
          ),
        ],
      ),
    );

    expect(result.loss, lessThan(0.005));
    expect(result.classification, isNot(MoveClassification.best));
  });

  test('Rxf3 from -6.19 position with mate-after should NOT be brilliant', () {
    final result = svc.classifyWithData(
      fenBefore: fenBefore,
      moveUci: moveUci,
      analysisBefore: analysisBefore,
      analysisAfter: analysisAfter,
    );

    AppLogger.debug('Classification: ${result.classification}');
    AppLogger.debug('Comment: ${result.comment}');
    AppLogger.debug('Eval: ${result.evalBefore} -> ${result.evalAfter}');
    AppLogger.debug('Mate: before=${analysisBefore.mateIn} -> after=${analysisAfter.mateIn}');
    AppLogger.debug('Loss: ${result.loss}');
    AppLogger.debug('Best move: ${result.bestMove}');

    expect(result.classification, isNot(MoveClassification.brilliant),
        reason: 'Rxf3 hangs a rook and leads to black getting mated — not brilliant');
  });

  test('BrilliantMoveEngine directly rejects Rxf3 with correct evals', () {
    // Simulate what classifyWithData computes:
    // evalAfter = -analysisAfter.evalInPawns = -100.0
    // mateAfter = -analysisAfter.mateIn = -5
    // epAfter = calculateExpectedPoints(-100.0, mateIn: -5) ≈ 0.005
    // epLoss = 0.093 - 0.005 = 0.088
    // isBestMove = (f8f3 == f8f4) = false
    const epAfter = 0.005; // approximate
    const epLoss = 0.093 - epAfter; // 0.088

    final check = BrilliantMoveEngine.evaluateBrilliantMove(
      fenBefore: fenBefore,
      moveUci: moveUci,
      isBestMove: false,
      epLoss: epLoss,
      evalBefore: -6.19,
      epBefore: 0.093,
      evalAfter: -100.0,
      epAfter: epAfter,
      candidateLines: [
        CandidateLine(moveUci: 'f8f4', evalInPawns: -6.19, mateIn: null, expectedPoints: 0.093),
        CandidateLine(moveUci: 'e5e4', evalInPawns: -6.35, mateIn: null, expectedPoints: 0.088),
      ],
      mateAfter: -5,
      mateBefore: null,
    );

    AppLogger.debug('Engine result: isBrilliant=${check.isBrilliant}');
    AppLogger.debug('Reason: ${check.reason}');

    expect(check.isBrilliant, false, reason: 'Rxf3 is not brilliant — gate 1 rejects (not best, epLoss > 0.035)');
  });

  test('Standing gate rejects evalAfter -100.0 with mateAfter -5', () {
    // Gate 2.5: _isPostMoveStandingAcceptable(evalAfter: -100, mateAfter: -5)
    // mateAfter < 0 → false → rejected
    final check = BrilliantMoveEngine.evaluateBrilliantMove(
      fenBefore: fenBefore,
      moveUci: moveUci,
      isBestMove: true, // bypass gate 1
      epLoss: 0.0,      // bypass gate 1
      evalBefore: -6.19,
      epBefore: 0.093,
      evalAfter: -100.0,
      epAfter: 0.005,
      candidateLines: [
        CandidateLine(moveUci: 'f8f4', evalInPawns: -6.19, mateIn: null, expectedPoints: 0.093),
      ],
      mateAfter: -5,
      mateBefore: null,
    );

    AppLogger.debug('Standing gate result: isBrilliant=${check.isBrilliant}');
    AppLogger.debug('Reason: ${check.reason}');

    expect(check.isBrilliant, false,
        reason: 'Standing gate must reject: evalAfter -100.0 ≤ -1.0, mateAfter -5 < 0');
  });

  test('DEGENERATE after-analysis must NOT be brilliant (the user-reported bug)', () {
    // Reproduces the failure the user saw: if the AFTER-position analysis is
    // degenerate garbage (eval 0.0, no mate, no candidates — an engine
    // stall/stale cache), every eval-based gate passes trivially and only the
    // BOARD-based sacrifice detector decides. Rxf3 hangs the rook ->
    // "sacrifice detected" -> brilliant. The reliability guard must block it.
    final degenerateAfter = PositionAnalysis(
      evalInPawns: 0.0,
      mateIn: null,
      expectedPoints: 0.5,
      bestMoveUci: '0000',
      principalVariation: const [],
      candidateLines: const [],
    );

    final result = svc.classifyWithData(
      fenBefore: fenBefore,
      moveUci: moveUci,
      analysisBefore: analysisBefore,
      analysisAfter: degenerateAfter,
    );

    AppLogger.debug('Degenerate-after Classification: ${result.classification}');
    AppLogger.debug('Comment: ${result.comment}');

    expect(result.classification, isNot(MoveClassification.brilliant),
        reason: 'Degenerate after-analysis must never produce brilliant');
  });

  test('terminalPositionAnalysis: checkmate resolves deterministically', () {
    // Verified with the chess package: 0 legal moves + in_checkmate == true.
    // Black king a8 checkmated by Qc7 + Ra1 (covers the a-file/b8).
    const mateFen = 'k7/2Q5/8/8/8/8/8/R6K b - - 0 1';
    final a = svc.terminalPositionAnalysis(mateFen);

    expect(a, isNotNull);
    expect(a!.evalInPawns, -100.0);
    expect(a.mateIn, -1); // side to move is mated
    expect(a.expectedPoints, lessThan(0.05));
    expect(a.bestMoveUci, '0000');
    expect(a.candidateLines, isEmpty);
  });

  test('terminalPositionAnalysis: stalemate resolves as a draw', () {
    // Black king h8, white queen f7 and king g6: black has no legal moves
    // and is not in check -> stalemate.
    const staleFen = '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1';
    final a = svc.terminalPositionAnalysis(staleFen);

    expect(a, isNotNull);
    expect(a!.evalInPawns, 0.0);
    expect(a.mateIn, isNull);
    expect(a.expectedPoints, 0.5);
  });

  test('terminalPositionAnalysis: normal position returns null', () {
    const normalFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    expect(svc.terminalPositionAnalysis(normalFen), isNull);
  });

    test('classifyWithData: terminal after-analysis never crashes and is not brilliant unless a real sacrifice', () {
    // Black plays Rxf3 (f8f3); the AFTER position analysis is degenerate
    // garbage. The classification must complete (no hang) and must NOT be
    // brilliant (the after-guard skips brilliant for degenerate after-data).
    const beforeFen = '5r2/pp6/2p3R1/4p2p/7k/5PR1/PPP2P1P/2K5 b - - 0 1';
    final analysisBefore = PositionAnalysis(
      evalInPawns: -6.19,
      mateIn: null,
      expectedPoints: 0.093,
      bestMoveUci: 'f8f4',
      principalVariation: const ['f8f4'],
      candidateLines: [
        CandidateLine(moveUci: 'f8f4', evalInPawns: -6.19, mateIn: null, expectedPoints: 0.093),
      ],
    );
    // Degenerate after: engine produced no scored output for the position
    // after Rxf3. This is exactly the data that previously produced a false
    // brilliant.
    final degenerateAfter = PositionAnalysis(
      evalInPawns: 0.0,
      mateIn: null,
      expectedPoints: 0.5,
      bestMoveUci: '0000',
      principalVariation: const [],
      candidateLines: const [],
    );

    final result = svc.classifyWithData(
      fenBefore: beforeFen,
      moveUci: 'f8f3',
      analysisBefore: analysisBefore,
      analysisAfter: degenerateAfter,
    );

    AppLogger.debug('Degenerate-after Classification: ${result.classification}');
    expect(result.classification, isNot(MoveClassification.brilliant),
        reason: 'Degenerate after-analysis must never be brilliant');
  });
}