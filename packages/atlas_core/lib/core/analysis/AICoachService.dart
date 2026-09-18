import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:atlas_core/core/integrations/SupabaseService.dart';
import 'package:atlas_core/core/logging/AppLogger.dart';
import 'package:atlas_core/core/settings/LocaleService.dart';

// ============================================================================
// 1. SYSTEM / USER PROMPTS — put at the top so you can edit them at will.
//    These mirror the website's `CHESS_COACH_SYSTEM_PROMPT` exactly.
// ============================================================================
const _systemPrompt = r'''You are a world-class Grandmaster Chess Coach providing a personalized lesson to a student. Never mention you are an AI, a model, or a computer program. Speak naturally, like a mentor talking directly to their student.

YOUR TASK:
You will be provided with an "Enhanced PGN" of a chess game and the color the student (the user) played.
This PGN contains the actual moves played, categorized by an engine.
For mistakes/blunders, it includes the student's line and the engine's best line.

YOUR OUTPUT:
You MUST output a valid, raw JSON array of objects.
The array must contain exactly one object for EVERY SINGLE MOVE in chronological order.

TONE & STYLE:
1. ADDRESS THE USER: Refer to the user as "You". (e.g., "You played e4 to claim the center").
2. ADDRESS THE OPPONENT: Refer to the other side as "the opponent" or "your opponent". Never say "White played" or "Black played" if you can refer to them as "You" or "Your opponent".
3. COACHING VIBE: Be encouraging but honest. Explain the "Why" behind moves.
4. NO ENGINE REFERENCES: NEVER mention "the engine", "Stockfish", "computer", or "AI suggested". Refer to alternative moves as "a better option", "a solid alternative", or "a much stronger continuation". Speak as if these insights are your own.
5. HUMAN-LIKE COACH WORDS: Talk the way a real coach talks to a student. Use plain, natural, simple words and avoid fancy, technical, or over-dramatic language. Keep it conversational and easy to follow.

EXPLANATION RULES:
1. EVERY single move must be explained.
2. DO NOT say for example this move is a fork or deflection or zugzwang or any tactic if its not. WHENEVER you need to see tactic, MAKE SURE that you PROPERLY ANALYZE all piece relationships on the board AND MAKE SURE that you do not say for example "This move is deflection" or "Wins the queen" when it does not actually do that at all. Factual accuracy is very important
2. FACTUAL ACCURACY (MOST IMPORTANT): Every single word you write must be factually correct and relevant. Never write anything wrong, exaggerated, or unrelated to what actually happened on the board. Everything must match the real purpose, threat, and effect of the move exactly. When in doubt, say less — better to be brief and correct than long and wrong.
3. LENGTH MATCHES IMPORTANCE: Do not pad explanations; write only as much as each move deserves. For simple, routine moves with no special purpose (like a plain quiet developing move), keep it to a short, honest sentence or two and do not overstate it. Always clearly state the main purpose of a move and any genuine threats it handles. When a move is important, hard to follow, has multiple purposes, or is a key moment (a mistake, blunder, or critical move with a better alternative), you may explain it at length, even 4-5 sentences — but only if every word stays factually correct and makes sense.
4. COMPLEXITY SCALING: For mistakes, blunders, or critical moments, expand to 4-5 sentences explaining the strategic failure and why the suggested line was better.
5. INTEGRATE DATA: Use the provided "Best line" data to explain tactical or positional concepts, but always frame it as your own Grandmaster insight.
6. NO ROBOTIC TONE: Vary your sentence structure and avoid robotic phrasing.
7. POSITIONAL CONTEXT: Mention pawn structures, weak squares, and initiative only when they are truly relevant to the move.
8. INTERPRETING ANNOTATIONS: For mistakes, blunders, or inaccuracies, the PGN annotations will contain:
   - "Best move that should have been played": The move the player should have made (prefixed with the move number, e.g., "6. cxd4" if White or "6... cxd5" if Black).
   - "Line after the move that should have been played": The moves that would follow the best move (alternating between players).
   - "Engine line after the actual played move": The moves that follow the mistake starting with the opponent's best response.
   Ensure you attribute these moves to the correct player (referring to them as "You" or "the opponent" based on who plays). Never recommend an opponent's move as a move the user should have played, or vice versa.

DO NOT output markdown formatting like ```json. Output ONLY the raw JSON array.''';

/// The system prompt for a single request, with the coach told which language
/// to answer in.
///
/// Deliberately layered on top of [_systemPrompt] rather than folded into it:
/// that constant is kept byte-identical to the website's
/// `CHESS_COACH_SYSTEM_PROMPT` (see `Website/lib/review-logic.ts`) so the two
/// stay diffable. The answer language is a per-request concern anyway — the
/// same device can switch language between two reviews of the same game.
///
/// The directive translates the *explanations* only. The JSON keys, the move
/// numbers and the SAN notation are contract rather than prose, and must
/// survive untouched or the parser downstream stops understanding the reply.
String _buildSystemPrompt(String? language) {
  if (language == null) return _systemPrompt;
  return '$_systemPrompt\n\n'
      'LANGUAGE: $language\n'
      'Write every explanation in $language, the way a native-speaking coach '
      'would say it naturally. Translate only the "explanation" text: keep the '
      'JSON keys, the move numbers and the SAN move notation exactly as '
      'specified above.';
}

String _buildUserPrompt(String enhancedPgn, String userColor) =>
    'The student played as $userColor.\n\n'
    'Analyze this Enhanced PGN and provide the personalized coach-style JSON array of move-by-move explanations. Output ONLY the JSON array.\n\n'
    'ENHANCED PGN:\n$enhancedPgn';

// ============================================================================
// 2. ENHANCED PGN GENERATOR — Dart port of Website/lib/review-logic.ts
//    generateEnhancedPgn() with the same PV formatting.
// ============================================================================
String _formatPv(List<String> pv, int startIndex, {bool skipFirstEllipsis = false}) {
  final buf = StringBuffer();
  int currIndex = startIndex;
  for (int j = 0; j < pv.length; j++) {
    final moveNum = (currIndex ~/ 2) + 1;
    final isWhite = currIndex % 2 == 0;
    if (isWhite) {
      buf.write('$moveNum. ${pv[j]} ');
    } else {
      if (j == 0) {
        if (skipFirstEllipsis) {
          buf.write('${pv[j]} ');
        } else {
          buf.write('$moveNum... ${pv[j]} ');
        }
      } else {
        buf.write('${pv[j]} ');
      }
    }
    currIndex++;
  }
  return buf.toString().trim();
}

String generateEnhancedPgn(List<String> historySan, List<Map<String, dynamic>> moveAnalyses) {
  final buf = StringBuffer();
  for (int i = 0; i < historySan.length; i++) {
    final moveNumber = (i ~/ 2) + 1;
    final isWhite = i % 2 == 0;
    final move = historySan[i];
    final analysis = moveAnalyses[i];
    if (isWhite) {
      buf.write('$moveNumber. $move');
    } else {
      buf.write(' $move');
    }

    if (analysis.isEmpty) {
      buf.write(' ');
      continue;
    }

    final category = (analysis['category'] as String?) ?? 'Best';

    if (category == 'Book') {
      buf.write('(book) ');
    } else if (category == 'Blunder' || category == 'Mistake' || category == 'Inaccuracy') {
      final classification =
          category[0].toUpperCase() + category.substring(1).toLowerCase();

      final isWhiteMove = i % 2 == 0;
      final pvList = (analysis['pv'] as List<dynamic>?)?.cast<String>() ?? [];
      final pvAfterList =
          (analysis['pvAfter'] as List<dynamic>?)?.cast<String>() ?? [];

      final bestMoveRaw = pvList.isNotEmpty ? pvList[0] : 'Unknown';
      final bestMoveFormatted = bestMoveRaw != 'Unknown'
          ? (isWhiteMove ? '$moveNumber. $bestMoveRaw' : '$moveNumber... $bestMoveRaw')
          : 'Unknown';

      final bestFollowUpFormatted =
          pvList.length > 1 ? _formatPv(pvList.sublist(1, pvList.length.clamp(1, 5)), i + 1, skipFirstEllipsis: true) : '';

      final pvAfterFormatted =
          pvAfterList.isNotEmpty ? _formatPv(pvAfterList.sublist(0, pvAfterList.length.clamp(0, 4)), i + 1) : '';

      final annotation = StringBuffer('($classification');
      if ((analysis['evalBefore'] as String?)?.isNotEmpty == true &&
          (analysis['evalAfter'] as String?)?.isNotEmpty == true) {
        annotation.write(', Eval: ${analysis['evalBefore']} -> ${analysis['evalAfter']}');
      }
      if (bestMoveFormatted != 'Unknown') {
        annotation.write(', : Best move that should have been played: $bestMoveFormatted');
        if (bestFollowUpFormatted.isNotEmpty) {
          annotation.write(' Line after the move that should have been played: $bestFollowUpFormatted');
        }
      }
      if (pvAfterFormatted.isNotEmpty) {
        annotation.write(', Engine line after the actual played move: $pvAfterFormatted');
      }
      annotation.write(') ');
      buf.write(annotation.toString());
    } else {
      final classification =
          category[0].toUpperCase() + category.substring(1).toLowerCase();
      final evalAfter = analysis['evalAfter'] as String?;
      buf.write('($classification');
      if (evalAfter != null && evalAfter.isNotEmpty) {
        buf.write(', Eval: $evalAfter');
      }
      buf.write(') ');
    }
  }
  return buf.toString().trim();
}

// ============================================================================
// 3. AI COACH SERVICE — direct Gemini call from the device.
//
//    Keys are never stored: a `security definer` Supabase RPC atomically
//    hands one back per call and is released immediately after use.
// ============================================================================
class AICoachNote {
  final String move;
  final String explanation;

  const AICoachNote({required this.move, required this.explanation});

  factory AICoachNote.fromJson(Map<String, dynamic> json) => AICoachNote(
        move: json['move'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );
}

class _AIKey {
  final String id;
  final String key;
  const _AIKey({required this.id, required this.key});
}

/// A terminal failure of the coach request. Carries a clean message and
/// surfaces through `toString()` as exactly that message. The UI maps any
/// failure to the single user-presentable 'Server Error, Please try again
/// later.' message instead of silently returning nothing.
///
/// [AICoachException.kind] distinguishes key-pool exhaustion from request
/// failure (the website's error.message === 'No active API keys available.'
/// check) so the retry loops can mirror the site's behaviour exactly.
class AICoachException implements Exception {
  final String message;
  final AICoachErrorKind kind;
  const AICoachException(this.message, {this.kind = AICoachErrorKind.request});

  @override
  String toString() => message;
}

enum AICoachErrorKind { keysExhausted, request }

class AICoachService {
  AICoachService._();

  static const Duration _timeout = Duration(minutes: 5);

  // Retry budget, split to mirror the website's two-layer retry exactly:
  // - route.ts (analyze) outer loop: 3 attempts, ONLY for key exhaustion,
  //   waiting 3s between tries.
  // - generateGameAnalysis() inner loop: 5 rounds, ONLY for request
  //   failures, each round immediately acquiring a fresh key (no delay).
  static const int _maxKeyAttempts = 3;
  static const int _maxRequestAttempts = 5;

  /// Pause between key-exhaustion retries (website: `setTimeout(r, 3000)`).
  /// The 5-minute rate-limit backoff itself lives server-side in
  /// `release_ai_key`, which marks the throttled key `rate_limited` with a
  /// `retry_after` deadline so `_acquireKey` picks a DIFFERENT key.
  static const Duration _busyKeyRetryDelay = Duration(seconds: 3);

  /// Builds the Enhanced PGN and calls Gemini directly from the device.
  ///
  /// Retry structure mirrors the website stack exactly:
  /// - OUTER loop (route.ts): retries KEY ACQUISITION failures — the device
  ///   equivalent of `err.message === 'No active API keys available.'` —
  ///   waiting [_busyKeyRetryDelay] between rounds.
  /// - INNER loop (generateGameAnalysis): retries REQUEST failures — each
  ///   round acquires a FRESH key (the failed key having been released and
  ///   marked `rate_limited` by `release_ai_key` when applicable), so a
  ///   single throttled/failed key never burns the whole budget.
  static Future<List<AICoachNote>> requestExplanations({
    // Language the coach must answer in, as an English language name (for
    // example 'Hindi' or 'Portuguese (Brazil)'). Omit to use the app's current
    // display language; pass it explicitly to pin a language in tests.
    String? language,
    required List<String> moveHistory,
    required List<Map<String, dynamic>> moveAnalyses,
    required String userColor,
  }) async {
    final enhancedPgn = generateEnhancedPgn(moveHistory, moveAnalyses);
    // Which language the coach writes back in. Defaults to whatever the app is
    // displaying right now, which `LocaleService.resolved` tracks for exactly
    // this kind of non-widget caller — the alternative was threading a locale
    // parameter through three service layers that do not care about it.
    final coachLanguage =
        language ?? LocaleService.promptNameFor(LocaleService.resolved);
    final model = (dotenv.env['MODEL'] ?? '').trim();
    if (model.isEmpty) {
      AppLogger.error('[AICoachService] MODEL env variable not set.');
      throw const AICoachException('MODEL environment variable is not defined');
    }

    // Website: route.ts step 5 — the outer retry loop deals ONLY with key
    // exhaustion ('No active API keys available.'), waiting 3s between
    // attempts. Any other error propagates immediately.
    for (int attempt = 1; attempt <= _maxKeyAttempts; attempt++) {
      try {
        return await _generateWithRetries(
            enhancedPgn, userColor, model, coachLanguage);
      } on AICoachException catch (e) {
        if (e.kind != AICoachErrorKind.keysExhausted) rethrow;
        if (attempt == _maxKeyAttempts) rethrow;
        AppLogger.debug('[AICoachService] Key pool busy (attempt $attempt/$_maxKeyAttempts), retrying...');
        await Future<void>.delayed(_busyKeyRetryDelay);
      }
    }
    throw const AICoachException(
      'No active API keys available.',
      kind: AICoachErrorKind.keysExhausted,
    );
  }

  /// Website: generateGameAnalysis() — up to [_maxRequestAttempts] rounds,
  /// each round acquiring a FRESH key from the pool (the previous round's
  /// key was released, and marked `rate_limited` by `release_ai_key` when it
  /// hit a 429, so the round-robin naturally moves to a healthy key).
  /// Acquisition failure throws immediately — the caller retries.
  static Future<List<AICoachNote>> _generateWithRetries(
    String language,
    String enhancedPgn,
    String userColor,
    String model,
  ) async {
    for (int attempt = 1; attempt <= _maxRequestAttempts; attempt++) {
      final key = await _acquireKey();
      if (key == null) {
        AppLogger.warn('[AICoachService] No active API keys available (round $attempt/$_maxRequestAttempts).');
        throw const AICoachException(
          'No active API keys available.',
          kind: AICoachErrorKind.keysExhausted,
        );
      }

      try {
        final response = await http
            .post(
              Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${key.key}',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {'role': 'user', 'parts': [{'text': _buildUserPrompt(enhancedPgn, userColor)}]}
                ],
                'systemInstruction': {
                  'parts': [{'text': _buildSystemPrompt(language)}]
                },
                'generationConfig': {
                  'temperature': 0.2,
                  'responseMimeType': 'application/json',
                }
              }),
            )
            .timeout(_timeout);

        if (response.statusCode != 200) {
          throw _GeminiError(response.statusCode, response.body);
        }

        await _releaseKey(key.id, success: true);

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text == null || text.isEmpty) {
          throw const _EmptyResponseError();
        }

        List<dynamic> explanationsList;
        try {
          explanationsList = jsonDecode(text) as List<dynamic>;
        } catch (_) {
          final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
          if (match != null) {
            explanationsList = jsonDecode(match.group(0)!) as List<dynamic>;
          } else {
            throw const _EmptyResponseError();
          }
        }

        return explanationsList
            .map((e) => AICoachNote.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (error) {
        // Mirror the website's releaseKey call: 429s get the key marked
        // rate_limited / exhausted_daily (with retry_after) server-side, 403
        // suspends it, anything else just frees the busy lock.
        final status = error is _GeminiError ? error.status : null;
        final payload = error is _GeminiError ? error.payload : null;
        await _releaseKey(key.id, success: false, status: status, errorPayload: payload);

        if (attempt == _maxRequestAttempts) {
          AppLogger.error('[AICoachService] AI request failed after $attempt rounds: $error');
          throw const AICoachException('AI request failed after maximum retries.');
        }
        // No artificial delay here — the website's loop immediately re-
        // acquires (a different, healthy) key on the next round.
      }
    }
    throw const AICoachException('AI request failed after maximum retries.');
  }

  /// Pulls an ephemeral key via Supabase's `security definer` RPC.
  ///
  /// Returns `null` ONLY when the pool has no free active key (all busy /
  /// rate-limited / suspended). An RPC failure is rethrown as
  /// [AICoachException] — swallowing it would disguise a connectivity or
  /// configuration problem as key exhaustion and make the retry loops burn
  /// their whole budget on something no delay can fix.
  static Future<_AIKey?> _acquireKey() async {
    dynamic res;
    try {
      res = await SupabaseService.client.rpc('acquire_ai_key');
    } catch (e) {
      AppLogger.warn('[AICoachService] Key acquisition RPC failed: $e');
      throw AICoachException('Key acquisition failed: $e');
    }
    if (res == null || res is! Map) return null;
    final id = res.containsKey('id') ? res['id']?.toString() : null;
    final key = res.containsKey('key') ? res['key']?.toString() : null;
    if (id == null || key == null) return null;
    return _AIKey(id: id, key: key);
  }

  /// Returns the key and its provider status back to Supabase (busy-free + status).
  static Future<void> _releaseKey(
    String keyId, {
    required bool success,
    int? status,
    Map<String, dynamic>? errorPayload,
  }) async {
    try {
      await SupabaseService.client.rpc('release_ai_key', params: {
        'p_key_id': keyId,
        'p_success': success,
        'p_status': status,
        'p_error': errorPayload,
      });
    } catch (e) {
      // Release failure must never propagate — worst case the busy lock
      // recovers on the server via the 5-minute deadlock timeout.
      AppLogger.warn('[AICoachService] Key release RPC failed: $e');
    }
  }
}

class _GeminiError implements Exception {
  final int status;
  final String raw;
  final Map<String, dynamic>? payload;
  _GeminiError(this.status, this.raw) : payload = _tryDecode(raw);

  static Map<String, dynamic>? _tryDecode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'GeminiError($status): $raw';
}

/// A 200 response whose text is empty or cannot be parsed into a JSON array.
/// Distinguished from a plain failure so the key is released without a
/// status (staying `active`) and the same key can be retried — matching the
/// website's generateGameAnalysis behaviour.
class _EmptyResponseError implements Exception {
  const _EmptyResponseError();

  @override
  String toString() => 'Empty/unparseable response from model.';
}