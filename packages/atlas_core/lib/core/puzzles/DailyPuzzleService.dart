import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_core/core/integrations/MongoService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/puzzles/MixedPuzzleService.dart';

/// The "Daily Puzzle": one hard puzzle that stays the same for the whole
/// calendar day.
///
/// A day is the LOCAL calendar date (`yyyy-MM-dd`), so every timezone gets a
/// fresh puzzle the moment *its* midnight passes instead of waiting on UTC.
/// All players who share a date label share the puzzle, which is resolved in
/// this order:
///
///   1. the device's cache for today (no network at all);
///   2. the shared `daily_puzzles` document in MongoDB — the first signed-in
///      player to open the app on a new day writes it (fen, solution, rating,
///      themes); a device with no account never writes it;
///   3. if MongoDB has nothing for today *and* this device is the first one up
///      (or Mongo is unreachable), the puzzle is picked from the high-rated end
///      of the Turso mirror and then published to MongoDB for everybody else.
///
/// The Turso pick is DETERMINISTIC for a given day — the day's index into the
/// id-ordered set of puzzles above the rating floor — so client 3 always lands
/// on the same puzzle even when two devices race to publish it, and nobody ends
/// up playing a different board for the same day.
class DailyPuzzleService {
  /// Rating floors tried in order, hardest first.
  ///
  /// The daily puzzle should be a real challenge, but a partial mirror of the
  /// Lichess DB has far fewer 2200+ puzzles than the full set, so we walk down
  /// to 2000 and then 1800 and use the first floor that actually has puzzles.
  /// Every tier is still clearly above average play.
  static const List<int> minRatingTiers = [2200, 2000, 1800];

  /// Shared collection of daily puzzles, one document per day.
  static const String collectionName = 'daily_puzzles';

  static const String _kPuzzleKey = 'daily_puzzle_v1';
  static const String _kSolvedDayKey = 'daily_puzzle_solved_day';

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Today's puzzle, from the local cache when it was already fetched today.
  /// Pass [forceRefresh] to skip the cache and re-resolve it from the shared
  /// record.
  static Future<MixedPuzzle> getDailyPuzzle({bool forceRefresh = false}) async {
    await _ensurePrefs();
    final today = _stamp(DateTime.now());

    if (!forceRefresh) {
      final cached = _readCachedPuzzle(today);
      if (cached != null) return cached;
    }

    final puzzle = await _resolveForDay(today);
    await _cachePuzzle(today, puzzle);
    return puzzle;
  }

  /// Mongo first, Turso (+ publish) only for the player who starts a new day.
  static Future<MixedPuzzle> _resolveForDay(String day) async {
    final stored = await _findStored(day);
    if (stored != null) return stored;

    final dayNumber = _dayNumberOf(day);
    final puzzle = await _fetchHardPuzzle(dayNumber);
    await _publish(day, dayNumber, puzzle);
    return puzzle;
  }

  static Future<void> _cachePuzzle(String day, MixedPuzzle puzzle) async {
    await _prefs!.setString(
      _kPuzzleKey,
      jsonEncode({'day': day, 'puzzle': puzzle.toJson()}),
    );
  }

  /// True when today's puzzle has already been solved on this device.
  static Future<bool> isSolvedToday() async {
    await _ensurePrefs();
    return _prefs!.getString(_kSolvedDayKey) == _stamp(DateTime.now());
  }

  /// Records today's puzzle as solved (local only — the daily puzzle is a
  /// fixed challenge, so it never moves the practice rating).
  static Future<void> markSolvedToday() async {
    await _ensurePrefs();
    await _prefs!.setString(_kSolvedDayKey, _stamp(DateTime.now()));
  }

  // ---------------------------------------------------------------------------
  // Daily selection
  // ---------------------------------------------------------------------------

  static MixedPuzzle? _readCachedPuzzle(String today) {
    final raw = _prefs!.getString(_kPuzzleKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['day'] != today) return null;
      final puzzle = decoded['puzzle'];
      if (puzzle is! Map<String, dynamic>) return null;
      final parsed = MixedPuzzle.fromJson(puzzle);
      return parsed.id.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  /// Walk the rating floors, hardest first, and return the puzzle at the
  /// deterministic offset for today's date.
  static Future<MixedPuzzle> _fetchHardPuzzle(int dayNumber) async {
    Object? lastError;
    for (final minRating in minRatingTiers) {
      try {
        final count = await _countAtOrAbove(minRating);
        if (count <= 0) continue;

        // Same day index → same offset → same puzzle for everyone today.
        final offset = dayNumber % count;
        final rows = await _query(
          'SELECT id, fen, moves, rating, themes FROM puzzles '
          'WHERE rating >= ? ORDER BY id LIMIT 1 OFFSET ?',
          ['$minRating', '$offset'],
        );
        final puzzle = _firstPuzzle(rows);
        if (puzzle != null) return puzzle;
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'No daily puzzle available'
      '${lastError == null ? '' : ' ($lastError)'}',
    );
  }

  static Future<int> _countAtOrAbove(int minRating) async {
    final rows = await _query(
      'SELECT COUNT(*) FROM puzzles WHERE rating >= ?',
      ['$minRating'],
    );
    if (rows.isEmpty || rows.first.isEmpty) return 0;
    return int.tryParse(_cellValue(rows.first.first)) ?? 0;
  }

  /// Days since the epoch for a `yyyy-MM-dd` label. Derived from the label (not
  /// from "now") so two devices on the same date label always compute the same
  /// offset, whatever their clock or timezone.
  static int _dayNumberOf(String day) {
    final parts = day.split('-');
    if (parts.length != 3) return 0;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return 0;
    return DateTime.utc(y, m, d).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  // ---------------------------------------------------------------------------
  // MongoDB — the shared record of the day's puzzle
  // ---------------------------------------------------------------------------
  // One document per day, keyed by the local date label. The first player up on
  // a new day writes it; everyone else reads it. Both directions are
  // best-effort: with Mongo unreachable the deterministic Turso pick still gives
  // this device a sensible puzzle instead of an error screen.

  static Future<MixedPuzzle?> _findStored(String day) async {
    try {
      return await MongoService.withRetry(() async {
        final coll = await MongoService.collection(collectionName);
        final doc = await coll.findOne(where.eq('day', day));
        return doc == null ? null : _fromMongoDoc(Map<String, dynamic>.from(doc));
      });
    } catch (e) {
      AppLogger.warn('[DailyPuzzleService] Mongo read failed: $e');
      return null;
    }
  }

  static Future<void> _publish(
      String day, int dayNumber, MixedPuzzle puzzle) async {
    // Publishing the day's record is a shared write, so it is reserved for
    // signed-in players. Guests still get the same deterministic Turso pick (see
    // [_dayNumberOf]); the first signed-in launch publishes it for everyone.
    try {
      await MongoService.withSignedInRetry(() async {
        final coll = await MongoService.collection(collectionName);
        // Upsert on `day`: the first signed-in player to open the app on a new
        // day creates the record, and a second player racing them just re-writes
        // the same deterministic puzzle rather than duplicating the day.
        await coll.updateOne(
          where.eq('day', day),
          <String, dynamic>{
            r'$set': _toMongoDoc(day, dayNumber, puzzle),
          },
          upsert: true,
        );
      });
    } catch (e) {
      AppLogger.warn('[DailyPuzzleService] Mongo publish failed: $e');
    }
  }

  /// Same shape as the local/Turso puzzle rows (`fen`, `moves`, `rating`,
  /// `themes`) plus the day key and the parsed solution list.
  static Map<String, dynamic> _toMongoDoc(
          String day, int dayNumber, MixedPuzzle puzzle) =>
      {
        'day': day,
        'day_number': dayNumber,
        'puzzle_id': puzzle.id,
        'fen': puzzle.fen,
        'moves': puzzle.solution.join(' '),
        'solution': puzzle.solution,
        'rating': puzzle.rating,
        'themes': [puzzle.theme],
        'created_at': DateTime.now().toUtc(),
      };

  /// Reads a `daily_puzzles` document back into a [MixedPuzzle]. Accepts either
  /// the `solution` array or the raw `moves` string. Returns null when the
  /// document is missing the position or the solution.
  static MixedPuzzle? _fromMongoDoc(Map<String, dynamic> doc) {
    final id = (doc['puzzle_id'] ?? doc['id'] ?? '').toString();
    final fen = (doc['fen'] ?? '').toString();

    List<String> solution = [];
    final rawSolution = doc['solution'];
    if (rawSolution is List && rawSolution.isNotEmpty) {
      solution = rawSolution.map((m) => m.toString().toLowerCase()).toList();
    } else {
      solution = (doc['moves'] ?? '')
          .toString()
          .split(RegExp(r'\s+'))
          .where((m) => m.isNotEmpty)
          .map((m) => m.toLowerCase())
          .toList();
    }

    if (id.isEmpty || fen.isEmpty || solution.isEmpty) return null;

    String theme = 'mix';
    final themes = doc['themes'];
    if (themes is List && themes.isNotEmpty) {
      theme = themes.first.toString();
    } else if (themes is String && themes.isNotEmpty) {
      theme = themes;
    }

    return MixedPuzzle(
      id: id,
      fen: fen,
      solution: solution,
      theme: theme,
      rating: (doc['rating'] as num?)?.toInt() ?? 1500,
    );
  }

  static String _stamp(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  // ---------------------------------------------------------------------------
  // Turso
  // ---------------------------------------------------------------------------

  /// Runs one statement through the Turso pipeline and returns its rows.
  static Future<List<List<dynamic>>> _query(
      String sql, List<String> args) async {
    final dbUrl = dotenv.env['TURSO_DB_URL'];
    final dbToken = dotenv.env['TURSO_DB_TOKEN'];
    if (dbUrl == null || dbUrl.isEmpty || dbToken == null || dbToken.isEmpty) {
      throw Exception(
        'Turso DB credentials (TURSO_DB_URL / TURSO_DB_TOKEN) missing from .env',
      );
    }

    final body = jsonEncode({
      'requests': [
        {
          'type': 'execute',
          'stmt': {
            'sql': sql,
            'args': [
              for (final a in args)
                {'type': 'integer', 'value': a},
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
      throw Exception('Turso DB error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) throw Exception('Turso DB returned no results');

    final first = results.first as Map<String, dynamic>;
    if (first['type'] != 'ok') {
      throw Exception('Turso DB query failed: ${first['error'] ?? first}');
    }

    final responseObj = first['response'] as Map<String, dynamic>?;
    final result = responseObj?['result'] as Map<String, dynamic>?;
    return (result?['rows'] as List<dynamic>? ?? [])
        .map((row) => row as List<dynamic>)
        .toList();
  }

  static String _cellValue(dynamic cell) {
    if (cell is Map<String, dynamic>) return cell['value']?.toString() ?? '';
    return cell?.toString() ?? '';
  }

  /// Parses the first well-formed row (id, fen, moves, rating, themes).
  static MixedPuzzle? _firstPuzzle(List<List<dynamic>> rows) {
    for (final row in rows) {
      final puzzle = _parseRow(row);
      if (puzzle != null) return puzzle;
    }
    return null;
  }

  static MixedPuzzle? _parseRow(List<dynamic> row) {
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
      // Invalid themes JSON — fall back to 'mix'.
    }

    return MixedPuzzle(
      id: id,
      fen: fen,
      solution: solution,
      theme: theme,
      rating: rating,
    );
  }
}
