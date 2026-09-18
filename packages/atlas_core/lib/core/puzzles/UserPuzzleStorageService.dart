import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single tactic puzzle extracted from the user's own games against Pippo.
///
/// Each puzzle is the position right before a sub-optimal move the user
/// played; the solution is the move Stockfish recommended instead.
class UserPuzzle {
  final String id;
  final String fen;
  final String bestMove;
  final String playedMove;
  final String classification;
  final double loss;
  final String playerColor;
  final int createdAt;

  UserPuzzle({
    required this.id,
    required this.fen,
    required this.bestMove,
    required this.playedMove,
    required this.classification,
    required this.loss,
    required this.playerColor,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fen': fen,
        'bestMove': bestMove,
        'playedMove': playedMove,
        'classification': classification,
        'loss': loss,
        'playerColor': playerColor,
        'createdAt': createdAt,
      };

  factory UserPuzzle.fromJson(Map<String, dynamic> json) => UserPuzzle(
        id: json['id']?.toString() ?? '',
        fen: json['fen']?.toString() ?? '',
        bestMove: json['bestMove']?.toString() ?? '',
        playedMove: json['playedMove']?.toString() ?? '',
        classification: json['classification']?.toString() ?? 'mistake',
        loss: (json['loss'] as num?)?.toDouble() ?? 0.0,
        playerColor: json['playerColor']?.toString() ?? 'white',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

/// Local persistence for puzzles generated from the user's Pippo games.
///
/// Follows the same static-SharedPreferences pattern as
/// [LocalPuzzleService] / GameStorageService. The stored puzzle count is
/// what the Puzzles screen shows as "Puzzles Remaining". Completed puzzles
/// are DELETED immediately upon being solved — only unsolved puzzles are
/// ever kept on disk.
class UserPuzzleStorageService {
  static const String _key = 'user_puzzles';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static List<UserPuzzle> getPuzzles() {
    if (_prefs == null) return [];
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => UserPuzzle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static int getPuzzleCount() => getPuzzles().length;

  /// Appends [puzzles], skipping any whose FEN is already stored so the same
  /// position can never appear twice in the feed.
  static Future<void> addPuzzles(List<UserPuzzle> puzzles) async {
    await init();
    if (puzzles.isEmpty) return;
    final existing = getPuzzles();
    final knownFens = existing.map((p) => p.fen).toSet();
    for (final puzzle in puzzles) {
      if (knownFens.contains(puzzle.fen)) continue;
      knownFens.add(puzzle.fen);
      existing.add(puzzle);
    }
    await _write(existing);
  }

  /// Deletes a puzzle once it has been solved — completed puzzles do not
  /// stay on disk. Returns true when a puzzle was removed.
  static Future<bool> deletePuzzle(String id) async {
    await init();
    final puzzles = getPuzzles();
    final remaining = puzzles.where((p) => p.id != id).toList();
    if (remaining.length == puzzles.length) return false;
    await _write(remaining);
    return true;
  }

  static Future<void> clearAll() async {
    await init();
    await _prefs!.remove(_key);
  }

  static Future<void> _write(List<UserPuzzle> puzzles) async {
    final encoded =
        jsonEncode(puzzles.map((p) => p.toJson()).toList(growable: false));
    await _prefs!.setString(_key, encoded);
  }
}