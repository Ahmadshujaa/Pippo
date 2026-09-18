import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedGame {
  final List<String> moves;
  final String result;
  final String resultType;
  final String playerColor;
  final int elo;
  final String opponent;
  final int timestamp;

  const SavedGame({
    required this.moves,
    required this.result,
    required this.resultType,
    required this.playerColor,
    required this.elo,
    required this.opponent,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'moves': moves,
        'result': result,
        'resultType': resultType,
        'playerColor': playerColor,
        'elo': elo,
        'opponent': opponent,
        'timestamp': timestamp,
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
        moves: (json['moves'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        result: json['result']?.toString() ?? '',
        resultType: json['resultType']?.toString() ?? '',
        playerColor: json['playerColor']?.toString() ?? 'white',
        elo: (json['elo'] as num?)?.toInt() ?? 0,
        opponent: json['opponent']?.toString() ?? 'Pippo',
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      );
}

class GameStorageService {
  static const String _key = 'saved_games';

  // Daily games-played counter. Games are deleted from [_key] once the
  // background analyzer turns them into puzzles, so the stored list alone
  // undercounts "games played today". This counter is bumped on every save
  // and reset implicitly by comparing the stored date stamp with today.
  static const String _dailyDateKey = 'daily_games_date';
  static const String _dailyCountKey = 'daily_games_count';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Appends [game] to the stored list. Games are kept until they have been
  /// turned into puzzles by the background analyzer and explicitly deleted
  /// via [deleteGameByTimestamp] — there is no automatic eviction cap.
  static Future<void> saveGame(SavedGame game) async {
    await init();
    final games = getGames();
    games.add(game);
    final encoded =
        jsonEncode(games.map((g) => g.toJson()).toList(growable: false));
    await _prefs!.setString(_key, encoded);
    await _incrementDailyCount();
  }

  /// How many games were played today (resets at local midnight).
  static Future<int> getGamesPlayedToday() async {
    await init();
    if (_prefs!.getString(_dailyDateKey) != _todayStamp()) return 0;
    return _prefs!.getInt(_dailyCountKey) ?? 0;
  }

  static Future<void> _incrementDailyCount() async {
    final today = _todayStamp();
    if (_prefs!.getString(_dailyDateKey) != today) {
      await _prefs!.setString(_dailyDateKey, today);
      await _prefs!.setInt(_dailyCountKey, 1);
    } else {
      final current = _prefs!.getInt(_dailyCountKey) ?? 0;
      await _prefs!.setInt(_dailyCountKey, current + 1);
    }
  }

  static String _todayStamp() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Removes the game stored with [timestamp], if present. Used by the
  /// background puzzle generator once a game's puzzles have been extracted.
  static Future<void> deleteGameByTimestamp(int timestamp) async {
    await init();
    final games = getGames();
    final remaining = games.where((g) => g.timestamp != timestamp).toList();
    if (remaining.length == games.length) return;
    final encoded =
        jsonEncode(remaining.map((g) => g.toJson()).toList(growable: false));
    await _prefs!.setString(_key, encoded);
  }

  static List<SavedGame> getGames() {
    if (_prefs == null) return [];
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => SavedGame.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearGames() async {
    await init();
    await _prefs!.remove(_key);
  }
}
