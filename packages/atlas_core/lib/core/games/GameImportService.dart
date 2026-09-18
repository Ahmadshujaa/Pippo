import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chess/chess.dart' as chess;

class GameImportResult {
  final bool success;
  final String? pgn;
  final Map<String, String>? headers;
  final List<String>? sanMoves;
  final String? error;
  final String? fen;
  final String? url;

  GameImportResult({
    required this.success,
    this.pgn,
    this.headers,
    this.sanMoves,
    this.error,
    this.fen,
    this.url,
  });

  factory GameImportResult.success({
    required String pgn,
    required Map<String, String> headers,
    required List<String> sanMoves,
    String? url,
  }) = _SuccessGameImportResult;

  factory GameImportResult.error(String error) = _ErrorGameImportResult;

  factory GameImportResult.fenOnly(String fen) = _FenOnlyGameImportResult;
}

class _SuccessGameImportResult extends GameImportResult {
  _SuccessGameImportResult({
    required String super.pgn,
    required Map<String, String> super.headers,
    required List<String> super.sanMoves,
    super.url,
  }) : super(success: true);
}

class _ErrorGameImportResult extends GameImportResult {
  _ErrorGameImportResult(String error) : super(success: false, error: error);
}

class _FenOnlyGameImportResult extends GameImportResult {
  _FenOnlyGameImportResult(String fen) : super(success: true, fen: fen);
}

class GameSummary {
  final String id;
  final String white;
  final String black;
  final int? whiteRating;
  final int? blackRating;
  final String result;
  final DateTime date;
  final String source;
  final String? pgn;
  final String? url;

  GameSummary({
    required this.id,
    required this.white,
    required this.black,
    this.whiteRating,
    this.blackRating,
    required this.result,
    required this.date,
    required this.source,
    this.pgn,
    this.url,
  });
}

class GameImportService {
  static const String _lichessApiBase = 'https://lichess.org/api';
  static const String _chessComApiBase = 'https://api.chess.com/pub';

  static Future<GameImportResult> importFromPgn(String pgnText) async {
    try {
      final game = chess.Chess();
      final parsed = game.load_pgn(pgnText.trim());

      if (!parsed) {
        return GameImportResult.error('Invalid PGN format. Could not parse the game.');
      }

      final headers = Map<String, String>.from(game.header);
      final sanMoves = game
          .getHistory({'verbose': false})
          .whereType<String>()
          .toList();

      if (sanMoves.isEmpty) {
        return GameImportResult.error('No moves found in the PGN.');
      }

      return GameImportResult.success(
        pgn: game.pgn(),
        headers: headers,
        sanMoves: sanMoves,
      );
    } catch (e) {
      return GameImportResult.error('Failed to parse PGN: $e');
    }
  }

  static Future<GameImportResult> importFromLichessUrl(String url) async {
    try {
      final gameId = _extractLichessGameId(url);
      if (gameId == null) {
        return GameImportResult.error(
          'Invalid Lichess URL format. Expected: https://lichess.org/<gameId> or https://lichess.org/<gameId>/<color>',
        );
      }

      final response = await http.get(
        Uri.parse('$_lichessApiBase/games/export/one/$gameId?pgnInJson=true'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return GameImportResult.error(
          'Failed to fetch game from Lichess (${response.statusCode}). Game may be private or not exist.',
        );
      }

      final json = jsonDecode(response.body);
      final pgnText = json['pgn'] as String?;
      if (pgnText == null || pgnText.isEmpty) {
        return GameImportResult.error('No PGN found in Lichess response.');
      }

      final res = await importFromPgn(pgnText);
      if (res.success) {
        return GameImportResult.success(
          pgn: res.pgn!,
          headers: res.headers!,
          sanMoves: res.sanMoves!,
          url: url,
        );
      }
      return res;
    } catch (e) {
      return GameImportResult.error('Failed to load from Lichess: $e');
    }
  }

  static Future<GameImportResult> importFromChessComUrl(String url) async {
    try {
      final gameId = _extractChessComGameId(url);
      if (gameId == null) {
        return GameImportResult.error(
          'Invalid Chess.com URL format. Expected: https://www.chess.com/game/live/<gameId> or similar.',
        );
      }

      final response = await http.get(
        Uri.parse('$_chessComApiBase/game/$gameId'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AtlasChess App (contact: ahmad@test.com)'
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return GameImportResult.error(
          'Failed to fetch game from Chess.com (${response.statusCode}). Game may be private or not exist.',
        );
      }

      final json = jsonDecode(response.body);
      final pgnText = json['pgn'] as String?;
      
      if (pgnText == null || pgnText.isEmpty) {
        return GameImportResult.error('No PGN found in Chess.com response.');
      }

      final res = await importFromPgn(pgnText);
      if (res.success) {
        return GameImportResult.success(
          pgn: res.pgn!,
          headers: res.headers!,
          sanMoves: res.sanMoves!,
          url: url,
        );
      }
      return res;
    } catch (e) {
      return GameImportResult.error('Failed to load from Chess.com: $e');
    }
  }

  static Future<List<GameSummary>> fetchUserGamesFromLichess(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_lichessApiBase/games/user/$username?max=20'),
        headers: {'Accept': 'application/x-ndjson'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Lichess error: ${response.statusCode}');
      }

      final lines = response.body.trim().split('\n');
      final List<GameSummary> games = [];

      for (final line in lines) {
        if (line.isEmpty) continue;
        final json = jsonDecode(line);
        
        final players = json['players'];
        final white = players['white'];
        final black = players['black'];

        games.add(GameSummary(
          id: json['id'],
          white: white['user']?['name'] ?? 'Anonymous',
          black: black['user']?['name'] ?? 'Anonymous',
          whiteRating: white['rating'],
          blackRating: black['rating'],
          result: json['winner'] == 'white' ? '1-0' : (json['winner'] == 'black' ? '0-1' : '1/2-1/2'),
          date: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
          source: 'Lichess',
          pgn: json['pgn'],
          url: 'https://lichess.org/${json['id']}',
        ));
      }
      return games;
    } catch (e) {
      throw Exception('Failed to fetch Lichess games: $e');
    }
  }

  static Future<List<GameSummary>> fetchUserGamesFromChessCom(String username) async {
    try {
      // 1. Get archives
      final archivesResponse = await http.get(
        Uri.parse('$_chessComApiBase/player/$username/games/archives'),
        headers: {'User-Agent': 'AtlasChess App (contact: ahmad@test.com)'},
      ).timeout(const Duration(seconds: 10));

      if (archivesResponse.statusCode != 200) {
        throw Exception('Chess.com error: ${archivesResponse.statusCode}');
      }

      final archivesJson = jsonDecode(archivesResponse.body);
      final List archives = archivesJson['archives'] ?? [];
      if (archives.isEmpty) return [];

      // 2. Get latest month
      final latestArchiveUrl = archives.last;
      final gamesResponse = await http.get(
        Uri.parse(latestArchiveUrl),
        headers: {'User-Agent': 'AtlasChess App (contact: ahmad@test.com)'},
      ).timeout(const Duration(seconds: 10));

      if (gamesResponse.statusCode != 200) {
        throw Exception('Chess.com games error: ${gamesResponse.statusCode}');
      }

      final gamesJson = jsonDecode(gamesResponse.body);
      final List gamesList = gamesJson['games'] ?? [];
      final List<GameSummary> games = [];

      for (final g in gamesList.reversed.take(20)) {
        final white = g['white'];
        final black = g['black'];
        
        // Basic result parsing
        String res = '*';
        if (white['result'] == 'win') {
          res = '1-0';
        } else if (black['result'] == 'win') {
          res = '0-1';
        } else {
          res = '1/2-1/2';
        }

        games.add(GameSummary(
          id: (g['url'] as String).split('/').last,
          white: white['username'] ?? 'Unknown',
          black: black['username'] ?? 'Unknown',
          whiteRating: white['rating'],
          blackRating: black['rating'],
          result: res,
          date: DateTime.fromMillisecondsSinceEpoch((g['end_time'] ?? 0) * 1000),
          source: 'Chess.com',
          pgn: g['pgn'],
          url: g['url'],
        ));
      }
      return games;
    } catch (e) {
      throw Exception('Failed to fetch Chess.com games: $e');
    }
  }

  static GameImportResult loadFromFen(String fen) {
    try {
      final game = chess.Chess.fromFEN(fen.trim());
      return GameImportResult.fenOnly(game.fen);
    } catch (e) {
      return GameImportResult.error('Invalid FEN: $e');
    }
  }

  static String? _extractLichessGameId(String url) {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null) return null;

      // Handle both lichess.org/gameId and lichess.org/gameId/white
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.isEmpty) return null;

      final gameId = pathSegments.first;
      // Lichess IDs are 8 chars (standard) or 12 chars (with room ID)
      if (gameId.length >= 8 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(gameId)) {
        return gameId.substring(0, 8); // We only need the first 8 chars for the export API
      }
    } catch (_) {}
    return null;
  }

  static String? _extractChessComGameId(String url) {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null) return null;

      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.isEmpty) return null;

      // Usually /game/live/ID or /game/daily/ID or /live/ID
      for (final segment in pathSegments) {
        if (RegExp(r'^\d{5,}$').hasMatch(segment)) {
          return segment;
        }
      }
    } catch (_) {}
    
    // Fallback: try to find digits in the path via regex if segment iteration fails
    final match = RegExp(r'/(\d{8,})').firstMatch(url);
    return match?.group(1);
  }
}