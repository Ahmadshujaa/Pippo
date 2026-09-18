import 'package:shared_preferences/shared_preferences.dart';

/// Device-local daily streak — deliberately offline-only.
///
/// Nothing here ever touches Supabase: signing in, signing out or being offline
/// makes no difference, and each device keeps its own count. A "day" is a local
/// calendar day (device timezone):
///
///   * first check-in ever            → 1
///   * check-in on the next day       → +1
///   * another check-in the same day  → unchanged
///   * a whole day missed             → 1 (streak broken)
///
/// A device that is never opened cannot know a day passed, so the streak only
/// advances when the app actually runs — see [registerToday], called from
/// bootstrap on every launch.
class StreakService {
  static const String _kCountKey = 'daily_streak_count';
  static const String _kLastDayKey = 'daily_streak_last_day';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Registers a check-in for today and returns the resulting streak. Safe to
  /// call on every app start — opening the app again on the same day leaves the
  /// count untouched.
  static Future<int> registerToday() async {
    await init();

    final today = _stamp(_dateOnly(DateTime.now()));
    final lastDay = _prefs!.getString(_kLastDayKey);
    if (lastDay == today) return _prefs!.getInt(_kCountKey) ?? 0;

    // Consecutive day → extend; anything else (never checked in before, a day
    // missed, or the clock moved backwards) → start a fresh streak at 1.
    final isConsecutive =
        lastDay != null && lastDay == _stamp(_dayBefore(DateTime.now()));
    final streak = isConsecutive ? (_prefs!.getInt(_kCountKey) ?? 0) + 1 : 1;

    await _prefs!.setString(_kLastDayKey, today);
    await _prefs!.setInt(_kCountKey, streak);
    return streak;
  }

  /// The stored streak without registering a check-in.
  static Future<int> getStreak() async {
    await init();
    return _prefs!.getInt(_kCountKey) ?? 0;
  }

  /// The last day that counted as a check-in, `yyyy-MM-dd` or null.
  static Future<String?> getLastCheckInDay() async {
    await init();
    return _prefs!.getString(_kLastDayKey);
  }

  /// Wipes the local streak (used by tests / a future "reset progress" action).
  static Future<void> clear() async {
    await init();
    await _prefs!.remove(_kCountKey);
    await _prefs!.remove(_kLastDayKey);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The calendar day before [d]. Going through DateTime normalises month and
  /// year boundaries (day 0 = last day of the previous month) and stays correct
  /// across DST shifts, unlike subtracting a fixed 24 hours.
  static DateTime _dayBefore(DateTime d) => DateTime(d.year, d.month, d.day - 1);

  static String _stamp(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
