class UserStats {
  final int openingsLearned;
  final int chaptersMastered;
  final int currentStreak;

  UserStats({
    required this.openingsLearned,
    required this.chaptersMastered,
    required this.currentStreak,
  });

  factory UserStats.empty() {
    return UserStats(
      openingsLearned: 0,
      chaptersMastered: 0,
      currentStreak: 0,
    );
  }
}

/// User stats for the home screen.
///
/// The app is standalone and no longer tracks user course progress, so there
/// is no local source for these stats anymore: they are reported as zeros.
class UserApiService {
  static Future<UserStats> getStats() async {
    return UserStats.empty();
  }
}
