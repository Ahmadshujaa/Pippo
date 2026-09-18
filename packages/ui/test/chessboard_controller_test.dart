import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_core/atlas_core.dart';

void main() {
  group('ChessboardController', () {
    test('selecting a pawn exposes its legal destination squares', () {
      final controller = ChessboardController();

      controller.selectSquare('e2');

      expect(controller.selectedSquare, 'e2');
      expect(controller.legalMoves, containsAll(<String>['e3', 'e4']));
    });

    test('makes a selected legal move and changes the turn', () {
      final controller = ChessboardController();

      expect(controller.makeMove('e2', 'e4'), isTrue);
      expect(controller.game.get('e2'), isNull);
      expect(controller.game.get('e4'), isNotNull);
      expect(controller.selectedSquare, isNull);
    });
  });
}

