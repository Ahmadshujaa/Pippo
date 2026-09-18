import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:chess/chess.dart' as chess;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:atlas_core/core/engine/ModelApiService.dart';

class PippoEngineService {
  static PippoEngineService? _instance;
  OrtSession? _session;
  OrtSessionOptions? _sessionOptions;
  bool _isLoaded = false;
  bool _envInitialized = false;
  bool _isInferencing = false;

  static const int policySize = 4672;
  static const int _numPlanes = 20;

  static const int minElo = 400;
  static const int maxElo = 3000;
  static const int eloStep = 50;

  /// Pippo samples from the model's three highest-scoring legal moves instead
  /// of always taking the single highest-scoring move. The model still
  /// determines the relative probability of those moves.
  static const int defaultTopK = 3;

  /// A value below 1 keeps the policy focused while allowing genuine variety
  /// when the model considers multiple moves plausible.
  static const double defaultTemperature = 0.65;

  final Random _random = Random();

  static const List<List<int>> _queenDirs = [
    [1, 0], [1, 1], [0, 1], [-1, 1],
    [-1, 0], [-1, -1], [0, -1], [1, -1],
  ];

  static const List<List<int>> _knightMoves = [
    [2, 1], [2, -1], [-2, 1], [-2, -1],
    [1, 2], [1, -2], [-1, 2], [-1, -2],
  ];

  PippoEngineService._();

  static PippoEngineService get instance {
    _instance ??= PippoEngineService._();
    return _instance!;
  }

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded && _session != null) return;

    if (!_envInitialized) {
      try {
        OrtEnv.instance.init();
      } catch (_) {}
      _envInitialized = true;
    }

    final modelPath = await ModelApiService.ensureModelFile();
    final modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      final docsDir = await getApplicationDocumentsDirectory();
      final fallbackFile = File('${docsDir.path}/BaseModel.onnx');
      if (await fallbackFile.exists()) {
        final bytes = await fallbackFile.readAsBytes();
        _sessionOptions?.release();
        _sessionOptions = OrtSessionOptions();
        _session?.release();
        _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
        _isLoaded = true;
        return;
      }
      throw Exception('Model file not found. Please download the model first.');
    }

    final bytes = await modelFile.readAsBytes();
    _sessionOptions?.release();
    _sessionOptions = OrtSessionOptions();
    _session?.release();
    _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
    _isLoaded = true;
  }

  void dispose() {
    _session?.release();
    _sessionOptions?.release();
    _session = null;
    _sessionOptions = null;
    _isLoaded = false;
  }

  // ── Board encoding (20 planes, matching Training_Notebook.txt) ──

  Float32List encodeBoard(chess.Chess game) {
    final planes = Float32List(_numPlanes * 64);
    final isBlackTurn = game.turn == chess.Chess.BLACK;

    // Piece type → plane index
    final pieceTypeMap = {
      chess.Chess.PAWN: 0,
      chess.Chess.KNIGHT: 1,
      chess.Chess.BISHOP: 2,
      chess.Chess.ROOK: 3,
      chess.Chess.QUEEN: 4,
      chess.Chess.KING: 5,
    };

    // Planes 0-11: piece placement
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final square = '${String.fromCharCode(97 + file)}${rank + 1}';
        final piece = game.get(square);
        if (piece == null) continue;

        final pieceIdx = pieceTypeMap[piece.type];
        if (pieceIdx == null) continue;

        int row = rank;
        if (isBlackTurn) row = 7 - row;

        if (piece.color == chess.Chess.WHITE) {
          planes[pieceIdx * 64 + row * 8 + file] = 1.0;
        } else {
          planes[(pieceIdx + 6) * 64 + row * 8 + file] = 1.0;
        }
      }
    }

    // If black's turn, swap white/black piece planes
    if (isBlackTurn) {
      for (int i = 0; i < 6 * 64; i++) {
        final tmp = planes[i];
        planes[i] = planes[6 * 64 + i];
        planes[6 * 64 + i] = tmp;
      }
    }

    // Planes 12-15: castling rights (perspective-adjusted)
    final fen = game.fen;
    final fenParts = fen.split(' ');
    final castling = fenParts[2];

    final wK = castling.contains('K') ? 1.0 : 0.0;
    final wQ = castling.contains('Q') ? 1.0 : 0.0;
    final bK = castling.contains('k') ? 1.0 : 0.0;
    final bQ = castling.contains('q') ? 1.0 : 0.0;

    if (isBlackTurn) {
      _fillPlane(planes, 12, bK);
      _fillPlane(planes, 13, bQ);
      _fillPlane(planes, 14, wK);
      _fillPlane(planes, 15, wQ);
    } else {
      _fillPlane(planes, 12, wK);
      _fillPlane(planes, 13, wQ);
      _fillPlane(planes, 14, bK);
      _fillPlane(planes, 15, bQ);
    }

    // Plane 16: en passant
    final ep = fenParts[3];
    if (ep != '-') {
      final epFile = ep.codeUnitAt(0) - 97;
      int epRank = int.parse(ep[1]) - 1;
      if (isBlackTurn) epRank = 7 - epRank;
      planes[16 * 64 + epRank * 8 + epFile] = 1.0;
    }

    // Plane 17: side to move (all 1s if white to move)
    if (!isBlackTurn) {
      _fillPlane(planes, 17, 1.0);
    }

    // Plane 18: halfmove clock (normalized /100)
    final halfmove = int.tryParse(fenParts[4]) ?? 0;
    _fillPlane(planes, 18, halfmove.clamp(0, 100) / 100.0);

    // Plane 19: fullmove number (normalized /200)
    final fullmove = int.tryParse(fenParts[5]) ?? 1;
    _fillPlane(planes, 19, fullmove.clamp(0, 200) / 200.0);

    return planes;
  }

  void _fillPlane(Float32List planes, int plane, double val) {
    final offset = plane * 64;
    for (int i = 0; i < 64; i++) {
      planes[offset + i] = val;
    }
  }

  // ── Move encoding (AlphaZero 73-plane) ──

  int moveToIndex(String from, String to, chess.Chess game, {String? promotion}) {
    final fromFile = from.codeUnitAt(0) - 97;
    final fromRank = int.parse(from[1]) - 1;
    final toFile = to.codeUnitAt(0) - 97;
    final toRank = int.parse(to[1]) - 1;

    int fromR = fromRank, fromC = fromFile;
    int toR = toRank, toC = toFile;

    // Flip ranks for black's perspective
    if (game.turn == chess.Chess.BLACK) {
      fromR = 7 - fromR;
      toR = 7 - toR;
    }

    final fromSq = fromR * 8 + fromC;
    final toSq = toR * 8 + toC;

    final dr = (toSq ~/ 8) - (fromSq ~/ 8);
    final dc = (toSq % 8) - (fromSq % 8);

    int plane = -1;
    final isUnderpromo = promotion != null &&
        promotion != 'q' &&
        (promotion == 'n' || promotion == 'b' || promotion == 'r');

    if (!isUnderpromo) {
      // Queen-like directions (planes 0-55)
      for (int i = 0; i < 8; i++) {
        for (int s = 1; s < 8; s++) {
          if (dr == _queenDirs[i][0] * s && dc == _queenDirs[i][1] * s) {
            plane = i * 7 + (s - 1);
            break;
          }
        }
        if (plane != -1) break;
      }

      // Knight moves (planes 56-63)
      if (plane == -1) {
        for (int i = 0; i < 8; i++) {
          if (dr == _knightMoves[i][0] && dc == _knightMoves[i][1]) {
            plane = 56 + i;
            break;
          }
        }
      }
    } else {
      // Underpromotion (planes 64-72)
      final promoIdx = promotion == 'n' ? 0 : (promotion == 'b' ? 1 : 2);
      plane = 64 + promoIdx * 3 + (dc + 1);
    }

    return fromSq * 73 + plane;
  }

  String indexToMove(int index, chess.Chess game) {
    final fromSqIdx = index ~/ 73;
    final plane = index % 73;

    int fromR = fromSqIdx ~/ 8;
    final fromC = fromSqIdx % 8;

    int dr, dc;
    String? promotion;

    if (plane < 56) {
      // Queen-like direction
      final dirIdx = plane ~/ 7;
      final dist = (plane % 7) + 1;
      dr = _queenDirs[dirIdx][0] * dist;
      dc = _queenDirs[dirIdx][1] * dist;
    } else if (plane < 64) {
      // Knight move
      final knightIdx = plane - 56;
      dr = _knightMoves[knightIdx][0];
      dc = _knightMoves[knightIdx][1];
    } else {
      // Underpromotion
      final promoPlane = plane - 64;
      final promoIdx = promoPlane ~/ 3;
      promotion = ['n', 'b', 'r'][promoIdx];
      dc = (promoPlane % 3) - 1;
      dr = 1;
    }

    int toR = fromR + dr;
    int toC = fromC + dc;

    // Unflip for black's turn
    if (game.turn == chess.Chess.BLACK) {
      fromR = 7 - fromR;
      toR = 7 - toR;
    }

    final fromFile = String.fromCharCode(97 + fromC);
    final fromRankStr = '${fromR + 1}';
    final toFile = String.fromCharCode(97 + toC);
    final toRankStr = '${toR + 1}';

    String uci = '$fromFile$fromRankStr$toFile$toRankStr';

    // Auto-promote to queen if a pawn reaches the back rank
    if (promotion == null && (toR == 0 || toR == 7)) {
      final piece = game.get('$fromFile$fromRankStr');
      if (piece != null && piece.type == chess.Chess.PAWN) {
        promotion = 'q';
      }
    }

    if (promotion != null) {
      uci += promotion;
    }

    return uci;
  }

  // ── Legal move mask ──

  Float32List getLegalMoveMask(chess.Chess game) {
    final mask = Float32List(policySize);
    final moves = game.generate_moves();

    for (final move in moves) {
      final idx = moveToIndex(
        move.fromAlgebraic,
        move.toAlgebraic,
        game,
        promotion: move.promotion?.name,
      );
      if (idx >= 0 && idx < policySize) {
        mask[idx] = 1.0;
      }
    }

    return mask;
  }

  // ── ELO normalization ──

  double normalizeElo(int elo) {
    return ((elo - 400.0) / 2600.0).clamp(0.0, 1.0);
  }

  // ── Inference ──

  /// Returns a move sampled from Pippo's policy distribution.
  ///
  /// The ONNX model is deterministic and returns logits for every move in its
  /// 4,672-entry policy space. This method performs the decoding step:
  ///
  /// 1. discard illegal moves;
  /// 2. keep only the model's [topK] legal candidates;
  /// 3. apply temperature-scaled softmax to those candidates; and
  /// 4. sample one candidate according to those probabilities.
  ///
  /// A [temperature] of zero uses a strict argmax. Positive temperatures must
  /// be finite. [topK] must be positive and is capped by the number of legal
  /// moves in the position.
  Future<String?> getBestMove(
    chess.Chess game,
    int elo, {
    double temperature = defaultTemperature,
    int topK = defaultTopK,
  }) async {
    if (!_isLoaded || _session == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    if (game.game_over) return null;
    if (_isInferencing) return null;

    _isInferencing = true;

    OrtValueTensor? boardTensor;
    OrtValueTensor? eloTensor;
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;

    try {
      final boardData = encodeBoard(game);
      final eloNorm = Float32List.fromList([normalizeElo(elo)]);

      boardTensor = OrtValueTensor.createTensorWithDataList(
        boardData,
        [1, _numPlanes, 8, 8],
      );
      eloTensor = OrtValueTensor.createTensorWithDataList(
        eloNorm,
        [1, 1],
      );

      final inputs = {'x': boardTensor, 'elo_norm': eloTensor};
      runOptions = OrtRunOptions();

      outputs = await _session!.runAsync(runOptions, inputs);

      if (outputs == null || outputs.isEmpty || outputs[0] == null) {
        throw Exception('No output from model');
      }

      // Extract policy logits from output tensor
      final rawOutput = outputs[0]!.value;
      final List<double> policyLogits = _extractPolicyLogits(rawOutput);
      if (policyLogits.length != policySize) {
        throw StateError(
          'Pippo returned ${policyLogits.length} policy values; '
          'expected $policySize',
        );
      }

      if (!temperature.isFinite || temperature < 0.0) {
        throw ArgumentError.value(
          temperature,
          'temperature',
          'must be finite and greater than or equal to zero',
        );
      }
      if (topK <= 0) {
        throw ArgumentError.value(topK, 'topK', 'must be greater than zero');
      }

      // Apply the legal move mask before ranking. Illegal moves must never
      // enter the sampling distribution, even if their model logit is high.
      final mask = getLegalMoveMask(game);
      final legalIndices = <int>[];
      for (int i = 0; i < policySize; i++) {
        if (mask[i] != 0.0 && policyLogits[i].isFinite) {
          legalIndices.add(i);
        } else {
          policyLogits[i] = double.negativeInfinity;
        }
      }

      if (legalIndices.isEmpty) {
        throw StateError('Pippo returned no finite score for a legal move');
      }

      final selectedIdx = _selectPolicyIndex(
        policyLogits,
        legalIndices,
        temperature: temperature,
        topK: topK,
      );
      return indexToMove(selectedIdx, game);
    } finally {
      if (outputs != null) {
        for (final output in outputs) {
          try {
            output?.release();
          } catch (_) {}
        }
      }
      try {
        boardTensor?.release();
      } catch (_) {}
      try {
        eloTensor?.release();
      } catch (_) {}
      try {
        runOptions?.release();
      } catch (_) {}
      _isInferencing = false;
    }
  }

  int _selectPolicyIndex(
    List<double> policyLogits,
    List<int> legalIndices, {
    required double temperature,
    required int topK,
  }) {
    // Sort only legal moves. The tie-break by index makes selection stable
    // when two logits are exactly equal, while the final sampling remains
    // stochastic for positive temperatures.
    final candidates = legalIndices.toList()
      ..sort((a, b) {
        final scoreOrder = policyLogits[b].compareTo(policyLogits[a]);
        return scoreOrder != 0 ? scoreOrder : a.compareTo(b);
      });

    final candidateCount = min(topK, candidates.length);
    final topCandidates = candidates.sublist(0, candidateCount);

    // Temperature zero is an explicit deterministic mode and avoids division
    // by zero. The candidates are already sorted by descending model score.
    if (temperature == 0.0 || topCandidates.length == 1) {
      return topCandidates.first;
    }

    // Stable softmax: subtracting the largest scaled logit prevents overflow
    // without changing the resulting probabilities.
    final maxLogit = policyLogits[topCandidates.first] / temperature;
    final weights = <double>[];
    var totalWeight = 0.0;
    for (final index in topCandidates) {
      final weight = exp(policyLogits[index] / temperature - maxLogit);
      weights.add(weight);
      totalWeight += weight;
    }

    // The logits were validated before reaching this method. Keep a safe
    // deterministic fallback for unexpected floating-point failures.
    if (!totalWeight.isFinite || totalWeight <= 0.0) {
      return topCandidates.first;
    }

    var threshold = _random.nextDouble() * totalWeight;
    for (int i = 0; i < topCandidates.length; i++) {
      threshold -= weights[i];
      if (threshold <= 0.0) return topCandidates[i];
    }

    // Rounding can leave a tiny remainder after the final bucket.
    return topCandidates.last;
  }

  List<double> _extractPolicyLogits(dynamic rawOutput) {
    if (rawOutput is List<List<double>>) {
      return List<double>.from(rawOutput[0]);
    }
    if (rawOutput is List<List<num>>) {
      return rawOutput[0].map((e) => e.toDouble()).toList();
    }
    if (rawOutput is List) {
      if (rawOutput.isNotEmpty && rawOutput[0] is List) {
        return (rawOutput[0] as List).map((e) => (e as num).toDouble()).toList();
      }
      return rawOutput.map((e) => (e as num).toDouble()).toList();
    }
    throw Exception('Unexpected output format: ${rawOutput.runtimeType}');
  }
}
