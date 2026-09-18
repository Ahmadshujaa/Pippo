import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motion specification for the chessboard.
///
/// Every animated value on the board reads its timing, curve and amplitude
/// from a single [ChessboardMotion], so the whole board can be retuned — or
/// silenced for users who asked for reduced motion — from one place.
///
/// The board only ever animates two kinds of property:
///
/// * **opacity** — tile highlight tints fade in, captured pieces fade out.
/// * **transform** — a selected piece pulses, a moving piece flies, a captured
///   piece shrinks.
///
/// Both are resolved on the compositor, so no tile and no piece artwork is
/// re-rasterised while an animation is running. This keeps the board smooth on
/// low-end devices even though 64 squares are on screen.
@immutable
class ChessboardMotion {
  const ChessboardMotion({
    this.moveDuration = defaultMoveDuration,
    this.captureDuration = defaultCaptureDuration,
    this.selectionPulseDuration = defaultSelectionPulseDuration,
    this.highlightDuration = defaultHighlightDuration,
    this.movingPieceScale = defaultMovingPieceScale,
    this.capturedPieceScale = defaultCapturedPieceScale,
    this.selectionPulseScale = defaultSelectionPulseScale,
    this.selectionPulseLift = defaultSelectionPulseLift,
  });

  /// Baseline preset used by [ChessBoard].
  static const ChessboardMotion standard = ChessboardMotion();

  // --- Durations -----------------------------------------------------------

  /// Time a piece takes to travel from its origin square to its target square.
  static const Duration defaultMoveDuration = Duration(milliseconds: 320);

  /// Time a captured piece takes to shrink and fade away.
  ///
  /// Deliberately shorter than [defaultMoveDuration] so the capture clears
  /// before the arriving piece lands on the square.
  static const Duration defaultCaptureDuration = Duration(milliseconds: 220);

  /// Time a selected piece takes to complete its lift-and-settle pulse.
  static const Duration defaultSelectionPulseDuration = Duration(
    milliseconds: 340,
  );

  /// Time a tile takes to fade its highlight tint in or out.
  static const Duration defaultHighlightDuration = Duration(
    milliseconds: 170,
  );

  // --- Amplitudes ----------------------------------------------------------

  /// Peak scale of a piece at the mid-point of its flight, returning to `1.0`
  /// as it lands.
  static const double defaultMovingPieceScale = 1.18;

  /// Scale a captured piece shrinks to as it fades out.
  static const double defaultCapturedPieceScale = 0.72;

  /// Peak scale of a selected piece during its pulse. The piece returns to
  /// `1.0` when the pulse finishes — it does not stay enlarged while selected.
  static const double defaultSelectionPulseScale = 1.16;

  /// Peak upward travel of a selected piece during its pulse, in logical
  /// pixels.
  static const double defaultSelectionPulseLift = 7.0;

  /// How long a piece takes to travel to its target square.
  final Duration moveDuration;

  /// How long a captured piece takes to shrink and fade away.
  final Duration captureDuration;

  /// How long a selected piece takes to complete its pulse.
  final Duration selectionPulseDuration;

  /// How long a tile takes to fade its highlight tint in or out.
  final Duration highlightDuration;

  /// Peak scale of a piece at the mid-point of its flight.
  final double movingPieceScale;

  /// Scale a captured piece shrinks to as it fades out.
  final double capturedPieceScale;

  /// Peak scale of a selected piece during its pulse.
  final double selectionPulseScale;

  /// Peak upward travel of a selected piece during its pulse.
  final double selectionPulseLift;

  // --- Curves --------------------------------------------------------------

  /// Flight easing: accelerates away from the origin, then decelerates firmly
  /// into the target square so the landing reads as deliberate.
  static const Curve moveCurve = Cubic(0.42, 0.00, 0.22, 1.00);

  /// Captured pieces leave quickly and fade out, so an ease-out is enough.
  static const Curve captureCurve = Cubic(0.30, 0.00, 0.60, 1.00);

  /// Symmetric ease used by the tile highlight fades.
  static const Curve highlightCurve = Cubic(0.40, 0.00, 0.20, 1.00);

  /// A one-shot "there and back" envelope: `0` at both ends, `1` at the
  /// mid-point.
  ///
  /// Everything that should peak and then return to rest is driven by this —
  /// the flight scale (piece swells mid-air, lands flush) and the selection
  /// pulse (piece lifts, settles back to its original size).
  ///
  /// The underlying animation value runs `0 -> 1` linearly so the envelope
  /// stays symmetric; easing, where it is wanted, is applied to the
  /// translation instead.
  static double pulseEnvelope(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return math.sin(math.pi * clamped);
  }

  /// Resolves the motion tokens for [context], honouring the platform's
  /// "reduce motion" accessibility setting.
  ///
  /// Board widgets should read their tokens from here in
  /// `didChangeDependencies` so the value stays stable across ordinary
  /// rebuilds.
  static ChessboardMotion of(BuildContext context) =>
      standard.reduced(MediaQuery.disableAnimationsOf(context));

  /// Returns a copy with every duration collapsed to zero when
  /// [disableAnimations] is `true`.
  ///
  /// Animations then resolve in a single frame instead of a timed transition,
  /// but still land on the correct visual state — so a user with reduced motion
  /// enabled gets a fully functional board, just without the movement.
  ChessboardMotion reduced(bool disableAnimations) {
    if (!disableAnimations) return this;
    return ChessboardMotion(
      moveDuration: Duration.zero,
      captureDuration: Duration.zero,
      selectionPulseDuration: Duration.zero,
      highlightDuration: Duration.zero,
      movingPieceScale: movingPieceScale,
      capturedPieceScale: capturedPieceScale,
      selectionPulseScale: selectionPulseScale,
      selectionPulseLift: selectionPulseLift,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChessboardMotion &&
      other.moveDuration == moveDuration &&
      other.captureDuration == captureDuration &&
      other.selectionPulseDuration == selectionPulseDuration &&
      other.highlightDuration == highlightDuration &&
      other.movingPieceScale == movingPieceScale &&
      other.capturedPieceScale == capturedPieceScale &&
      other.selectionPulseScale == selectionPulseScale &&
      other.selectionPulseLift == selectionPulseLift;

  @override
  int get hashCode => Object.hash(
    moveDuration,
    captureDuration,
    selectionPulseDuration,
    highlightDuration,
    movingPieceScale,
    capturedPieceScale,
    selectionPulseScale,
    selectionPulseLift,
  );
}
