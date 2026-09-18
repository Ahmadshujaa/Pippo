import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;

import 'engine_models.dart';

/// Outcome of processing a single engine output line.
///
/// The parser is a pure state machine: it consumes raw UCI output and, when a
/// publish warrants it, produces an [AnalysisResult]. The service layer is
/// responsible for routing these to the UI stream.
class StockfishParseOutcome {
  /// Non-null when this line should be published to analysis subscribers.
  final AnalysisResult? publish;

  /// True when `bestmove` was seen for an active search, so the driver can
  /// clear its "search active" bookkeeping.
  final bool searchEnded;

  /// Search generation associated with this outcome. The engine service uses
  /// it to prevent an old worker message from clearing the bookkeeping for a
  /// newer search.
  final int generation;

  const StockfishParseOutcome({
    this.publish,
    this.searchEnded = false,
    this.generation = 0,
  });
}

/// The complete Stockfish output parsing state machine, extracted so it can
/// run inside a background worker isolate.
///
/// Historically this code lived inside `StockfishEngineService` and ran on
/// the UI isolate, where the *cheap-looking* per-line work (FEN parsing +
/// legal-move generation for the PV-legality check) ran hundreds of times per
/// second and starved the render thread on low-end devices.
///
/// This class is pure Dart (no Flutter, no I/O) and deliberately mirrors the
/// old logic exactly â€” same publish conditions, same throttle math, same SAN
/// conversion â€” so the service can switch between running it inline (fallback)
/// or inside an isolate without any behavioural change.
class StockfishOutputParser {
  int _currentDepth = 0;
  int _lastPublishedDepth = -1;
  int _configuredLines = 3;
  final Map<int, AnalysisLine> _currentLines = {};
  final Map<int, int> _currentLineDepths = {};
  final Map<int, String> _currentPvs = {};
  final Map<int, double> _currentScores = {};
  final Map<int, bool> _currentMates = {};

  int _minDepth = 6;
  int _depthInterval = 3;

  int _currentLegalMoves = 0;

  bool _isSynchronizing = false;
  String? _lastFen;
  int _searchGeneration = 0;
  int? _targetDepth;
  bool _targetPublished = false;

  /// Cache of PV-start legality results. The first UCI move of a PV changes
  /// surprisingly often as the search iterates, but re-verifying the SAME
  /// (fen, firstMove) pair via FEN parsing + legal-move generation on every
  /// line is pure waste. Bounded LRU-style Map keyed by `fen|firstMove`.
  final Map<String, bool> _pvStartCache = {};

  void configure({int? lines, int? minDepth, int? depthInterval}) {
    if (lines != null) _configuredLines = lines.clamp(1, 3);
    if (minDepth != null) _minDepth = minDepth;
    if (depthInterval != null) _depthInterval = math.max(1, depthInterval);
  }

  /// Called when a new search is started (the driver has already sent
  /// `stop` / `position` / `isready`). Resets the state machine and computes
  /// the legal-move count that drives the "all lines reached the milestone"
  /// wait.
  void beginSearch(
    String fen, {
    int generation = 0,
    int? targetDepth,
  }) {
    try {
      final game = chess.Chess.fromFEN(fen);
      _currentLegalMoves = game.generate_moves().length;
    } catch (_) {
      _currentLegalMoves = 3; // Fallback
    }

    _currentDepth = 0;
    _lastPublishedDepth = -1;
    _currentLines.clear();
    _currentLineDepths.clear();
    _currentPvs.clear();
    _currentScores.clear();
    _currentMates.clear();
    _pvStartCache.clear();
    _searchGeneration = generation;
    _targetDepth = targetDepth;
    _targetPublished = false;

    _isSynchronizing = true;
    _lastFen = null;
  }

  /// Called when the engine acknowledges readiness for the pending search
  /// (`readyok` handled by the driver). Tags output as belonging to [fen] and
  /// lets `info` lines flow again.
  void resumeSearch(String fen, {int? generation}) {
    _lastFen = fen;
    if (generation != null) _searchGeneration = generation;
    _isSynchronizing = false;
  }

  StockfishParseOutcome handleLine(String rawLine) {
    final String line = rawLine.trim();

    if (line.startsWith('info ')) {
      return _handleInfo(line);
    }
    if (line.startsWith('bestmove ')) {
      return _handleBestMove();
    }
    return const StockfishParseOutcome();
  }

  StockfishParseOutcome _handleInfo(String line) {
    if (_isSynchronizing || _lastFen == null) {
      return const StockfishParseOutcome();
    }

    final List<String> parts = line.split(' ');
    int? depth;
    int? multipv;
    double? score;
    bool isMate = false;
    String? pv;

    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'depth') {
        if (i + 1 < parts.length) depth = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'multipv') {
        if (i + 1 < parts.length) multipv = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'score') {
        if (i + 1 < parts.length && parts[i + 1] == 'cp') {
          score = double.tryParse(parts[i + 2]) ?? 0.0;
        } else if (i + 1 < parts.length && parts[i + 1] == 'mate') {
          final mateVal = int.tryParse(parts[i + 2]) ?? 0;
          score = mateVal.toDouble();
          isMate = true;
        }
      } else if (parts[i] == 'pv') {
        pv = parts.sublist(i + 1).join(' ');
        break;
      }
    }

    if (depth != null && multipv != null && score != null && pv != null) {
      if (depth > _currentDepth) {
        _currentDepth = depth;
      }

      // Cheap sanity check: only the FIRST PV move needs to be legal from the
      // current position. Full PV->SAN conversion is deferred to publish time
      // (_buildLinesForPublish), so a stale PV is rejected without walking the
      // whole PV on every "info" line.
      if (!_isPvStartLegal(_lastFen!, pv)) {
        return const StockfishParseOutcome();
      }

      _currentLineDepths[multipv] = depth;
      _currentPvs[multipv] = pv;
      _currentScores[multipv] = score;
      _currentMates[multipv] = isMate;

      // --- ADAPTIVE MILESTONE LOGIC ---
      const targetMilestone = 13;
      final linesToWait = math.min(_currentLegalMoves, _configuredLines);

      // Condition A: All expected lines have hit D13.
      bool allLinesReady = true;
      for (int i = 1; i <= linesToWait; i++) {
        if ((_currentLineDepths[i] ?? 0) < targetMilestone) {
          allLinesReady = false;
          break;
        }
      }

      // Condition B: Line 1 is already significantly deeper (D16), don't wait
      // for stragglers.
      final bool line1Stable = (_currentLineDepths[1] ?? 0) >= 16;

      final bool isMilestoneDepth =
          (allLinesReady || line1Stable) && _lastPublishedDepth < targetMilestone;
      final bool isThrottlePass =
          depth >= _minDepth && (depth - _minDepth) % _depthInterval == 0;
      final bool isNewDepth = depth > _lastPublishedDepth;

      final bool allLinesReadyAtTarget =
          _targetDepth != null && _allExpectedLinesAtDepth(_targetDepth!);
      final bool shouldPublish =
          isMilestoneDepth ||
          (isThrottlePass && isNewDepth) ||
          (allLinesReadyAtTarget && !_targetPublished);

      if (shouldPublish) {
        _lastPublishedDepth = math.max(_lastPublishedDepth, depth);
        if (allLinesReadyAtTarget) _targetPublished = true;
        return StockfishParseOutcome(
          generation: _searchGeneration,
          publish: _buildResult(
            depth,
            _currentScores[1] ?? score,
            _currentMates[1] ?? isMate,
            isFinal: false,
          ),
        );
      }
    }
    return const StockfishParseOutcome();
  }

  StockfishParseOutcome _handleBestMove() {
    // Search is complete. Trigger a final result if we haven't reached the
    // milestone yet, provided we have at least SOME depth.
    if (_lastFen != null && _currentDepth > 0 && !_targetPublished) {
      return StockfishParseOutcome(
        searchEnded: true,
        generation: _searchGeneration,
        publish: _buildResult(
          _currentDepth,
          _currentScores[1] ?? 0,
          _currentMates[1] ?? false,
          isFinal: true,
        ),
      );
    }
    return StockfishParseOutcome(
      searchEnded: true,
      generation: _searchGeneration,
    );
  }

  bool _allExpectedLinesAtDepth(int targetDepth) {
    final linesToWait = math.min(_currentLegalMoves, _configuredLines);
    for (int i = 1; i <= linesToWait; i++) {
      if ((_currentLineDepths[i] ?? 0) < targetDepth) return false;
    }
    return linesToWait > 0;
  }

  AnalysisResult _buildResult(
    int depth,
    double score,
    bool isMate, {
    bool isFinal = false,
  }) {
    chess.Color turn = chess.Color.WHITE;
    final fen = _lastFen;
    if (fen != null) {
      try {
        final game = chess.Chess.fromFEN(fen);
        turn = game.turn;
      } catch (_) {}
    }
    return AnalysisResult(
      fen: fen ?? '',
      depth: depth,
      evaluation: score,
      isMate: isMate,
      generation: _searchGeneration,
      lines: _buildLinesForPublish(),
      turn: turn,
      lineDepths: Map<int, int>.from(_currentLineDepths),
      isFinal: isFinal,
    );
  }

  /// Builds the [AnalysisLine] list for publication. SAN conversion is
  /// deferred to this point: doing it per raw "info" line would burn CPU for
  /// lines the throttle never publishes.
  ///
  /// Lines whose PV has gone stale since the last successful conversion
  /// retain the previously cached [AnalysisLine] so the UI never shows a
  /// skeleton for a transient glitch in the engine's output.
  List<AnalysisLine> _buildLinesForPublish() {
    final fen = _lastFen;
    if (fen == null) return const [];

    final sortedKeys = _currentPvs.keys.toList()..sort();
    final lines = <AnalysisLine>[];
    for (final k in sortedKeys) {
      final existing = _currentLines[k];
      final pv = _currentPvs[k]!;
      final sanMoves = _convertToSan(fen, pv);
      if (sanMoves != null) {
        final line = AnalysisLine(
          moves: sanMoves,
          rawPv: pv,
          eval: _formatEval(_currentScores[k] ?? 0, _currentMates[k] ?? false),
          isPrimary: k == 1,
        );
        _currentLines[k] = line;
        lines.add(line);
      } else if (existing != null) {
        lines.add(existing);
      }
    }
    return lines;
  }

  /// Fast PV-start legality check: only the first UCI move needs to be legal
  /// from [fen]. Results are cached for the duration of a search because the
  /// engine frequently re-emits the same leading move across depth iterations.
  bool _isPvStartLegal(String fen, String pv) {
    final firstMove = pv.split(' ').first;
    if (firstMove.length < 4) return false;

    final cacheKey = '$fen|$firstMove';
    final cached = _pvStartCache[cacheKey];
    if (cached != null) return cached;

    bool legal = false;
    try {
      final game = chess.Chess.fromFEN(fen);
      final from = firstMove.substring(0, 2);
      final to = firstMove.substring(2, 4);
      final promotion = firstMove.length > 4 ? firstMove.substring(4, 5) : null;
      for (final m in game.generate_moves()) {
        if (m.fromAlgebraic == from &&
            m.toAlgebraic == to &&
            (m.promotion == null || m.promotion!.name == promotion)) {
          legal = true;
          break;
        }
      }
    } catch (_) {
      legal = false;
    }

    if (_pvStartCache.length >= 32) _pvStartCache.clear();
    _pvStartCache[cacheKey] = legal;
    return legal;
  }

  String _formatEval(double score, bool isMate) {
    if (isMate) return 'M${score.toInt().abs()}';
    final val = score / 100.0;
    return val > 0 ? '+$val' : val.toString();
  }

  String? _convertToSan(String fen, String pv) {
    try {
      final game = chess.Chess.fromFEN(fen);
      final uciMoves = pv.split(' ');
      final sanMoves = <String>[];

      for (int i = 0; i < uciMoves.length; i++) {
        final uci = uciMoves[i];
        if (uci.isEmpty) continue;

        if (uci.length < 4) {
          sanMoves.add(uci);
          continue;
        }

        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promotion = uci.length > 4 ? uci.substring(4, 5) : null;

        final legalMoves = game.generate_moves();
        chess.Move? moveObj;
        for (final m in legalMoves) {
          if (m.fromAlgebraic == from &&
              m.toAlgebraic == to &&
              (m.promotion == null || m.promotion?.name == promotion)) {
            moveObj = m;
            break;
          }
        }

        if (moveObj != null) {
          sanMoves.add(game.move_to_san(moveObj));
          game.make_move(moveObj);
        } else {
          // If any move in the PV is illegal for the current FEN, the entire
          // PV is invalid (likely stale). Discard it to prevent UI flickering.
          return null;
        }
      }
      return sanMoves.join(' ');
    } catch (e) {
      dev.log('Error converting PV to SAN: $e');
      return null;
    }
  }
}
