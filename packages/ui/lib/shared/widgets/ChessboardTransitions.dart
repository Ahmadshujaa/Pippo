import 'package:flutter/material.dart';

import 'package:atlas_ui/shared/widgets/ChessboardMotion.dart';

/// Number of squares along one side of the board.
const int _kSquaresPerSide = 8;

/// A square in **display** coordinates: [file] `0..7` runs left to right and
/// [rank] `0..7` runs top to bottom, already flipped for the board's
/// orientation.
///
/// Working in display coordinates means the overlays never have to reason about
/// board orientation or algebraic notation again — they only interpolate
/// between two pixel offsets.
@immutable
class BoardSquare {
  const BoardSquare(this.file, this.rank)
    : assert(file >= 0 && file < _kSquaresPerSide),
      assert(rank >= 0 && rank < _kSquaresPerSide);

  /// Visual column, `0` = leftmost.
  final int file;

  /// Visual row, `0` = topmost.
  final int rank;

  /// Top-left offset of this square within a board whose squares are
  /// [squareSize] across.
  Offset topLeft(double squareSize) =>
      Offset(file * squareSize, rank * squareSize);

  @override
  bool operator ==(Object other) =>
      other is BoardSquare && other.file == file && other.rank == rank;

  @override
  int get hashCode => Object.hash(file, rank);
}

/// Measures the board and hands a one-square box to [builder].
///
/// The box is wrapped in an `Align` on purpose. Overlays live in a `Stack` with
/// `StackFit.expand`, which hands down **tight** constraints the size of the
/// whole board — and a child can never violate tight parent constraints, so a
/// bare `SizedBox(width: squareSize)` would be stretched to the full board and
/// the piece would be centred on the board instead of on its square. `Align`
/// calls `constraints.loosen()` before laying out its child, which lets the
/// one-square box keep the size we asked for.
///
/// `Align` also sizes itself to the board, so the caller can position the box
/// with a single `Transform.translate` in board coordinates.
@immutable
class _BoardSquareBox extends StatelessWidget {
  const _BoardSquareBox({
    required this.squareSize,
    required this.offset,
    required this.child,
  });

  final double squareSize;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: squareSize,
          height: squareSize,
          child: child,
        ),
      ),
    );
  }
}

/// Measures the board once per layout and exposes the size of a single square.
///
/// Sits above the `AnimatedBuilder` so the square size is recomputed on layout
/// changes only, never on animation ticks.
@immutable
class _BoardMeasurer extends StatelessWidget {
  const _BoardMeasurer({
    required this.builder,
  });

  final Widget Function(BuildContext context, double squareSize) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSize = constraints.biggest.width / _kSquaresPerSide;
        return builder(context, squareSize);
      },
    );
  }
}

/// A tile tint that fades in and out by animating **opacity only**.
///
/// The tint is a flat fill laid over the square's base colour, so the
/// transition is a compositor blend rather than a re-rasterisation of the
/// tile. Because the underlying `AnimatedOpacity` paints nothing while it is
/// fully transparent, an idle square costs no more than two render objects.
///
/// Each highlight is kept mounted for every square at all times so that it can
/// animate *out* when the selection moves elsewhere — removing the widget from
/// the tree would pop the tint off instantly instead of fading it.
class SquareHighlight extends StatelessWidget {
  const SquareHighlight({
    super.key,
    required this.active,
    required this.color,
    this.duration = ChessboardMotion.defaultHighlightDuration,
    this.curve = ChessboardMotion.highlightCurve,
  });

  /// Whether the tint should be fully visible.
  final bool active;

  /// The tint colour, including its own alpha.
  final Color color;

  /// How long the tint takes to fade in or out.
  final Duration duration;

  /// Easing applied to the fade.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: ColoredBox(color: color),
    );
  }
}

/// Plays a one-shot lift-and-settle pulse on a piece when it becomes selected.
///
/// The piece rises, then **returns to its original size and position** — it does
/// not stay enlarged while selected. The persistent selection cue is the tile
/// highlight ([SquareHighlight]); the pulse is the acknowledgement of the tap.
///
/// The piece subtree is handed to the internal `AnimatedBuilder` as a
/// pre-built child, so ticking the animation never rebuilds (and never
/// re-rasterises) the piece artwork — only the transform around it changes.
/// Once the pulse finishes the widget drops back to returning [child] directly,
/// leaving no wrapper in front of the piece at rest.
class SelectedPiecePulse extends StatefulWidget {
  const SelectedPiecePulse({
    super.key,
    required this.isSelected,
    required this.child,
    this.motion = ChessboardMotion.standard,
  });

  /// Whether the wrapped piece is the selected piece.
  final bool isSelected;

  /// The piece widget to pulse.
  final Widget child;

  /// Timing and amplitude for the pulse.
  final ChessboardMotion motion;

  @override
  State<SelectedPiecePulse> createState() => _SelectedPiecePulseState();
}

class _SelectedPiecePulseState extends State<SelectedPiecePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.motion.selectionPulseDuration,
    )..addStatusListener((status) {
      // Drop the AnimatedBuilder once the pulse has returned to rest.
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
    if (widget.isSelected) _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant SelectedPiecePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = widget.motion.selectionPulseDuration;
    if (oldWidget.motion.selectionPulseDuration != duration) {
      _controller.duration = duration;
    }
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Before the first pulse and after it settles there is nothing to animate,
    // so the piece is passed straight through with no wrapper at all.
    if (_controller.isDismissed || _controller.isCompleted) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Raw controller value: the envelope is symmetric, so easing it here
        // would skew the lift relative to the settle.
        final envelope = ChessboardMotion.pulseEnvelope(_controller.value);
        final scale =
            1.0 + (widget.motion.selectionPulseScale - 1.0) * envelope;
        final lift = -widget.motion.selectionPulseLift * envelope;
        return Transform.translate(
          offset: Offset(0.0, lift),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Flies a piece across the board from [from] to [to].
///
/// Two transforms are composed from a single animation value:
///
/// * **translation** along the straight line between the two square centres,
///   eased by [progress], and
/// * **scale** driven by [ChessboardMotion.pulseEnvelope], which peaks at the
///   mid-point so the piece swells as it leaves the board and settles flush
///   onto the target square.
///
/// Both are pure `Transform`s, so the flying piece costs one paint operation
/// per frame and its artwork is built exactly once.
class MovingPieceOverlay extends StatelessWidget {
  const MovingPieceOverlay({
    super.key,
    required this.progress,
    required this.from,
    required this.to,
    required this.child,
    this.motion = ChessboardMotion.standard,
  });

  /// Eased progress of the move, in the `0..1` range.
  final Animation<double> progress;

  /// Where the piece starts, in display coordinates.
  final BoardSquare from;

  /// Where the piece lands, in display coordinates.
  final BoardSquare to;

  /// The piece widget being moved.
  final Widget child;

  /// Timing, curve and amplitude for the flight.
  final ChessboardMotion motion;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _BoardMeasurer(
        builder: (context, squareSize) {
          final fromOffset = from.topLeft(squareSize);
          final toOffset = to.topLeft(squareSize);
          return AnimatedBuilder(
            animation: progress,
            child: child,
            builder: (context, child) {
              final t = progress.value;
              final envelope = ChessboardMotion.pulseEnvelope(t);
              final scale = 1.0 + (motion.movingPieceScale - 1.0) * envelope;
              return _BoardSquareBox(
                squareSize: squareSize,
                offset: Offset.lerp(fromOffset, toOffset, t)!,
                child: Transform.scale(scale: scale, child: child),
              );
            },
          );
        },
      ),
    );
  }
}

/// A brief, subtle ring that flashes on the square of a captured piece.
///
/// Complements the shrinking captured piece (see [CapturedPieceOverlay]): a
/// thin ring swells from a pinprick into a small dot mark as it fades out,
/// signalling *this square was taken* without re-rasterising any artwork —
/// only a compositor transform and blend run while it plays.
class CaptureFlash extends StatelessWidget {
  const CaptureFlash({
    super.key,
    required this.progress,
    required this.square,
    this.color = const Color(0xFFE15A4A),
    this.ringSize = 34,
    this.ringWidth = 3,
  });

  /// Eased progress of the capture, in the `0..1` range.
  final Animation<double> progress;

  /// The square being captured, in display coordinates.
  final BoardSquare square;

  /// Colour of the flash ring.
  final Color color;

  /// Diameter of the ring at full size, before it is scaled during the flash.
  final double ringSize;

  /// Stroke width of the ring.
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _BoardMeasurer(
        builder: (context, squareSize) {
          final offset = square.topLeft(squareSize);
          return AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final t = progress.value;
              // Grow from a pinprick towards the ring's full size while fading
              // out, so the marker is present for the whole capture but never
              // loud.
              final scale = 0.25 + 0.75 * t;
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              return _BoardSquareBox(
                squareSize: squareSize,
                offset: offset,
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: ringWidth),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shrinks and fades out a captured piece on its own square.
///
/// Runs under the incoming piece, which is drawn in a separate overlay above
/// it, so the capture reads as the defending piece being removed rather than
/// being snuffed out between frames.
class CapturedPieceOverlay extends StatelessWidget {
  const CapturedPieceOverlay({
    super.key,
    required this.progress,
    required this.square,
    required this.child,
    this.motion = ChessboardMotion.standard,
  });

  /// Eased progress of the capture, in the `0..1` range.
  final Animation<double> progress;

  /// The square the captured piece is standing on, in display coordinates.
  final BoardSquare square;

  /// The captured piece widget.
  final Widget child;

  /// Timing, curve and amplitude for the disappearance.
  final ChessboardMotion motion;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _BoardMeasurer(
        builder: (context, squareSize) {
          final offset = square.topLeft(squareSize);
          return AnimatedBuilder(
            animation: progress,
            child: child,
            builder: (context, child) {
              final t = progress.value;
              final scale =
                  1.0 - (1.0 - motion.capturedPieceScale) * t;
              return _BoardSquareBox(
                squareSize: squareSize,
                offset: offset,
                child: Opacity(
                  opacity: 1.0 - t,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
