import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/features/analysis/game_analyzer.dart';
import 'package:atlas_core/features/board/chessboard_controller.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = MoveClassificationService.instance;
  const forcedFen = 'k7/8/2K5/8/8/8/8/R7 b - - 0 1';

  setUp(service.clearCache);

  test('forced overrides engine loss and survives serialization', () {
    final before = PositionAnalysis(
      evalInPawns: 10,
      expectedPoints: 0.99,
      bestMoveUci: 'a8b8',
      principalVariation: const ['a8b8'],
      candidateLines: const [],
    );
    final after = PositionAnalysis(
      evalInPawns: 10,
      expectedPoints: 0.99,
      bestMoveUci: 'a1a2',
      principalVariation: const ['a1a2'],
      candidateLines: const [],
    );
    final result = MoveClassificationService.runClassificationJob(
      fenBefore: forcedFen,
      moveUci: 'a8b8',
      analysisBefore: before,
      analysisAfter: after,
    );
    expect(result.classification, MoveClassification.forced);
    expect(result.loss, 0);
    expect(ClassificationResult.fromJson(result.toJson()).classification,
        MoveClassification.forced);
  });

  test('zero moves, multiple moves, and illegal input are not forced', () {
    expect(service.tryClassifyForcedMove(forcedFen, 'a8a7'), isNull);
    expect(service.tryClassifyForcedMove(chess.Chess().fen, 'e2e4'), isNull);
    const mate = 'k7/1Q6/2K5/8/8/8/8/8 b - - 0 1';
    expect(chess.Chess.fromFEN(mate).moves(), isEmpty);
    expect(service.tryClassifyForcedMove(mate, 'a8b8'), isNull);
  });

  test('promotion choices are separate legal moves', () {
    const fen = '8/P7/8/8/8/5k2/8/7K w - - 0 1';
    final board = chess.Chess.fromFEN(fen);
    expect(board.generate_moves().where((m) => m.promotion != null).length, 4);
    expect(service.tryClassifyForcedMove(fen, 'a7a8q'), isNull);
  });

  testWidgets('full-game analysis resolves forced before book or engine',
      (tester) async {
    final controller = ChessboardController(fen: forcedFen);
    expect(controller.makeMove('a8', 'b8'), isTrue);
    final node = controller.currentNode;
    final analyzer = GameAnalyzer(controller: controller);
    await analyzer.analyze(
      mainline: [node],
      onProgress: (_, _, _) {},
      isCanceled: () => false,
    );
    expect(node.classification?.classification, MoveClassification.forced);
    expect(node.isPendingClassification, isFalse);
    expect(analyzer.bookEnded, isFalse);
    tester.binding.scheduleFrame();
    await tester.pump();
    controller.dispose();
  });

  test('classifyMove returns forced without starting an engine', () async {
    final board = chess.Chess.fromFEN(forcedFen);
    expect(board.moves(), ['Kb8']);

    final result = await service.classifyMove(forcedFen, 'a8b8');
    expect(result.classification, MoveClassification.forced);
    expect(result.playedMoveUci, 'a8b8');
    expect(result.loss, 0);
  });
}
