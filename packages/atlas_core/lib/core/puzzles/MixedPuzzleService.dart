import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atlas_core/core/auth/AuthService.dart';
import 'package:atlas_core/core/user/UserProfileService.dart';

class MixedPuzzle {
  final String id;
  final String fen;
  final String? lastMove;
  final String? fenBeforeLastMove;
  final List<String> solution;
  final String theme;
  final int rating;
  final bool completed;

  MixedPuzzle({
    required this.id,
    required this.fen,
    this.lastMove,
    this.fenBeforeLastMove,
    required this.solution,
    required this.theme,
    this.rating = 1500,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fen': fen,
    'lastMove': lastMove,
    'fenBeforeLastMove': fenBeforeLastMove,
    'solution': solution,
    'theme': theme,
    'rating': rating,
    'completed': completed,
  };

  factory MixedPuzzle.fromJson(Map<String, dynamic> json) {
    return MixedPuzzle(
      id: json['id'] as String? ?? '',
      fen: json['fen'] as String? ?? '',
      lastMove: json['lastMove'] as String?,
      fenBeforeLastMove: json['fenBeforeLastMove'] as String?,
      solution: (json['solution'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      theme: json['theme'] as String? ?? 'mix',
      rating: (json['rating'] as num?)?.toInt() ?? 1500,
      completed: json['completed'] as bool? ?? false,
    );
  }

  MixedPuzzle copyWith({bool? completed}) {
    return MixedPuzzle(
      id: id,
      fen: fen,
      lastMove: lastMove,
      fenBeforeLastMove: fenBeforeLastMove,
      solution: List<String>.from(solution),
      theme: theme,
      rating: rating,
      completed: completed ?? this.completed,
    );
  }
}

class MixedPuzzleService {
  static const String _kRatingKey = 'mixed_puzzle_rating';
  static const String _kBatchKey = 'mixed_puzzle_batch_v2';
  static const String _kCurrentIndexKey = 'mixed_puzzle_current_index';

  /// Default rating for a brand-new player (no stored value yet).
  static const int initialRating = 400;
  static const int _kInitialRating = initialRating;
  static const int _kRatingDelta = 15;
  static const int _kBatchSize = 20;
  static const int _kRatingWindow = 400;

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // Rating
  // ---------------------------------------------------------------------------

  static Future<int> getRating() async {
    await _ensurePrefs();
    return _prefs!.getInt(_kRatingKey) ?? _kInitialRating;
  }

  static Future<void> setRating(int rating) async {
    await _ensurePrefs();
    final clamped = rating < 100 ? 100 : rating;
    await _prefs!.setInt(_kRatingKey, clamped);
  }

  static Future<int> adjustRating({required bool perfect}) async {
    final current = await getRating();
    final next = perfect ? current + _kRatingDelta : current - _kRatingDelta;
    await setRating(next);
    final clamped = next < 100 ? 100 : next;
    // Mirror to the account in the background — solving a puzzle must not wait
    // on a network round trip.
    unawaited(_pushRatingToAccount(clamped));
    return clamped;
  }

  // ---------------------------------------------------------------------------
  // Account mirror (Supabase `profiles.puzzle_rating`)
  // ---------------------------------------------------------------------------
  // The shared-preferences value above stays the working copy, so offline play,
  // guests and every existing caller behave exactly as before. When the user is
  // signed in, Supabase keeps a per-account copy that survives reinstalls and
  // follows them across devices: the HIGHER of the two values is kept and
  // written back to whichever side was behind.

  /// Merges the local rating with the signed-in account's stored
  /// `puzzle_rating` and returns the effective rating. Returns the local value
  /// untouched for guests and when offline.
  static Future<int> syncWithAccount() async {
    final local = await getRating();
    final userId = AuthService.userId;
    if (userId == null) return local;

    final remote = await UserProfileService.getPuzzleRating(userId);
    if (remote == null) {
      // Nothing usable on the server yet (or the read failed) — seed it.
      await UserProfileService.setPuzzleRating(userId, local);
      return local;
    }

    if (remote <= local) {
      if (remote != local) {
        await UserProfileService.setPuzzleRating(userId, local);
      }
      return local;
    }

    await setRating(remote);
    return remote;
  }

  /// Fire-and-forget mirror of [rating] onto the signed-in user's profile.
  static Future<void> _pushRatingToAccount(int rating) async {
    final userId = AuthService.userId;
    if (userId == null) return;
    await UserProfileService.setPuzzleRating(userId, rating);
  }

  // ---------------------------------------------------------------------------
  // Batch persistence
  // ---------------------------------------------------------------------------

  static Future<List<MixedPuzzle>> getBatch() async {
    await _ensurePrefs();
    final raw = _prefs!.getString(_kBatchKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => MixedPuzzle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBatch(List<MixedPuzzle> batch) async {
    await _ensurePrefs();
    final encoded = jsonEncode(batch.map((p) => p.toJson()).toList());
    await _prefs!.setString(_kBatchKey, encoded);
  }

  static Future<void> clearBatch() async {
    await _ensurePrefs();
    await _prefs!.remove(_kBatchKey);
    await _prefs!.remove(_kCurrentIndexKey);
  }

  static Future<void> markCompleted(String puzzleId) async {
    final batch = await getBatch();
    bool changed = false;
    final updated = batch.map((p) {
      if (p.id == puzzleId && !p.completed) {
        changed = true;
        return p.copyWith(completed: true);
      }
      return p;
    }).toList();
    if (changed) {
      await saveBatch(updated);
    }
  }

  static Future<int> getCurrentIndex() async {
    await _ensurePrefs();
    return _prefs!.getInt(_kCurrentIndexKey) ?? 0;
  }

  static Future<void> setCurrentIndex(int index) async {
    await _ensurePrefs();
    await _prefs!.setInt(_kCurrentIndexKey, index);
  }

  static Future<bool> isBatchCompleted() async {
    final batch = await getBatch();
    if (batch.isEmpty) return true;
    return batch.every((p) => p.completed);
  }

  // ---------------------------------------------------------------------------
  // Turso DB — fetch a batch of mixed puzzles within the rating window
  // ---------------------------------------------------------------------------

  static Future<List<MixedPuzzle>> fetchBatchFromTurso({
    int? ratingOverride,
    int count = _kBatchSize,
  }) async {
    final rating = ratingOverride ?? await getRating();
    final dbUrl = dotenv.env['TURSO_DB_URL'];
    final dbToken = dotenv.env['TURSO_DB_TOKEN'];
    if (dbUrl == null || dbUrl.isEmpty || dbToken == null || dbToken.isEmpty) {
      throw Exception(
        'Turso DB credentials (TURSO_DB_URL / TURSO_DB_TOKEN) missing from .env',
      );
    }

    final minRating = rating - _kRatingWindow;
    final maxRating = rating + _kRatingWindow;

    final sql =
        'SELECT id, fen, moves, rating, themes FROM puzzles '
        'WHERE rating BETWEEN ? AND ? '
        'ORDER BY RANDOM() LIMIT $count';

    final body = jsonEncode({      'requests': [
        {
          'type': 'execute',
          'stmt': {
            'sql': sql,
            'args': [
              {'type': 'integer', 'value': '$minRating'},
              {'type': 'integer', 'value': '$maxRating'},
            ],
          },
        },
      ],
    });

    final response = await http.post(
      Uri.parse('$dbUrl/v2/pipeline'),
      headers: {
        'Authorization': 'Bearer $dbToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Turso DB error: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      throw Exception('Turso DB returned no results');
    }

    final first = results.first as Map<String, dynamic>;
    if (first['type'] != 'ok') {
      final err = first['error'];
      throw Exception('Turso DB query failed: ${err ?? first}');
    }

    final responseObj = first['response'] as Map<String, dynamic>?;
    final result = responseObj?['result'] as Map<String, dynamic>?;
    final rows = result?['rows'] as List<dynamic>? ?? [];

    final puzzles = <MixedPuzzle>[];
    for (final row in rows) {
      try {
        final parsed = _parseTursoRow(row as List<dynamic>);
        if (parsed != null) puzzles.add(parsed);
      } catch (_) {
        // Skip malformed rows
      }
    }

    if (puzzles.isEmpty) {
      throw Exception(
        'No puzzles found within rating range $minRating-$maxRating',
      );
    }

    return puzzles.take(count).toList();
  }

  /// Parses a Turso typed row cell into a plain string value.
  static String _cellValue(dynamic cell) {
    if (cell is Map<String, dynamic>) {
      return cell['value']?.toString() ?? '';
    }
    return cell?.toString() ?? '';
  }

  /// Parses one Turso row (id, fen, moves, rating, themes) into a MixedPuzzle.
  static MixedPuzzle? _parseTursoRow(List<dynamic> row) {
    if (row.length < 5) return null;

    final id = _cellValue(row[0]);
    final fen = _cellValue(row[1]);
    final moves = _cellValue(row[2]);
    final rating = int.tryParse(_cellValue(row[3])) ?? 1500;
    final themesRaw = _cellValue(row[4]);

    if (id.isEmpty || fen.isEmpty || moves.isEmpty) return null;

    final solution = moves
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .map((m) => m.toLowerCase())
        .toList();
    if (solution.isEmpty) return null;

    String theme = 'mix';
    try {
      final decoded = jsonDecode(themesRaw) as List<dynamic>? ?? [];
      if (decoded.isNotEmpty) theme = decoded.first.toString();
    } catch (_) {
      // Invalid themes JSON — fall back to 'mix'
    }

    return MixedPuzzle(
      id: id,
      fen: fen,
      solution: solution,
      theme: theme,
      rating: rating,
    );
  }

  // ---------------------------------------------------------------------------
  // Batch lifecycle
  // ---------------------------------------------------------------------------

  static Future<List<MixedPuzzle>> fetchAndSaveNewBatch({
    int count = _kBatchSize,
  }) async {
    final rating = await getRating();
    final newBatch = await fetchBatchFromTurso(
      ratingOverride: rating,
      count: count,
    );
    await clearBatch();
    await saveBatch(newBatch);
    await setCurrentIndex(0);
    return newBatch;
  }

  static Future<List<MixedPuzzle>> ensureBatch({int count = _kBatchSize}) async {
    final existing = await getBatch();
    if (existing.isNotEmpty) {
      final hasUncompleted = existing.any((p) => !p.completed);
      if (hasUncompleted) return existing;
    }
    return await fetchAndSaveNewBatch(count: count);
  }

  /// IDs of unsolved mixed Turso puzzles currently retained on this device.
  static Future<Set<String>> getUnsolvedPuzzleIds() async {
    final batch = await getBatch();
    return batch.where((p) => !p.completed).map((p) => p.id).toSet();
  }
}
