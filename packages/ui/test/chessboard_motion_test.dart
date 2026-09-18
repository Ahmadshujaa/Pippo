import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_ui/shared/widgets/ChessboardTransitions.dart';

const double _boardSize = 400.0;
const double _squareSize = _boardSize / 8;
const double _pieceSize = 46.0;
const Key _pieceKey = ValueKey('piece');

/// Wraps [child] in a board that reproduces the real one: a `Stack` with
/// `StackFit.expand`, which hands its children **tight** constraints the size
/// of the whole board.
///
/// This detail matters. Under loose constraints a one-square box keeps the size
/// it asks for; under tight constraints it is stretched to the board and the
/// piece ends up centred on the board instead of on its square. The overlay
/// used to have exactly that bug, and a test with a loose-fitting Stack passed
/// straight through it.
Widget _board(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        width: _boardSize,
        height: _boardSize,
        child: Stack(fit: StackFit.expand, children: [child]),
      ),
    ),
  );
}

/// Mimics a real board piece: centred artwork inside its square.
Widget _piece() => const Center(
  child: SizedBox(key: _pieceKey, width: _pieceSize, height: _pieceSize),
);

void expectOffsetCloseTo(Offset actual, Offset expected, {String? reason}) {
  expect(actual.dx, closeTo(expected.dx, 0.5), reason: reason);
  expect(actual.dy, closeTo(expected.dy, 0.5), reason: reason);
}

/// Nearest [Transform] ancestor of the piece — the scale transform.
double _scaleOf(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.ancestor(
      of: find.byKey(_pieceKey),
      matching: find.byType(Transform),
    ).first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  group('MovingPieceOverlay', () {
    testWidgets('flies along the real path and lands on the target square', (
      WidgetTester tester,
    ) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 320),
      );
      addTearDown(progress.dispose);

      await tester.pumpWidget(
        _board(
          MovingPieceOverlay(
            progress: progress,
            // Bottom-left square, to a square four files right and four up.
            from: const BoardSquare(0, 7),
            to: const BoardSquare(4, 3),
            child: _piece(),
          ),
        ),
      );

      final boardOrigin = tester.getTopLeft(find.byType(Stack));

      // The controller value only takes effect after a frame is pumped.
      Future<Offset> centreAfterPump(double t) async {
        progress.value = t;
        await tester.pump();
        return tester.getCenter(find.byKey(_pieceKey));
      }

      expectOffsetCloseTo(
        await centreAfterPump(0.0),
        boardOrigin + const Offset(0, 7 * _squareSize) + const Offset(25, 25),
        reason: 'must start centred on the origin square',
      );

      expectOffsetCloseTo(
        await centreAfterPump(0.5),
        boardOrigin + const Offset(100, 250) + const Offset(25, 25),
        reason: 'must be halfway between the two squares',
      );

      expectOffsetCloseTo(
        await centreAfterPump(1.0),
        boardOrigin + const Offset(200, 150) + const Offset(25, 25),
        reason: 'must land centred on the destination square',
      );

      // Guards the original bug: under tight constraints the one-square box
      // was stretched to the whole board and the artwork scaled with it.
      expect(tester.getSize(find.byKey(_pieceKey)), const Size(46, 46));
    });

    testWidgets('swells mid-flight and lands flush', (
      WidgetTester tester,
    ) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 320),
      );
      addTearDown(progress.dispose);

      await tester.pumpWidget(
        _board(
          MovingPieceOverlay(
            progress: progress,
            // Straight down the board, so flight scale is the only variable.
            from: const BoardSquare(0, 0),
            to: const BoardSquare(0, 4),
            child: _piece(),
          ),
        ),
      );

      // Transform.scale only affects painting, not layout, so the scale has to
      // be read off the transform matrix rather than from the rendered size.
      Future<double> scaleAt(double t) async {
        progress.value = t;
        await tester.pump();
        return _scaleOf(tester);
      }

      final resting = await scaleAt(0.0);
      final midFlight = await scaleAt(0.5);
      final landed = await scaleAt(1.0);

      expect(resting, closeTo(1.0, 0.001));
      expect(midFlight, greaterThan(resting), reason: 'lifts off the board');
      expect(landed, closeTo(resting, 0.001), reason: 'settles flush on landing');
    });
  });

  group('CapturedPieceOverlay', () {
    testWidgets('shrinks and fades out on its own square', (
      WidgetTester tester,
    ) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 220),
      );
      addTearDown(progress.dispose);

      await tester.pumpWidget(
        _board(
          CapturedPieceOverlay(
            progress: progress,
            square: const BoardSquare(3, 2),
            child: _piece(),
          ),
        ),
      );

      final boardOrigin = tester.getTopLeft(find.byType(Stack));
      final expectedCentre =
          boardOrigin +
          const Offset(3 * _squareSize, 2 * _squareSize) +
          const Offset(25, 25);

      progress.value = 0.0;
      await tester.pump();
      expectOffsetCloseTo(
        tester.getCenter(find.byKey(_pieceKey)),
        expectedCentre,
        reason: 'starts on the square the victim stood on',
      );
      expect(_scaleOf(tester), closeTo(1.0, 0.001));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);

      progress.value = 0.5;
      await tester.pump();
      expect(_scaleOf(tester), lessThan(1.0), reason: 'shrinks away');
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1.0));

      progress.value = 1.0;
      await tester.pump();
      expect(_scaleOf(tester), lessThan(0.8));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.0);

      // A capture does not travel.
      expectOffsetCloseTo(
        tester.getCenter(find.byKey(_pieceKey)),
        expectedCentre,
      );
    });
  });


  testWidgets('FractionallySizedBox alignment does not position its child', (
    WidgetTester tester,
  ) async {
    // Documents why the overlays measure the board and compute pixel offsets
    // instead of using this pattern: the render object sizes itself to its
    // child, so there is no slack for `alignment` to resolve against and the
    // child stays pinned to the stack's origin.
    await tester.pumpWidget(
      _board(
        FractionallySizedBox(
          widthFactor: 0.125,
          heightFactor: 0.125,
          alignment: const Alignment(0.75, 0.5),
          child: _piece(),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_pieceKey)),
      tester.getTopLeft(find.byType(Stack)),
    );
  });
}
