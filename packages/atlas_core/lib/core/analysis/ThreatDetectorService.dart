import 'package:atlas_core/core/analysis/MoveClassificationService.dart';

/// Stockfish-free detector for material-winning captures threatened by the
/// side that just played a move.
///
/// The input is intentionally limited to the position before the move and
/// the move itself. The detector applies the move, gives the next turn back to
/// the mover, and uses the advanced SEE/material routine shared with brilliant
/// move detection to find profitable captures.
class ThreatDetectorService {
  const ThreatDetectorService._();

  static List<ThreatArrow> detect({
    required String fenBefore,
    required String moveUci,
  }) {
    return BrilliantMoveEngine.findThreats(
      fenBefore: fenBefore,
      moveUci: moveUci,
    );
  }
}
