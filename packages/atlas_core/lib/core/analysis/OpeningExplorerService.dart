import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:atlas_core/core/auth/LichessAuthService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';

enum ExplorerDatabase { masters, lichess }

class OpeningMove {
  final String san;
  final String uci;
  final int white;
  final int draws;
  final int black;
  final int averageRating;

  OpeningMove({
    required this.san,
    required this.uci,
    required this.white,
    required this.draws,
    required this.black,
    required this.averageRating,
  });

  int get totalGames => white + draws + black;

  /// Percentage of games won by the side to move (0.0 - 1.0)
  double get whiteScore => totalGames == 0 ? 0 : (white + draws / 2) / totalGames;

  factory OpeningMove.fromJson(Map<String, dynamic> json) {
    return OpeningMove(
      san: json['san'] ?? '',
      uci: json['uci'] ?? '',
      white: json['white'] ?? 0,
      draws: json['draws'] ?? 0,
      black: json['black'] ?? 0,
      averageRating: json['averageRating'] ?? 0,
    );
  }
}

class TopGame {
  final String? uci;
  final String id;
  final String winner; // 'white', 'black', or null (draw)
  final Map<String, dynamic> white;
  final Map<String, dynamic> black;
  final int year;
  final String? month; // API returns month names as strings, e.g. "March"

  TopGame({
    this.uci,
    required this.id,
    required this.winner,
    required this.white,
    required this.black,
    required this.year,
    this.month,
  });

  factory TopGame.fromJson(Map<String, dynamic> json) {
    return TopGame(
      uci: json['uci'],
      id: json['id'] ?? '',
      winner: json['winner'] ?? 'draw',
      white: json['white'] ?? {},
      black: json['black'] ?? {},
      year: json['year'] ?? 0,
      month: json['month']?.toString(),
    );
  }

  String get resultString {
    if (winner == 'white') return '1-0';
    if (winner == 'black') return '0-1';
    return '½-½';
  }

  String get whiteName => white['name'] ?? 'Unknown';
  String get blackName => black['name'] ?? 'Unknown';
  String get whiteRating =>
      white['rating'] != null ? white['rating'].toString() : '—';
  String get blackRating =>
      black['rating'] != null ? black['rating'].toString() : '—';
}

class OpeningExplorerResult {
  final int white;
  final int draws;
  final int black;
  final String? openingName;
  final String? eco;
  final List<OpeningMove> moves;
  final List<TopGame> topGames;
  final List<TopGame> recentGames;

  OpeningExplorerResult({
    required this.white,
    required this.draws,
    required this.black,
    this.openingName,
    this.eco,
    required this.moves,
    required this.topGames,
    required this.recentGames,
  });

  int get totalGames => white + draws + black;

  factory OpeningExplorerResult.fromJson(Map<String, dynamic> json) {
    final moves = (json['moves'] as List?)
            ?.map((m) => OpeningMove.fromJson(m))
            .toList() ??
        [];

    final topGames = (json['topGames'] as List?)
            ?.map((g) => TopGame.fromJson(g))
            .toList() ??
        [];

    final recentGames = (json['recentGames'] as List?)
            ?.map((g) => TopGame.fromJson(g))
            .toList() ??
        [];

    String? name;
    String? eco;
    if (json['opening'] != null) {
      name = json['opening']['name'];
      eco = json['opening']['eco'];
    }

    return OpeningExplorerResult(
      white: json['white'] ?? 0,
      draws: json['draws'] ?? 0,
      black: json['black'] ?? 0,
      openingName: name,
      eco: eco,
      moves: moves,
      topGames: topGames,
      recentGames: recentGames,
    );
  }
}

class OpeningExplorerService {
  static const String _lichessExplorerBase = 'https://explorer.lichess.org';
  static const String _userAgent = 'AtlasChess/1.0 (mobile)';

  /// Lichess API token, injected at compile time via
  /// `--dart-define=LICHESS_API_TOKEN=lip_xxx`.
  /// This is a development fallback — production builds rely on
  /// [LichessAuthService] (OAuth "Sign in with Lichess").
  /// Never commit the token to version control.
  static const String _devToken = String.fromEnvironment(
    'LICHESS_API_TOKEN',
    defaultValue: '',
  );

  /// Resolves the token to use: the user's OAuth token if signed in,
  /// otherwise the compile-time developer token (if provided).
  static String? get _token {
    final oauth = LichessAuthService.instance.token;
    if (oauth != null && oauth.isNotEmpty) return oauth;
    if (_devToken.isNotEmpty) return _devToken;
    return null;
  }

  /// Whether a token is available (OAuth sign-in or dev define).
  static bool get hasToken => _token != null;

  /// Fetches the full PGN of an explorer game by its id.
  ///
  /// - Masters games: `explorer.lichess.org/masters/pgn/{id}` (token required)
  /// - Lichess games: `lichess.org/game/export/{id}` (public, token sent too)
  static Future<String?> fetchGamePgn(
    String id, {
    ExplorerDatabase database = ExplorerDatabase.masters,
  }) async {
    try {
      final uri = database == ExplorerDatabase.masters
          ? Uri.parse('https://explorer.lichess.org/masters/pgn/$id')
          : Uri.parse('https://lichess.org/game/export/$id');

      final headers = <String, String>{
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      };
      final token = _token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        return response.body;
      }
      AppLogger.warn(
        'Explorer game PGN request failed (${response.statusCode}) for: $id',
      );
      return null;
    } catch (e) {
      AppLogger.error('Error fetching explorer game PGN: $e');
      return null;
    }
  }

  /// Simple in-memory position cache to reduce duplicate requests
  /// when the user navigates back and forth.
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);
  static const int _maxCacheEntries = 500;

  static Future<OpeningExplorerResult?> fetchOpeningData(
    String fen, {
    ExplorerDatabase database = ExplorerDatabase.lichess,
    List<String> speeds = const ['blitz', 'rapid', 'classical'],
    List<int> ratings = const [1600, 1800, 2000, 2200, 2500],
  }) async {
    try {
      final dbPath = database == ExplorerDatabase.masters ? 'masters' : 'lichess';

      final queryParams = <String, String>{
        'fen': fen,
        'variant': 'standard',
        'topGames': '4',
        'recentGames': '4',
      };

      if (database == ExplorerDatabase.lichess) {
        queryParams['speeds'] = speeds.join(',');
        queryParams['ratings'] = ratings.join(',');
      }

      final uri = Uri.parse(
        '$_lichessExplorerBase/$dbPath',
      ).replace(queryParameters: queryParams);

      final cacheKey = uri.toString();

      // Check cache
      final cached = _cache[cacheKey];
      if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
        return cached.result;
      }

      final headers = <String, String>{
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      };
      final token = _token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final result = OpeningExplorerResult.fromJson(jsonDecode(response.body));
        // Store in cache
        if (_cache.length >= _maxCacheEntries) _cache.clear();
        _cache[cacheKey] = _CacheEntry(
          result: result,
          expiresAt: DateTime.now().add(_cacheTtl),
        );
        return result;
      }

      AppLogger.warn(
        'Opening explorer request failed (${response.statusCode}) for: $dbPath',
      );
      if (response.statusCode == 401) {
        AppLogger.info(
          'Hint: sign in with Lichess (explorer tab) or set LICHESS_API_TOKEN '
          'via --dart-define=LICHESS_API_TOKEN=lip_xxx',
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching opening data: $e');
      return null;
    }
  }
}

class _CacheEntry {
  final OpeningExplorerResult result;
  final DateTime expiresAt;
  _CacheEntry({required this.result, required this.expiresAt});
}
