import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_core/core/puzzles/MixedPuzzleService.dart';

/// One theme entry on the "Browse all themes" screen and the search it runs
/// against the puzzles DB.
class ThemePuzzleDef {
  final String screenName;
  final String description;
  final String? dbTheme;
  final List<String>? dbThemeAnyOf;

  const ThemePuzzleDef({
    required this.screenName,
    required this.description,
    this.dbTheme,
    this.dbThemeAnyOf,
  });
}

/// Themed batches reuse [MixedPuzzle] from MixedPuzzleService directly so the
/// existing MixedPuzzlePlayScreen can consume them without any conversion.

class ThemePuzzleService {
  // Same tuning as MixedPuzzleService — themes share the mixed rating.
  static const int _kBatchSize = 20;
  static const int _kRatingWindow = 400;

  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // Theme definitions — screen name -> DB theme search (verified against the
  // local lichess_puzzles.db; counts saved in theme_predicate_counts.json).
  // ---------------------------------------------------------------------------

  /// "Other Mates" catch-all: substring 'mate' matches mate, mateIn1..5 and
  /// every named mate pattern (backRankMate, smotheredMate, operaMate, ...).
  /// "Advanced Tactics" catch-all: OR of the leftover combinatorial themes
  /// that have no screen entry of their own.
  static const Map<String, ThemePuzzleDef> themeDefs = {
    // ---- Mates ----
    'Mate In 1': ThemePuzzleDef(
        screenName: 'Mate In 1',
        description: 'Find the checkmate in a single move.',
        dbTheme: 'mateIn1'),
    'Mate In 2': ThemePuzzleDef(
        screenName: 'Mate In 2',
        description:
            'Set up the position and finish with checkmate on your next move.',
        dbTheme: 'mateIn2'),
    'Mate In 3': ThemePuzzleDef(
        screenName: 'Mate In 3',
        description:
            'Find the winning sequence that leads to checkmate in three moves.',
        dbTheme: 'mateIn3'),
    'Mate In 4': ThemePuzzleDef(
        screenName: 'Mate In 4',
        description: 'Plan a few moves ahead to force checkmate.',
        dbTheme: 'mateIn4'),
    'Mate In 5': ThemePuzzleDef(
        screenName: 'Mate In 5',
        description: 'A longer mating sequence where every move matters.',
        dbTheme: 'mateIn5'),
    'Other Mates': ThemePuzzleDef(
        screenName: 'Other Mates',
        description:
            'Special mating patterns like Back Rank, Smothered, Anastasia, Arabian, Boden, Opera, and more.',
        dbTheme: 'mate'), // substring match — see _themePredicate
    // ---- Tactics ----
    'Fork': ThemePuzzleDef(
        screenName: 'Fork',
        description: 'One piece attacks two or more targets at once.',
        dbTheme: 'fork'),
    'Pin': ThemePuzzleDef(
        screenName: 'Pin',
        description:
            'A piece is stuck because moving it would expose something more valuable.',
        dbTheme: 'pin'),
    'Skewer': ThemePuzzleDef(
        screenName: 'Skewer',
        description: 'Attack a valuable piece and win what is hiding behind it.',
        dbTheme: 'skewer'),
    'Discovered Attack': ThemePuzzleDef(
        screenName: 'Discovered Attack',
        description: 'Move one piece to uncover an attack from another.',
        dbTheme: 'discoveredAttack'),
    'Discovered Check': ThemePuzzleDef(
        screenName: 'Discovered Check',
        description: 'Uncover a check by moving another piece out of the way.',
        dbTheme: 'discoveredCheck'),
    'Double Check': ThemePuzzleDef(
        screenName: 'Double Check',
        description: 'Give check from two pieces at the same time.',
        dbTheme: 'doubleCheck'),
    'Sacrifice': ThemePuzzleDef(
        screenName: 'Sacrifice',
        description: 'Give up material to gain something stronger in return.',
        dbTheme: 'sacrifice'),
    'Deflection': ThemePuzzleDef(
        screenName: 'Deflection',
        description: 'Force a piece away from where it needs to be.',
        dbTheme: 'deflection'),
    'Clearance': ThemePuzzleDef(
        screenName: 'Clearance',
        description: 'Move a piece away to open the way for another piece.',
        dbTheme: 'clearance'),
    'Capturing Defender': ThemePuzzleDef(
        screenName: 'Capturing Defender',
        description: 'Remove the piece protecting an important target.',
        dbTheme: 'capturingDefender'),
    'Advanced Tactics': ThemePuzzleDef(
        screenName: 'Advanced Tactics',
        description:
            'More difficult combinations involving several tactical ideas.',
        dbThemeAnyOf: [
          'attraction',
          'intermezzo',
          'interference',
          'xRayAttack',
          'trappedPiece',
          'hangingPiece',
          'collinearMove',
        ]),
    // ---- King Attack ----
    'Kingside Attack': ThemePuzzleDef(
        screenName: 'Kingside Attack',
        description: 'Build an attack against the king on the kingside.',
        dbTheme: 'kingsideAttack'),
    'Queenside Attack': ThemePuzzleDef(
        screenName: 'Queenside Attack',
        description:
            'Look for ways to break through around the enemy king on the queenside.',
        dbTheme: 'queensideAttack'),
    'Exposed King': ThemePuzzleDef(
        screenName: 'Exposed King',
        description: 'Take advantage of a king that has lost its protection.',
        dbTheme: 'exposedKing'),
    'Attacking F2 F7': ThemePuzzleDef(
        screenName: 'Attacking F2 F7',
        description: 'Target the weak f2 or f7 square near the king.',
        dbTheme: 'attackingF2F7'),
    // ---- Endgames ----
    'Endgame': ThemePuzzleDef(
        screenName: 'Endgame',
        description: 'Find the best way to play when only a few pieces remain.',
        dbTheme: 'endgame'),
    'Rook Endgame': ThemePuzzleDef(
        screenName: 'Rook Endgame',
        description: 'Learn to make the most of your rooks in the endgame.',
        dbTheme: 'rookEndgame'),
    'Queen Endgame': ThemePuzzleDef(
        screenName: 'Queen Endgame',
        description:
            'Find the right moves in positions where queens remain on the board.',
        dbTheme: 'queenEndgame'),
    'Queen Rook Endgame': ThemePuzzleDef(
        screenName: 'Queen Rook Endgame',
        description:
            'Handle endgames where queens and rooks are still in play.',
        dbTheme: 'queenRookEndgame'),
    'Bishop Endgame': ThemePuzzleDef(
        screenName: 'Bishop Endgame',
        description: 'Use your bishop and king to find the winning plan.',
        dbTheme: 'bishopEndgame'),
    'Knight Endgame': ThemePuzzleDef(
        screenName: 'Knight Endgame',
        description:
            'Find the right moves in endgames where knights matter most.',
        dbTheme: 'knightEndgame'),
    'Pawn Endgame': ThemePuzzleDef(
        screenName: 'Pawn Endgame',
        description: 'Calculate pawn races and find the path to victory.',
        dbTheme: 'pawnEndgame'),
    'Zugzwang': ThemePuzzleDef(
        screenName: 'Zugzwang',
        description:
            'Put your opponent in a position where any move makes things worse.',
        dbTheme: 'zugzwang'),
    // ---- Pawns & Promotion ----
    'Advanced Pawn': ThemePuzzleDef(
        screenName: 'Advanced Pawn',
        description:
            'Use a dangerous pawn that has pushed deep into enemy territory.',
        dbTheme: 'advancedPawn'),
    'Promotion': ThemePuzzleDef(
        screenName: 'Promotion',
        description: 'Push a pawn through to become a stronger piece.',
        dbTheme: 'promotion'),
    'Under Promotion': ThemePuzzleDef(
        screenName: 'Under Promotion',
        description:
            "Promote to something other than a queen when that's the winning move.",
        dbTheme: 'underPromotion'),
    'En Passant': ThemePuzzleDef(
        screenName: 'En Passant',
        description: 'Spot the rare chance to capture a pawn using en passant.',
        dbTheme: 'enPassant'),
    // ---- Strategy ----
    'Quiet Move': ThemePuzzleDef(
        screenName: 'Quiet Move',
        description:
            'Find a calm move that creates a strong advantage without forcing tactics.',
        dbTheme: 'quietMove'),
    'Defensive Move': ThemePuzzleDef(
        screenName: 'Defensive Move',
        description: "Find the move that stops your opponent's threat.",
        dbTheme: 'defensiveMove'),
    'Advantage': ThemePuzzleDef(
        screenName: 'Advantage',
        description: 'Find the move that keeps or increases your advantage.',
        dbTheme: 'advantage'),
    'Equality': ThemePuzzleDef(
        screenName: 'Equality',
        description: 'Find the move that keeps the position balanced.',
        dbTheme: 'equality'),
    'Crushing': ThemePuzzleDef(
        screenName: 'Crushing',
        description:
            'Find the powerful move that turns a strong position into a winning one.',
        dbTheme: 'crushing'),
  };

  // ---------------------------------------------------------------------------
  // SQL predicate builder
  // ---------------------------------------------------------------------------

  /// WHERE predicate for a screen theme. Turso runs the same SQLite schema as
  /// the local DB: themes is a JSON array of tokens, so exact tokens are
  /// matched with LIKE '%"token"%'.
  ///   Other Mates      -> themes LIKE '%mate%'            (substring)
  ///   Advanced Tactics -> (LIKE '%"a"%' OR LIKE '%"b"%' ...) (OR of tokens)
  ///   everything else  -> themes LIKE '%"token"%'         (exact token)
  static String themePredicate(String screenTheme) {
    if (screenTheme == 'Other Mates') return "themes LIKE '%mate%'";
    if (screenTheme == 'Advanced Tactics') {
      final anyOf = themeDefs['Advanced Tactics']!.dbThemeAnyOf!;
      return anyOf.map((t) => "themes LIKE '%\"$t\"%'").join(' OR ');
    }
    final token = themeDefs[screenTheme]?.dbTheme ?? _slugify(screenTheme);
    return "themes LIKE '%\"$token\"%'";
  }

  /// 'Attacking F2 F7' -> 'attackingF2F7'
  static String _slugify(String screenName) {
    final words = screenName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return screenName;
    final buf = StringBuffer(words.first.toLowerCase());
    for (int i = 1; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;
      buf.write(w[0].toUpperCase());
      buf.write(w.substring(1).toLowerCase());
    }
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Rating — themes share the SAME rating as mixed puzzles (delegated to
  // MixedPuzzleService so there is exactly one source of truth).
  // ---------------------------------------------------------------------------

  static Future<int> getRating() => MixedPuzzleService.getRating();

  static Future<int> adjustRating({required bool perfect}) =>
      MixedPuzzleService.adjustRating(perfect: perfect);

  // ---------------------------------------------------------------------------
  // Batch persistence — one stored batch per theme
  // ---------------------------------------------------------------------------

  static String _batchKey(String theme) => 'theme_puzzle_batch__${_keyOf(theme)}';
  static String _indexKey(String theme) => 'theme_puzzle_index__${_keyOf(theme)}';

  static String _keyOf(String theme) =>
      theme.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static Future<List<MixedPuzzle>> getBatch(String theme) async {
    await _ensurePrefs();
    final raw = _prefs!.getString(_batchKey(theme));
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

  static Future<void> saveBatch(String theme, List<MixedPuzzle> batch) async {
    await _ensurePrefs();
    final encoded = jsonEncode(batch.map((p) => p.toJson()).toList());
    await _prefs!.setString(_batchKey(theme), encoded);
  }

  static Future<void> clearBatch(String theme) async {
    await _ensurePrefs();
    await _prefs!.remove(_batchKey(theme));
    await _prefs!.remove(_indexKey(theme));
  }

  static Future<void> markCompleted(String theme, String puzzleId) async {
    final batch = await getBatch(theme);
    bool changed = false;
    final updated = batch.map((p) {
      if (p.id == puzzleId && !p.completed) {
        changed = true;
        return p.copyWith(completed: true);
      }
      return p;
    }).toList();
    if (changed) await saveBatch(theme, updated);
  }

  static Future<int> getCurrentIndex(String theme) async {
    await _ensurePrefs();
    return _prefs!.getInt(_indexKey(theme)) ?? 0;
  }

  static Future<void> setCurrentIndex(String theme, int index) async {
    await _ensurePrefs();
    await _prefs!.setInt(_indexKey(theme), index);
  }

  // ---------------------------------------------------------------------------
  // Turso — fetch a batch of puzzles for one theme within the rating window
  // ---------------------------------------------------------------------------

  static String _cellValue(dynamic cell) {
    if (cell is Map<String, dynamic>) {
      return cell['value']?.toString() ?? '';
    }
    return cell?.toString() ?? '';
  }

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
      // keep 'mix'
    }

    return MixedPuzzle(
      id: id,
      fen: fen,
      solution: solution,
      theme: theme,
      rating: rating,
    );
  }

  /// Runs one Turso pipeline request and returns the parsed puzzle rows.
  static Future<List<MixedPuzzle>> _runTursoQuery(
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
    return puzzles;
  }

  /// Fetches up to [_kBatchSize] puzzles for [theme] inside
  /// [minRating, maxRating].
  static Future<List<MixedPuzzle>> _fetchBatchInRange(
      String theme, int minRating, int maxRating, int count) async {
    final predicate = themePredicate(theme);
    final sql = 'SELECT id, fen, moves, rating, themes FROM puzzles '
        'WHERE rating BETWEEN ? AND ? AND ($predicate) '
        'ORDER BY RANDOM() LIMIT $count';
    return _runTursoQuery(sql, ['$minRating', '$maxRating']);
  }

  /// Fetches a themed batch, widening the rating window if the theme is too
  /// rare to fill 20 puzzles at the user's rating (e.g. Mate In 5 or En
  /// Passant at low ratings). The mixed rating window (±400) is always tried
  /// FIRST — the widening is only a fallback so rare themes never come back
  /// empty.
  static Future<List<MixedPuzzle>> fetchBatchFromTurso(String theme,
      {int? ratingOverride, int count = _kBatchSize}) async {
    final rating = ratingOverride ?? await getRating();

    final wideningSteps = [0, 200, 500, 1000, 2000, 10000];
    List<MixedPuzzle> best = [];
    for (int i = 0; i < wideningSteps.length; i++) {
      final extra = wideningSteps[i];
      final min = rating - _kRatingWindow - extra;
      final max = rating + _kRatingWindow + extra;
      final batch = await _fetchBatchInRange(theme, min, max, count);
      if (batch.length >= count) return batch.take(count).toList();
      if (batch.length > best.length) best = batch;
      // No point widening further if there is nothing at all in this range.
      if (batch.isEmpty && extra >= 1000) break;
    }

    if (best.isNotEmpty) return best.take(count).toList();
    throw Exception(
        'No puzzles found for theme "$theme" within rating range');
  }

  // ---------------------------------------------------------------------------
  // Batch lifecycle
  // ---------------------------------------------------------------------------

  static Future<List<MixedPuzzle>> fetchAndSaveNewBatch(String theme,
      {int count = _kBatchSize}) async {
    final newBatch = await fetchBatchFromTurso(theme, count: count);
    await clearBatch(theme);
    await saveBatch(theme, newBatch);
    await setCurrentIndex(theme, 0);
    return newBatch;
  }

  static Future<List<MixedPuzzle>> ensureBatch(String theme,
      {int count = _kBatchSize}) async {
    final existing = await getBatch(theme);
    if (existing.isNotEmpty && existing.any((p) => !p.completed)) {
      return existing;
    }
    return await fetchAndSaveNewBatch(theme, count: count);
  }

  /// IDs of unsolved puzzles retained by every themed batch. The set removes
  /// duplicates if a random Turso query returns the same puzzle in two themes.
  static Future<Set<String>> getAllUnsolvedPuzzleIds() async {
    final ids = <String>{};
    for (final theme in themeDefs.keys) {
      final batch = await getBatch(theme);
      ids.addAll(batch.where((p) => !p.completed).map((p) => p.id));
    }
    return ids;
  }
}
