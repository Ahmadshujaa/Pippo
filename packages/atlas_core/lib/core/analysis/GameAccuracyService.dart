import 'dart:math' as math;

/// Provides the exact Lichess accuracy calculation formulas.
/// This service calculates the 0-100% game accuracy for both White and Black
/// using volatility-weighted means and harmonic means, mirroring Lichess's 
/// AccuracyPercent.scala logic.
class GameAccuracyService {
  // Private constructor to prevent instantiation
  GameAccuracyService._();

  /// Calculates the full game accuracy for White and Black.
  /// 
  /// [isStartWhite]: True if White made the first move of the game, false if Black started.
  /// [winPercents]: A list of Win Percentages (scaled 0.0 to 100.0, from WHITE'S perspective) 
  /// for the starting position and after every subsequent half-move.
  /// 
  /// Returns a Map with 'white' and 'black' accuracy percentages (0.0 - 100.0).
  static Map<String, double> calculateGameAccuracy(bool isStartWhite, List<double> winPercents) {
    final int n = winPercents.length;
    if (n < 2) return {'white': 0.0, 'black': 0.0};

    final List<double> weights = _calculateWeights(winPercents);
    
    final List<double> whiteWeighted = [];
    final List<double> whiteWeights = [];
    final List<double> whiteAccuracies = [];
    
    final List<double> blackWeighted = [];
    final List<double> blackWeights = [];
    final List<double> blackAccuracies = [];

    for (int i = 0; i < n - 1; i++) {
      final double p = winPercents[i];
      final double nVal = winPercents[i + 1];
      final double weight = i < weights.length ? weights[i] : 0.5;
      
      // Determine whose move it is based on start color and move index
      final bool isWhiteMove = ((i % 2 == 0) == isStartWhite);
      
      // Lichess cleverly swaps 'before' and 'after' for Black to avoid 100-x math
      final double before = isWhiteMove ? p : nVal;
      final double after = isWhiteMove ? nVal : p;
      
      final double accuracy = _calculateMoveAccuracy(before, after);
      
      if (isWhiteMove) {
        whiteWeighted.add(accuracy * weight);
        whiteWeights.add(weight);
        whiteAccuracies.add(accuracy);
      } else {
        blackWeighted.add(accuracy * weight);
        blackWeights.add(weight);
        blackAccuracies.add(accuracy);
      }
    }

    final double whiteScore = _calculateFinalScore(whiteWeighted, whiteWeights, whiteAccuracies);
    final double blackScore = _calculateFinalScore(blackWeighted, blackWeights, blackAccuracies);

    return {
      'white': whiteScore,
      'black': blackScore,
    };
  }

  /// Calculates move-by-move accuracy using the exact Lichess exponential decay curve.
  static double _calculateMoveAccuracy(double before, double after) {
    // If the move maintained or improved the position, it's 100% accurate.
    if (after >= before) return 100.0;
    
    final double winDiff = before - after;
    
    // The exact Lichess curve-fit constants derived via scipy.optimize
    final double raw = 103.1668100711649 * math.exp(-0.04354415386753951 * winDiff) - 3.166924740191411;
    final double withBonus = raw + 1.0; // uncertainty bonus (due to imperfect analysis)
    
    return withBonus.clamp(0.0, 100.0);
  }

  /// Generates volatility weights using sliding windows of standard deviation.
  /// High volatility (chaotic position) = higher weight (mistakes are more understandable).
  static List<double> _calculateWeights(List<double> winPercents) {
    final int n = winPercents.length;
    final int cpsSize = n - 1;
    
    // Lichess calculates window size dynamically based on game length, clamped between 2 and 8
    int windowSize = (cpsSize / 10).round().clamp(2, 8);
    final int effectiveWindowSize = math.min(windowSize, n);
    
    // Prepend padding logic exactly matches Lichess's sliding window alignment
    final int prependCount = math.max(0, effectiveWindowSize - 2);
    
    final List<double> weights = [];
    
    // Prepend copies of the first window to align with move count
    if (effectiveWindowSize > 0) {
      final firstWindow = winPercents.sublist(0, effectiveWindowSize);
      final double firstStdDev = _standardDeviation(firstWindow);
      for (int i = 0; i < prependCount; i++) {
        weights.add(firstStdDev);
      }
    }
    
    // Generate sliding windows
    if (effectiveWindowSize <= n) {
      for (int i = 0; i <= n - effectiveWindowSize; i++) {
        final window = winPercents.sublist(i, i + effectiveWindowSize);
        weights.add(_standardDeviation(window));
      }
    }
    
    // Safety padding in case of edge cases
    while (weights.length < n - 1) {
      weights.add(weights.isEmpty ? 0.5 : weights.last);
    }
    
    return weights;
  }

  /// Calculates population standard deviation, clamped to [0.5, 12.0] exactly as in Lichess.
  static double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0.5;
    
    final double mean = values.reduce((a, b) => a + b) / values.length;
    
    // Calculate variance avoiding Dart's num vs double type-casting issues with math.pow
    final double variance = values.map((x) {
      final double diff = x - mean;
      return diff * diff;
    }).reduce((a, b) => a + b) / values.length;
    
    final double stdDev = math.sqrt(variance);
    
    return stdDev.clamp(0.5, 12.0);
  }

  /// Blends the weighted mean and harmonic mean to form the final score.
  static double _calculateFinalScore(List<double> weightedAcc, List<double> weights, List<double> plainAcc) {
    if (plainAcc.isEmpty) return 0.0;
    
    final double weightedMean = _weightedMean(weightedAcc, weights);
    final double harmonicMean = _harmonicMean(plainAcc);
    
    // The final accuracy is the average of these two means
    final double finalScore = (weightedMean + harmonicMean) / 2.0;
    return finalScore.clamp(0.0, 100.0);
  }

  static double _weightedMean(List<double> weightedValues, List<double> weights) {
    if (weights.isEmpty) return 0.0;
    final double sumWeights = weights.reduce((a, b) => a + b);
    if (sumWeights == 0) return 0.0;
    final double sumWeighted = weightedValues.reduce((a, b) => a + b);
    return sumWeighted / sumWeights;
  }

  /// Harmonic mean is highly sensitive to outliers. 
  /// This ensures one massive blunder heavily penalizes the final score.
  static double _harmonicMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    double sum = 0;
    for (final v in values) {
      if (v <= 0) return 0.0; // A single 0 accuracy tanks the harmonic mean entirely
      sum += 1.0 / v;
    }
    return values.length / sum;
  }
}