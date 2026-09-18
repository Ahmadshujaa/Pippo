import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_core/core/puzzles/MixedPuzzleService.dart';
import 'package:atlas_core/core/user/DailyUsageService.dart';

/// Local persistence for puzzles the user downloaded for offline solving.
///
/// Downloads replace the previous set (like a fresh batch) so the user is
/// always downloading "N brand-new puzzles". Solved puzzles are DELETED
/// immediately — the stored set only ever contains unsolved puzzles, which is
/// why it can be used as an offline fallback when there is at least one left.
class DownloadedPuzzlesService {
  static const String _key = 'downloaded_puzzles';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static List<MixedPuzzle> getPuzzles() {
    if (_prefs == null) return [];
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => MixedPuzzle.fromJson(e as Map<String, dynamic>))
          .where((p) => p.id.isNotEmpty && p.fen.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Number of downloaded puzzles still available to solve.
  static int getPuzzleCount() => getPuzzles().length;

  /// Fetches [count] fresh puzzles from the online puzzle source (over the
  /// same rating window the mixed player uses) and stores them locally as the
  /// new "Downloaded Puzzles" batch. Throws when offline / when the source
  /// cannot be reached, so callers can surface the failure.
  static Future<void> downloadPuzzles(int count) async {
    await init();
    final plan = await DailyUsageService.currentPlanStatus();
    if (!plan.isPro) {
      throw StateError('Offline puzzle downloads require Pro');
    }
    final fetched = await MixedPuzzleService.fetchBatchFromTurso(
      ratingOverride: await MixedPuzzleService.getRating(),
      count: count,
    );
    await _write(fetched);
  }

  /// Deletes a downloaded puzzle once it has been solved — completed puzzles
  /// do not stay on disk. Returns true when a puzzle was removed.
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

  static Future<void> _write(List<MixedPuzzle> puzzles) async {
    final encoded =
        jsonEncode(puzzles.map((p) => p.toJson()).toList(growable: false));
    await _prefs!.setString(_key, encoded);
  }
}
