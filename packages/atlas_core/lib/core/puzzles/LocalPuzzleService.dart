import 'package:shared_preferences/shared_preferences.dart';

class LocalPuzzleService {
  static const String _key = 'solved_puzzle_ids';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveSolved(String puzzleId) async {
    await init();
    final solved = getSolvedIds();
    if (!solved.contains(puzzleId)) {
      solved.add(puzzleId);
      await _prefs!.setStringList(_key, solved.toList());
    }
  }

  static Set<String> getSolvedIds() {
    if (_prefs == null) return {};
    final list = _prefs!.getStringList(_key);
    return list?.toSet() ?? {};
  }

  static bool isSolved(String puzzleId) {
    return getSolvedIds().contains(puzzleId);
  }
}
