import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:atlas_core/core/games/GameStorageService.dart';
import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/engine/StockfishEngineService.dart';
import 'package:atlas_core/core/puzzles/UserPuzzleStorageService.dart';
import 'package:atlas_core/features/analysis/game_analyzer.dart';
import 'package:atlas_core/features/board/chessboard_controller.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One classified mainline move, checkpointed to disk as soon as it is done.
class _MoveRecord {
  final int ply;
  final String san;
  final String uci;
  final String fenBefore;
  final ClassificationResult result;

  const _MoveRecord({
    required this.ply,
    required this.san,
    required this.uci,
    required this.fenBefore,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'ply': ply,
        'san': san,
        'uci': uci,
        'fenBefore': fenBefore,
        'result': result.toJson(),
      };

  factory _MoveRecord.fromJson(Map<String, dynamic> json) => _MoveRecord(
        ply: (json['ply'] as num?)?.toInt() ?? 0,
        san: json['san']?.toString() ?? '',
        uci: json['uci']?.toString() ?? '',
        fenBefore: json['fenBefore']?.toString() ?? '',
        result: ClassificationResult.fromJson(
          json['result'] as Map<String, dynamic>? ?? {},
        ),
      );
}

/// Severity tag for background pipeline log lines. The in-app debug console
/// was removed after verification; these tags only decorate the lines sent
/// to the developer console (dev.log).
enum BackgroundPuzzleLogLevel { engine, game, move, puzzle, error, info }

/// Persisted mid-run progress for the game currently being analyzed.
class _Checkpoint {
  final int gameId;
  final List<_MoveRecord> records;

  const _Checkpoint({required this.gameId, required this.records});

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'records': records.map((r) => r.toJson()).toList(growable: false),
      };

  static _Checkpoint? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final gameId = (json['gameId'] as num?)?.toInt();
    if (gameId == null) return null;
    final records = <_MoveRecord>[];
    for (final entry in json['records'] as List<dynamic>? ?? []) {
      try {
        records.add(_MoveRecord.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        return null; // corrupt record -> discard the whole checkpoint
      }
    }
    return _Checkpoint(gameId: gameId, records: records);
  }
}

/// Classification labels that are converted into puzzles.
const Set<MoveClassification> _puzzleClassifications = {
  MoveClassification.inaccuracy,
  MoveClassification.mistake,
  MoveClassification.miss,
  MoveClassification.blunder,
};

/// Background puzzle generator.
///
/// Whenever the user finishes a game against Pippo, that game is stored via
/// [GameStorageService]. This service — completely invisible to the user —
/// runs a DEDICATED Stockfish process (its own `StockfishEngineService`
/// instance, separate from the UI singleton the Analysis screen and PippoPlayScreen
/// drive) and classifies every move of one game at a time, exactly the way
/// the Analysis screen's full-game run does (same `GameAnalyzer`, depth 13).
///
/// Guarantees:
/// - Runs on ANY screen and keeps going while the app is open. The engine is
///   a child process of the app, so if the OS kills the process everything
///   dies — therefore every finished move is CHECKPOINTED to disk and the
///   run cleanly RESUMES on the next app launch: it starts its engine, re
///   applies the persisted classifications to the move tree and lets
///   `GameAnalyzer`'s idempotent fast path skip them, so already-classified
///   moves are never re-classified.
/// - Only one game is analyzed at a time. When a game's classification is
///   complete, the sub-optimal USER moves (inaccuracy / mistake / miss /
///   blunder) are converted into puzzles — FEN before the move, the played
///   move, and Stockfish's best move — stored via
///   [UserPuzzleStorageService], and the game itself is DELETED (only the
///   puzzles remain).
/// - When the queue of saved games is empty the background engine process is
///   killed. If a game exists that needs analysis, the engine is started
///   fresh (lazily) for it.
class BackgroundPuzzleService extends ChangeNotifier {
  BackgroundPuzzleService._();

  static final BackgroundPuzzleService _instance = BackgroundPuzzleService._();
  static BackgroundPuzzleService get instance => _instance;

  static const String _checkpointKey = 'puzzle_analysis_checkpoint';
  static const int _startDelayMs = 5000;
  static const int _maxConsecutiveFailures = 3;

  SharedPreferences? _prefs;
  StockfishEngineService? _engine;
  bool _initialized = false;
  bool _isRunning = false;
  bool _cancelRequested = false;
  int _consecutiveFailures = 0;

  /// Whether a background classification run is currently active.
  bool get isRunning => _isRunning;

  /// Progress of the current game as (classified, total), or null when idle.
  (int, int)? progress;

  /// Logs to the developer console only.
  void _log(String message, {BackgroundPuzzleLogLevel level = BackgroundPuzzleLogLevel.info}) {
    dev.log('[BackgroundPuzzles][${level.name}] $message');
  }

  /// Must be awaited during app startup (Main.dart). Schedules the first run
  /// shortly after launch so the boot path is never slowed down: the engine
  /// is only ever started when a saved game actually needs analysis.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    await GameStorageService.init();
    await UserPuzzleStorageService.init();
    _log('Service initialized — first queue check scheduled in '
        '${_startDelayMs}ms.');
    Timer(const Duration(milliseconds: _startDelayMs), () {
      _log('Scheduled queue check firing (app startup).');
      _maybeStart();
    });
  }

  /// Called by PippoPlayScreen right after a finished game has been saved.
  /// Fire-and-forget by design; the caller does not need to await it.
  Future<void> onGameSaved(SavedGame game) async {
    _log('GAME FINISHED vs Pippo — queued for puzzle generation: '
        'game=${game.timestamp}, ${game.moves.length} moves, '
        'result=${game.result} (${game.resultType}), '
        'userColor=${game.playerColor}, elo=${game.elo}.',
        level: BackgroundPuzzleLogLevel.game);
    await init();
    _maybeStart();
  }

  /// Stops the current run. The checkpoint stays on disk, so the next
  /// trigger resumes from the first unclassified move.
  void cancel() {
    if (!_isRunning) return;
    _cancelRequested = true;
    _log('CANCEL requested — run will stop at the next await point and '
        'resume later from the checkpoint.',
        level: BackgroundPuzzleLogLevel.game);
  }

  // =========================================================================
  // QUEUE / RUN LOOP
  // =========================================================================

  Future<void> _maybeStart() async {
    if (_isRunning) return;
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _log('Too many consecutive failures ($_consecutiveFailures) — '
          'waiting for the next game-finished trigger to retry.',
          level: BackgroundPuzzleLogLevel.error);
      return;
    }

    // Defensive lazy init: a game-finished trigger can arrive before the
    // delayed startup init() has completed its awaits.
    _prefs ??= await SharedPreferences.getInstance();
    await GameStorageService.init();
    await UserPuzzleStorageService.init();

    // Re-read storage so a game that was saved microseconds ago is visible.
    final checkpoint = _loadCheckpoint();
    final games = GameStorageService.getGames();
    _log('Queue check: ${games.length} game(s) waiting, '
        '${UserPuzzleStorageService.getPuzzleCount()} puzzle(s) stored'
        '${checkpoint != null ? ', checkpoint for game ${checkpoint.gameId} '
            '(${checkpoint.records.length} moves done)' : ''}.');
    if (games.isEmpty) {
      _log('Queue empty — nothing to analyze.',
          level: BackgroundPuzzleLogLevel.game);
      return;
    }

    // Prefer the checkpointed (partially analyzed) game; otherwise the
    // oldest saved game is next in the queue.
    SavedGame target;
    bool isContinuation;
    if (checkpoint != null) {
      final match = games
          .where((g) => g.timestamp == checkpoint.gameId)
          .toList(growable: false);
      if (match.isNotEmpty) {
        target = match.first;
        isContinuation = true;
      } else {
        // Checkpointed game was already deleted — stale checkpoint.
        _log('Checkpoint references game ${checkpoint.gameId} which no '
            'longer exists in storage — clearing stale checkpoint.',
            level: BackgroundPuzzleLogLevel.game);
        await _clearCheckpoint();
        target = games.first;
        isContinuation = false;
      }
    } else {
      target = games.first;
      isContinuation = false;
    }

    _log(isContinuation
            ? 'CONTINUING classification of game ${target.timestamp} '
                '(${checkpoint!.records.length}/${_countMoves(target)} moves '
                'already classified) — will resume at the first '
                'unclassified move.'
            : 'STARTING NEW classification for game ${target.timestamp} '
                '(${_countMoves(target)} moves) — queue position '
                '${games.indexOf(target) + 1} of ${games.length}.',
        level: BackgroundPuzzleLogLevel.game);

    _isRunning = true;
    _cancelRequested = false;
    progress = null;
    notifyListeners();

    try {
      await _processGame(target, checkpoint);
      _consecutiveFailures = 0;
    } catch (e, stack) {
      _consecutiveFailures++;
      _log('Run FAILED ($_consecutiveFailures consecutive): $e\n$stack',
          level: BackgroundPuzzleLogLevel.error);
    } finally {
      _isRunning = false;
      progress = null;
      notifyListeners();

      // No games left to analyze -> kill the background engine process so
      // only the UI-shared singleton (if in use) remains running.
      if (GameStorageService.getGames().isEmpty) {
        _log('Queue is now empty — CLOSING the dedicated background '
            'Stockfish instance.',
            level: BackgroundPuzzleLogLevel.engine);
        try {
          _engine?.dispose();
        } catch (_) {}
        _engine = null;
      } else {
        _log('More games are waiting — background Stockfish instance stays '
            'open for the next game.',
            level: BackgroundPuzzleLogLevel.engine);
      }
    }

    // Continue with the next queued game, if any.
    if (!_cancelRequested) {
      _maybeStart();
    }
  }

  /// Cheap move count for logging (replays SAN without building FENs).
  int _countMoves(SavedGame game) =>
      game.moves.where((m) => m.trim().isNotEmpty).length;

  // =========================================================================
  // SINGLE GAME PIPELINE
  // =========================================================================

  Future<void> _processGame(SavedGame game, _Checkpoint? checkpoint) async {
    // 1. Rebuild the FEN sequence by replaying the stored SAN moves.
    final List<String> fens;
    try {
      fens = _buildFenSequence(game.moves);
    } catch (e) {
      _log('Game ${game.timestamp} has INVALID move data ($e) — deleting it '
          'and its checkpoint to keep the queue moving.',
          level: BackgroundPuzzleLogLevel.error);
      await GameStorageService.deleteGameByTimestamp(game.timestamp);
      await _clearCheckpoint();
      return;
    }
    _log('Game ${game.timestamp} rebuilt from SAN: ${fens.length - 1} moves '
        '→ ${fens.length} FEN positions.',
        level: BackgroundPuzzleLogLevel.game);

    // 2. Headless move tree (no UI anywhere near this pipeline).
    final controller = ChessboardController();
    controller.loadGame(fens);
    final mainline = _extractMainline(controller);
    _log('Move tree ready: ${mainline.length} mainline node(s).',
        level: BackgroundPuzzleLogLevel.game);

    // 3. Resume: re-apply persisted classifications so GameAnalyzer's
    //    idempotent fast path skips them without re-classifying.
    final nodeIndex = <MoveNode, int>{};
    for (int i = 0; i < mainline.length; i++) {
      nodeIndex[mainline[i]] = i;
    }

    final records = <int, _MoveRecord>{};
    if (checkpoint != null && checkpoint.gameId == game.timestamp) {
      var valid = true;
      for (final record in checkpoint.records) {
        if (record.ply >= mainline.length ||
            mainline[record.ply].san != record.san) {
          valid = false; // game data changed under us — restart cleanly
          break;
        }
        records[record.ply] = record;
        controller.updateClassificationForNode(mainline[record.ply],
            record.result);
      }
      if (!valid) {
        records.clear();
        for (final node in mainline) {
          node.classification = null;
        }
        _log('Checkpoint MISMATCHED the rebuilt move tree — discarding it '
            'and re-classifying the whole game from move 1.',
            level: BackgroundPuzzleLogLevel.game);
      } else {
        _log('Re-applied ${records.length} checkpointed classification(s) — '
            'no already-classified move will be re-classified.',
            level: BackgroundPuzzleLogLevel.game);
      }
    } else {
      _log('No usable checkpoint for game ${game.timestamp} — classifying '
          'from move 1.',
          level: BackgroundPuzzleLogLevel.game);
    }

    // 4. Fully classified already (crash between classify-complete and
    //    extraction, or resume right after the last move)? Extract only.
    if (mainline.isNotEmpty && records.length >= mainline.length) {
      _log('Game ${game.timestamp} is ALREADY fully classified '
          '(${records.length}/${mainline.length}) — skipping straight to '
          'puzzle extraction.',
          level: BackgroundPuzzleLogLevel.game);
      await _extractPuzzlesAndFinish(game, records, mainline);
      return;
    }

    if (mainline.isEmpty) {
      _log('Game ${game.timestamp} has NO moves — deleting it without '
          'puzzles so the queue keeps moving.',
          level: BackgroundPuzzleLogLevel.game);
      await GameStorageService.deleteGameByTimestamp(game.timestamp);
      await _clearCheckpoint();
      return;
    }

    // 5. Start the dedicated background engine fresh, only now that a game
    //    actually needs analysis.
    if (_engine == null) {
      _log('OPENING dedicated background Stockfish instance (separate from '
          'the UI singleton)...',
          level: BackgroundPuzzleLogLevel.engine);
    }
    try {
      _engine ??= StockfishEngineService();
      await _engine!.start();
    } catch (e) {
      _log('FAILED to start the background Stockfish instance: $e',
          level: BackgroundPuzzleLogLevel.error);
      rethrow;
    }
    _log('Background Stockfish instance READY — classifying '
        '${mainline.length - records.length} remaining move(s) of game '
        '${game.timestamp} at depth 13.',
        level: BackgroundPuzzleLogLevel.engine);

    // 6. Run the exact same sequential classifier the Analysis screen uses,
    //    but driven through the dedicated engine instance. Every finished
    //    move is checkpointed to disk the moment it is classified.
    final analyzer = GameAnalyzer(controller: controller, engineOverride: _engine);
    await analyzer.analyze(
      mainline: mainline,
      depth: 13,
      onProgress: (node, done, total) {
        progress = (done.round(), total.round());
        final index = nodeIndex[node];
        if (index != null &&
            node.hasClassification &&
            !records.containsKey(index)) {
          final record = _MoveRecord(
            ply: index,
            san: node.san,
            uci: _uciFor(node),
            fenBefore: node.parent?.fen ?? controller.root.fen,
            result: node.classification!,
          );
          records[index] = record;
          _persistCheckpoint(game.timestamp, records);
          _log('Move ${index + 1}/$total classified: ${node.san} '
              '(${record.uci}) → ${record.result.classification.name}'
              '${record.result.loss > 0
                  ? ' (loss ${record.result.loss.toStringAsFixed(3)}, '
                      'best ${record.result.bestMove})'
                  : ''} — checkpoint saved.',
              level: BackgroundPuzzleLogLevel.move);
        }
        notifyListeners();
      },
      isCanceled: () => _cancelRequested,
    );

    if (_cancelRequested) {
      _log('Run stopped by cancel — game ${game.timestamp} keeps its '
          'checkpoint (${records.length}/${mainline.length} moves done) and '
          'will be resumed on the next trigger.',
          level: BackgroundPuzzleLogLevel.game);
      return;
    }

    // 7. Convert the classified game into puzzles and delete the game.
    await _extractPuzzlesAndFinish(game, records, mainline);
  }

  // =========================================================================
  // EXTRACTION
  // =========================================================================

  Future<void> _extractPuzzlesAndFinish(
    SavedGame game,
    Map<int, _MoveRecord> records,
    List<MoveNode> mainline,
  ) async {
    final userIsWhite = game.playerColor.toLowerCase() == 'white';
    final puzzles = <UserPuzzle>[];

    for (int ply = 0; ply < mainline.length; ply++) {
      final record = records[ply];
      if (record == null) continue;
      if (!_puzzleClassifications.contains(record.result.classification)) {
        continue;
      }
      // Only the user's own mistakes become puzzles: the puzzle position
      // must have the USER to move.
      final moverIsWhite = ply.isEven;
      if (moverIsWhite != userIsWhite) continue;

      final bestMove = record.result.bestMove.trim();
      if (bestMove.length < 4 || bestMove == '0000') continue;

      final puzzle = UserPuzzle(
        id: 'up_${game.timestamp}_$ply',
        fen: record.fenBefore,
        bestMove: bestMove,
        playedMove: record.result.playedMoveUci ?? record.uci,
        classification: record.result.classification.name,
        loss: record.result.loss,
        playerColor: game.playerColor,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      puzzles.add(puzzle);
      _log('Puzzle candidate from move ${ply + 1}: type='
          '${puzzle.classification}, userPlayed=${puzzle.playedMove}, '
          'best=${puzzle.bestMove}, loss=${puzzle.loss.toStringAsFixed(3)}, '
          'fen=${puzzle.fen}.',
          level: BackgroundPuzzleLogLevel.puzzle);
    }

    if (puzzles.isNotEmpty) {
      await UserPuzzleStorageService.addPuzzles(puzzles);
      _log('${puzzles.length} puzzle(s) stored from game ${game.timestamp} '
          '(total stored now: '
          '${UserPuzzleStorageService.getPuzzleCount()}).',
          level: BackgroundPuzzleLogLevel.puzzle);
    } else {
      _log('No puzzle-worthy mistakes found in game ${game.timestamp}.',
          level: BackgroundPuzzleLogLevel.puzzle);
    }

    // Only the puzzles remain — the game itself is deleted.
    _log('Deleting game ${game.timestamp} from storage — only its puzzles '
        'remain.',
        level: BackgroundPuzzleLogLevel.game);
    await GameStorageService.deleteGameByTimestamp(game.timestamp);
    await _clearCheckpoint();
    _log('Game ${game.timestamp} COMPLETE: ${puzzles.length} puzzle(s) '
        'extracted, game and checkpoint deleted.',
        level: BackgroundPuzzleLogLevel.game);
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Replays the SAN move list from the initial position, returning the FEN
  /// of every position along the way (start position included).
  List<String> _buildFenSequence(List<String> sanMoves) {
    final board = chess.Chess();
    final fens = <String>[board.fen];
    for (final san in sanMoves) {
      final clean = san.trim();
      if (clean.isEmpty) continue;
      if (!board.move(clean)) {
        throw FormatException('illegal/unparseable SAN move: "$clean"');
      }
      fens.add(board.fen);
    }
    return fens;
  }

  List<MoveNode> _extractMainline(ChessboardController controller) {
    final mainline = <MoveNode>[];
    MoveNode? current =
        controller.root.children.isEmpty ? null : controller.root.children.first;
    while (current != null) {
      mainline.add(current);
      current = current.children.isEmpty ? null : current.children.first;
    }
    return mainline;
  }

  String _uciFor(MoveNode node) {
    final move = node.move;
    if (move == null) return '';
    return '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
  }

  _Checkpoint? _loadCheckpoint() {
    final raw = _prefs?.getString(_checkpointKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return _Checkpoint.tryParse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistCheckpoint(
    int gameId,
    Map<int, _MoveRecord> records,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    final ordered = (records.keys.toList()..sort())
        .map((ply) => records[ply]!)
        .toList(growable: false);
    final checkpoint = _Checkpoint(gameId: gameId, records: ordered);
    await _prefs!.setString(_checkpointKey, jsonEncode(checkpoint.toJson()));
  }

  Future<void> _clearCheckpoint() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_checkpointKey);
    _log('Checkpoint cleared.', level: BackgroundPuzzleLogLevel.game);
  }
}
