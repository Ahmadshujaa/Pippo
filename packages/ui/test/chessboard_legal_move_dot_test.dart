import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';

const double _boardSize = 400.0;
const double _squareSize = _boardSize / 8;

/// Board-space centre of [square] (e.g. `e2`) in White orientation.
Offset _centreOf(String square) {
  final file = square.codeUnitAt(0) - 97; // 'a' -> 0
  final rank = int.parse(square.substring(1)); // 1..8
  return Offset(
    file * _squareSize + _squareSize / 2,
    (8 - rank) * _squareSize + _squareSize / 2,
  );
}

Future<void> _pumpBoard(
  WidgetTester tester,
  ChessboardController controller, {
  void Function(String from, String to)? onMove,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _boardSize,
            height: _boardSize,
            child: ChessBoard(
              controller: controller,
              onMove: onMove,
              showSettingsButton: false,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a move rejected by an external handler does not leave the legal-move '
    'indicator stuck on the board',
    (WidgetTester tester) async {
      final controller = ChessboardController();
      final attempts = <String>[];
      // The puzzle screens hand every attempt to `onMove` and simply return
      // when the move is not the solution — the controller is never touched.
      await _pumpBoard(
        tester,
        controller,
        onMove: (from, to) => attempts.add('$from$to'),
      );

      final boardTopLeft = tester.getTopLeft(
        find.descendant(
          of: find.byType(ChessBoard),
          matching: find.byType(AspectRatio),
        ),
      );

      await tester.tapAt(boardTopLeft + _centreOf('e2'));
      await tester.pumpAndSettle();

      expect(controller.selectedSquare, 'e2');
      expect(controller.legalMoves, contains('e4'));

      await tester.tapAt(boardTopLeft + _centreOf('e4'));
      await tester.pumpAndSettle();

      expect(attempts, ['e2e4']);
      expect(
        controller.selectedSquare,
        isNull,
        reason: 'the piece must not stay picked up after the attempt',
      );
      expect(
        controller.legalMoves,
        isEmpty,
        reason: 'the legal-move dots must not outlive the move attempt',
      );
    },
  );
}
