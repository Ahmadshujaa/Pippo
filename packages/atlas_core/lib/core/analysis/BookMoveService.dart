import 'dart:convert';

import 'package:http/http.dart' as http;

// =============================================================================
// BOOK MOVE SERVICE
// =============================================================================
//
// Sole purpose: determine whether a given move, played in a given position,
// is a book move by querying the ChessDB opening book API
// (https://www.chessdb.cn). This service has no other responsibilities.

class BookMoveCheckResult {
  final bool isBookMove;
  final bool requestSucceeded;
  final String? bestMoveUci;
  final String? bestMoveSan;
  final int? bestScore;
  final int? rank;
  final String? playedUci;
  final String? playedSan;

  BookMoveCheckResult({
    required this.isBookMove,
    required this.requestSucceeded,
    this.bestMoveUci,
    this.bestMoveSan,
    this.bestScore,
    this.rank,
    this.playedUci,
    this.playedSan,
  });
}

class BookMoveService {
  static const String _chessDbUrl =
      'https://www.chessdb.cn/cdb.php?action=queryall&json=1&board=';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxCachedPositions = 256;

  // A position query contains every book move from that position. Cache it
  // once instead of issuing another HTTP request when the user navigates back
  // or when multiple UI paths ask about moves from the same position.
  static final Map<String, _BookPositionData> _positionCache = {};
  static final Map<String, Future<_BookPositionData>> _inFlightQueries = {};

  /// Normalizes a UCI move string (strips everything except a-h, 1-8, q, r, b, n).
  static String normalizeUci(String? move) {
    if (move == null || move.isEmpty) return '';
    final buffer = StringBuffer();
    for (final rune in move.toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      if ('abcdefgh12345678qrbn'.contains(c)) buffer.write(c);
    }
    return buffer.toString();
  }

  /// Checks whether [moveUci] played in position [fen] is a book move.
  ///
  /// - [isBookMove] is `true` only when the move is present in the ChessDB
  ///   opening book with rank >= 1.
  /// - [requestSucceeded] is `false` when the API could not be reached or
  ///   its response could not be parsed, meaning the result is inconclusive
  ///   rather than a definitive "not a book move".
  static Future<BookMoveCheckResult> checkMove(
    String fen,
    String moveUci, {
    String? moveSan,
  }) async {
    final data = await _queryPosition(fen);
    if (!data.requestSucceeded) {
      return BookMoveCheckResult(
        isBookMove: false,
        requestSucceeded: false,
      );
    }

    final normalizedPlayed = normalizeUci(moveUci);
    Map<String, dynamic>? matched;
    for (final rawMove in data.moves) {
      final moveEntry = rawMove['move'] ?? rawMove['uci'];
      final sanEntry = rawMove['san'];
      final isUciMatch = normalizeUci(moveEntry) == normalizedPlayed;
      final isSanMatch = moveSan != null && sanEntry == moveSan;
      if (isUciMatch || isSanMatch) {
        matched = rawMove;
        break;
      }
    }

    if (matched == null) {
      return BookMoveCheckResult(
        isBookMove: false,
        requestSucceeded: true,
      );
    }

    final rank = matched['rank'];
    if (rank is! int || rank < 1) {
      return BookMoveCheckResult(
        isBookMove: false,
        requestSucceeded: true,
      );
    }

    final firstMove = data.moves.first;
    final bestUci = firstMove['move'] ?? firstMove['uci'];
    final bestSan = firstMove['san'];
    final bestScore = firstMove['score'];

    return BookMoveCheckResult(
      isBookMove: true,
      requestSucceeded: true,
      bestMoveUci: bestUci?.toString(),
      bestMoveSan: bestSan?.toString(),
      bestScore: bestScore is int ? bestScore : null,
      rank: rank,
      playedUci: (matched['move'] ?? matched['uci'])?.toString(),
      playedSan: matched['san']?.toString(),
    );
  }

  static Future<_BookPositionData> _queryPosition(String fen) async {
    final cached = _positionCache[fen];
    if (cached != null) return cached;

    final inFlight = _inFlightQueries[fen];
    if (inFlight != null) return inFlight;

    final future = _fetchPosition(fen);
    _inFlightQueries[fen] = future;
    try {
      final data = await future;
      if (data.requestSucceeded) {
        if (_positionCache.length >= _maxCachedPositions) {
          _positionCache.remove(_positionCache.keys.first);
        }
        _positionCache[fen] = data;
      }
      return data;
    } finally {
      if (identical(_inFlightQueries[fen], future)) {
        _inFlightQueries.remove(fen);
      }
    }
  }

  static Future<_BookPositionData> _fetchPosition(String fen) async {
    try {
      final uri = Uri.parse('$_chessDbUrl${Uri.encodeComponent(fen)}');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) return _BookPositionData.failure();

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
        return _BookPositionData.failure();
      }

      final rawMoves = decoded['moves'];
      if (rawMoves is! List) return _BookPositionData.success(const []);

      final moves = rawMoves
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return _BookPositionData.success(moves);
    } catch (_) {
      // Network and parse failures remain inconclusive and are deliberately
      // not cached, so a transient outage can recover on the next request.
      return _BookPositionData.failure();
    }
  }
}

class _BookPositionData {
  final bool requestSucceeded;
  final List<Map<String, dynamic>> moves;

  const _BookPositionData({
    required this.requestSucceeded,
    required this.moves,
  });

  const _BookPositionData.success(List<Map<String, dynamic>> moves)
      : this(requestSucceeded: true, moves: moves);

  const _BookPositionData.failure()
      : this(requestSucceeded: false, moves: const []);
}
