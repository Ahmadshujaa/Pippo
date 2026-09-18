import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_core/core/analysis/ThreatDetectorService.dart';

void main() {
  test('does not invent black threats after the opening e4 e5', () {
    // Position after 1.e4, before Black plays 1...e5. After applying e5,
    // Black has no capturable white piece and therefore no threats.
    const afterE4 =
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';

    final threats = ThreatDetectorService.detect(
      fenBefore: afterE4,
      moveUci: 'e7e5',
    );

    expect(threats, isEmpty);
  });

  test('finds a material-winning capture opened by the played move', () {
    // White moves Ba2-b3, uncovering Ra1xa8 against the black queen. Black is
    // the side to move in the resulting position, so the detector temporarily
    // gives the move back to White and reports the red threat arrow.
    const fenBefore = 'q3k3/8/8/8/8/8/B7/R3K3 w - - 0 1';

    final threats = ThreatDetectorService.detect(
      fenBefore: fenBefore,
      moveUci: 'a2b3',
    );

    expect(
      threats.any(
        (threat) =>
            threat.fromSquare == 'a1' &&
            threat.toSquare == 'a8' &&
            threat.materialGain >= 800,
      ),
      isTrue,
    );
  });

  test('detects the mirrored threat after a black move', () {
    const fenBefore = 'r3k3/b7/8/8/8/8/8/q3K3 b - - 0 1';

    final threats = ThreatDetectorService.detect(
      fenBefore: fenBefore,
      moveUci: 'a7b6',
    );

    expect(
      threats.any(
        (threat) =>
            threat.fromSquare == 'a8' &&
            threat.toSquare == 'a1' &&
            threat.materialGain >= 800,
      ),
      isTrue,
    );
  });

  test('does not report quiet moves or non-profitable captures', () {
    const fenBefore = '4k3/8/8/8/8/8/B7/R3K3 w - - 0 1';

    final threats = ThreatDetectorService.detect(
      fenBefore: fenBefore,
      moveUci: 'a2b3',
    );

    expect(threats, isEmpty);
  });
}
