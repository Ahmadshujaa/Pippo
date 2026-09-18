import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

/// Width split of the practice row: the daily puzzle tile is narrower than the
/// tactics tile.
const int _kDailyFlex = 4;
const int _kTacticsFlex = 6;

class _HomeState extends State<Home> {
  UserStats _stats = UserStats.empty();
  // Placeholder until [_loadLocalData] answers. The greeting is behind the
  // loading spinner until then, so this value is never rendered.
  String _displayName = '';
  PlanStatus _planStatus = PlanStatus.guest;
  List<CourseModel> _courses = [];
  UserCourseProgressSnapshot _courseProgress =
      const UserCourseProgressSnapshot(courses: []);
  int _puzzleRating = MixedPuzzleService.initialRating;
  int _streak = 0;
  int _gamesToday = 0;
  bool _isLoading = true;

  bool _dailyPuzzleSolved = false;

  /// Board shown in the Daily Puzzle tile's preview. Owned by this screen and
  /// disposed with it.
  ChessboardController? _dailyPreviewController;
  ChessboardSettings _dailyPreviewSettings = const ChessboardSettings();

  /// True while a user is signed in — drives whether the plan badge is shown.
  bool get _isSignedIn => AuthService.userId != null;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Loads the screen in two phases so it is usable immediately.
  ///
  /// Phase 1 is everything the device already has: the display name and plan
  /// cached at sign-in (see [UserProfileStore]), the local streak, the merged
  /// puzzle rating and today's game count. Phase 2 is the network refresh.
  /// Waiting for phase 2 first is what used to leave the user staring at a
  /// spinner on a slow or offline connection — and left them signed out of
  /// their own greeting even though their session was perfectly valid.
  Future<void> _fetchData() async {
    await _loadLocalData();
    // The daily puzzle needs the network only once a day, so it is loaded in
    // the background rather than holding up the stats above it.
    unawaited(_loadDailyPuzzle());
    await _refreshFromServer();
  }

  @override
  void dispose() {
    _dailyPreviewController?.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final userId = AuthService.userId;

    // The cached profile is keyed by account id, so a stale cache from a
    // previous sign-in can never leak into the current session.
    final cached = await UserProfileStore.load(userId: userId);

    // The puzzle rating is the same value the puzzles screens read via
    // MixedPuzzleService — for signed-in users it first merges in the copy
    // mirrored on their profile (highest wins), which is a no-op for guests.
    // The streak is local-only: bootstrap already registered today's check-in.
    final puzzleRating = await MixedPuzzleService.syncWithAccount();
    final streak = await StreakService.getStreak();
    final gamesToday = await GameStorageService.getGamesPlayedToday();

    if (!mounted) return;
    setState(() {
      _displayName = (cached?.hasDisplayName ?? false)
          ? cached!.displayName!
          : AppLocalizations.of(context).defaultPlayerName;
      _planStatus = _isSignedIn
          ? (cached?.plan ?? PlanStatus.free)
          : PlanStatus.guest;
      _puzzleRating = puzzleRating;
      _streak = streak;
      _gamesToday = gamesToday;
      _isLoading = false;
    });
  }

  Future<void> _refreshFromServer() async {
    // Guests have no account data to fetch, and the stats call would only
    // return defaults — skip it rather than making them wait on the network.
    if (!_isSignedIn) {
      final courses = await CourseApiService.getAllCourses();
      if (mounted) {
        setState(() {
          _courseProgress = const UserCourseProgressSnapshot(courses: []);
          _courses = courses;
          _stats = UserStats.empty();
        });
      }
      return;
    }

    final results = await Future.wait([
      UserApiService.getStats(),
      AuthApiService.fetchDisplayName(),
      CourseApiService.getAllCourses(),
      AuthApiService.getPlanStatus(),
      UserCourseProgressService.getProgress(),
    ]);

    if (!mounted) return;
    setState(() {
      _stats = results[0] as UserStats;
      final profile = results[1] as DisplayNameResult;
      // Only overwrite the greeting when the server actually answered with a
      // name; an offline read must not wipe the cached one.
      if (profile.success && profile.hasDisplayName) {
        _displayName = profile.displayName!;
      }
      _courseProgress = results[4] as UserCourseProgressSnapshot;
      final fetchedCourses = results[2] as List<CourseModel>;
      final started = fetchedCourses
          .where((course) => _courseProgress.forCourse(course.slug)?.hasStarted ?? false)
          .toList();
      final notStarted = fetchedCourses
          .where((course) => !(_courseProgress.forCourse(course.slug)?.hasStarted ?? false))
          .toList();
      _courses = [...started, ...notStarted];
      _planStatus = results[3] as PlanStatus;
    });
    // A signed-in account the server reports without a display name (the sign-up
    // prompt never completed, or the name write failed) is asked for one instead
    // of being left with the generic "Player" greeting.
    if (!(results[1] as DisplayNameResult).hasDisplayName) {
      await _promptForDisplayNameIfMissing();
    }
  }

  /// Sends a signed-in account that the server confirms has no display name to
  /// the name prompt.
  ///
  /// The account may never have finished the sign-up prompt (or the name write
  /// failed), and without this the app would keep using the generic "Player"
  /// greeting forever. Only a positively confirmed missing name redirects — the
  /// check re-reads the profile, so an offline read cannot strand the user on a
  /// screen whose save needs the network.
  Future<void> _promptForDisplayNameIfMissing() async {
    if (!mounted || !_isSignedIn) return;
    if (!await AuthApiService.confirmedNoDisplayName()) return;
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  // ---------------------------------------------------------------------------
  // Daily Puzzle
  // ---------------------------------------------------------------------------
  // The tile previews the position the player actually has to solve, so the
  // stored FEN's leading move (the opponent's blunder) is played on the preview
  // board, exactly like the daily puzzle screen does before handing over.

  Future<void> _loadDailyPuzzle() async {
    try {
      final puzzle = await DailyPuzzleService.getDailyPuzzle();
      final solved = await DailyPuzzleService.isSolvedToday();
      if (!mounted) return;
      _applyDailyPuzzle(puzzle, solved: solved);
    } catch (_) {
      // Offline with no cached puzzle for today: the tile falls back to its
      // placeholder and the play screen offers a retry.
    }
  }

  void _applyDailyPuzzle(MixedPuzzle puzzle, {required bool solved}) {
    // One long-lived preview board: reloading the position reuses it instead of
    // handing the widget a fresh controller on every refresh.
    final controller =
        _dailyPreviewController ?? ChessboardController(fen: puzzle.fen);
    controller.loadFen(puzzle.fen);

    if (puzzle.solution.isNotEmpty) {
      final blunder = puzzle.solution.first.toLowerCase().trim();
      if (blunder.length >= 4) {
        controller.makeMove(
          blunder.substring(0, 2),
          blunder.substring(2, 4),
          promotion: blunder.length == 5 ? blunder[4] : 'q',
        );
      }
    }

    // The player takes the side opposite the doomed FEN (which is the opponent
    // to move), same as the play screen.
    final fenParts = puzzle.fen.split(' ');
    final blundererIsWhite = fenParts.length > 1 ? fenParts[1] == 'w' : true;

    setState(() {
      _dailyPreviewController = controller;
      _dailyPreviewSettings = _dailyPreviewSettings.copyWith(
        orientation:
            blundererIsWhite ? BoardOrientation.black : BoardOrientation.white,
        showCoordinates: false,
      );
      _dailyPuzzleSolved = solved;
    });
  }

  /// Opens the daily puzzle and refreshes the tile afterwards so a solve is
  /// reflected straight away.
  Future<void> _openDailyPuzzle() async {
    await Navigator.pushNamed(context, '/daily-puzzle');
    if (!mounted) return;
    await _loadDailyPuzzle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        OfflineBanner(),
                        const SizedBox(height: 16),
                        _buildHelloHeader(theme),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 28),
                        _buildSectionHeader(context, l10n.coursesSection,
                            () => Navigator.pushNamed(context, '/courses')),
                        const SizedBox(height: 12),
                        _buildCoursesSection(context),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                            context, l10n.dailyPracticeSection, null),
                        const SizedBox(height: 12),
                        _buildPracticeGrid(context),
                        const SizedBox(height: 120),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Material(
        color: AppColors.surfaceSubtleOf(context),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/download-model'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PippoAvatar(size: 28, cornerRadius: 8),
                const SizedBox(width: 10),
                Text(
                  l10n.playNow,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.home_rounded, l10n.navHome, true,
                  onTap: () => Navigator.pushReplacementNamed(context, '/home')),
              _buildNavItem(
                  context, Icons.menu_book_outlined, l10n.navCourses, false,
                  onTap: () => Navigator.pushNamed(context, '/courses')),
              _buildNavItem(
                  context, Icons.extension_rounded, l10n.navPuzzles, false,
                  onTap: () => Navigator.pushNamed(context, '/puzzles')),
              _buildNavItem(
                  context, Icons.analytics_outlined, l10n.navAnalysis, false,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/analysis')),
              _buildNavItem(context, Icons.menu_rounded, l10n.navMenu, false,
                  onTap: () =>
                      Navigator.pushNamed(context, '/profile-settings')),
            ],
          ),
        ),
      ),
    );
  }

  /// One bottom-bar entry.
  ///
  /// The destination arrives as [onTap] instead of being inferred from [label]:
  /// [label] is translated now, so routing off its value would send every
  /// non-English user to the wrong screen.
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isActive ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        // The active tab stays inert but still ripples, matching the previous
        // behaviour, which guarded inside the callback.
        if (!isActive) onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Short plan badge for the home app bar. Takes the localizations rather than
  /// reading them, because the tier names are translated and this is a plain
  /// getter without a widget to hang them off.
  String _planBadgeLabel(AppLocalizations l10n) {
    switch (_planStatus.plan) {
      case 'admin':
        return l10n.planBadgeAdmin;
      case 'free':
        return l10n.planBadgeFree;
      default:
        return l10n.planBadgePro;
    }
  }

  /// Wording for the plan pill under the greeting. Premium tiers all read as
  /// PRO, matching the badge in the app bar.
  String _planChipLabel(AppLocalizations l10n) =>
      l10n.planChipLabel(_planBadgeLabel(l10n));

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFDE047), Color(0xFFFB923C), Color(0xFFEF4444)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_streak',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Shown for guests too: "FREE" is the honest answer for someone with
        // no plan, and hiding the badge entirely left the top bar looking
        // broken for signed-out users.
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/pricing'),
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond_outlined,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 5),
                Text(
                  _planBadgeLabel(l10n),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () =>
              ThemeService.setTheme(isDark ? ThemeMode.light : ThemeMode.dark),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtleOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 18,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelloHeader(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap rather than Row: a long display name pushes the plan pill onto
        // the next line instead of overflowing on a narrow phone.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              l10n.helloGreeting(_displayName),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            _buildPlanChip(theme),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.homeSubtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Plan pill next to the greeting. Tappable so it doubles as the upsell
  /// entry point, like the badge in the app bar.
  Widget _buildPlanChip(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isPremium = _planStatus.isAdmin || _planStatus.isPro;
    final premium = AppColors.primary;
    final neutral = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final color = isPremium ? premium : neutral;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/pricing'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPremium
              ? premium.withValues(alpha: 0.12)
              : AppColors.surfaceSubtleOf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPremium ? Icons.diamond_rounded : Icons.person_outline_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              _planChipLabel(l10n),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback? onSeeAll) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.seeAll,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats section (above Courses)
  // ---------------------------------------------------------------------------
  // One "TODAY" snapshot: games against Pippo, puzzle rating (the stored
  // value the puzzles screens read via MixedPuzzleService), local daily
  // streak, and chapters done. Full-width rows so labels and values each get the
  // whole card width and nothing gets squeezed. Flat everywhere: no
  // gradients, no shadows.

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayLabel,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_gamesToday',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.gamesVsPippo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          const SizedBox(height: 16),
          // ---- rating / streak / chapters -----------------------------------
          _buildOverallRow(
            theme,
            icon: Icons.extension_rounded,
            label: l10n.puzzleRatingLabel,
            value: '$_puzzleRating',
          ),
          const SizedBox(height: 14),
          _buildOverallRow(
            theme,
            icon: Icons.local_fire_department_rounded,
            label: l10n.dailyStreakLabel,
            value: '$_streak',
          ),
          const SizedBox(height: 14),
          _buildOverallRow(
            theme,
            icon: Icons.menu_book_rounded,
            label: l10n.chaptersDoneLabel,
            value: '${_stats.chaptersMastered}',
          ),
        ],
      ),
    );
  }

  /// One row in the TODAY list: a plain gray icon, the label, then the
  /// value right-aligned. The value is the dynamic part, so it gets the
  /// Expanded width with textAlign end — it can ellipsize but never push
  /// the row past its bounds regardless of how wide the value gets.
  Widget _buildOverallRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final gray = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final leading = Icon(icon, size: 19, color: gray);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(dimension: 22, child: Center(child: leading)),
        const SizedBox(width: 10),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  /// Two practice tiles. The Daily Puzzle one is deliberately narrower: it is a
  /// board preview of today's puzzle with its label underneath, rather than an
  /// icon card.
  Widget _buildPracticeGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The row's height is computed instead of intrinsic: the daily tile's board
    // is a square that follows the tile width, and an IntrinsicHeight pass would
    // ask that board for its height at the FULL row width (a flex child is
    // measured before the space is distributed), which would make the row as
    // tall as a full-width board.
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalFlex = _kDailyFlex + _kTacticsFlex;
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 340.0;
        final dailyTileWidth = (available - 12) * _kDailyFlex / totalFlex;

        return SizedBox(
          // Board + caption + tile padding, with a few pixels of slack.
          height: dailyTileWidth + 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: _kDailyFlex,
                child: _buildDailyPuzzleTile(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: _kTacticsFlex,
                child: _buildPracticeTile(
                  context,
                  icon: Icons.extension_outlined,
                  iconColor: AppColors.secondary,
                  title: l10n.tacticsTrainingTitle,
                  subtitle: l10n.tacticsTrainingSubtitle,
                  onTap: () => Navigator.pushNamed(context, '/puzzles'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Daily Puzzle tile: a small board showing today's starting position, with
  /// the label (and a check once it is solved) underneath.
  Widget _buildDailyPuzzleTile(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = _dailyPreviewController;

    return GestureDetector(
      onTap: _openDailyPuzzle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller == null)
              // Placeholder while today's puzzle is fetched (or when there is
              // no cached puzzle to show offline).
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtleOf(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    color: AppColors.accent.withValues(alpha: 0.6),
                    size: 28,
                  ),
                ),
              )
            else
              // Preview only — taps belong to the tile itself.
              IgnorePointer(
                child: ChessBoard(
                  controller: controller,
                  settings: _dailyPreviewSettings,
                  showSettingsButton: false,
                  showLastMove: false,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    l10n.dailyPuzzleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_dailyPuzzleSolved) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: enabled ? 0.1 : 0.06),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon,
                      color: enabled
                          ? iconColor
                          : iconColor.withValues(alpha: 0.5),
                      size: 18),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.2,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Courses section: a clean horizontal row of the first 3 courses fetched
  /// from MongoDB, with a See all shortcut to the full library.
  Widget _buildCoursesSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final courses = _courses.take(3).toList();

    if (courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.coursesComingSoon,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: courses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final course = courses[index];
          final progress = _courseProgress.forCourse(course.slug);
          return progress?.hasStarted == true
              ? _buildStartedCourseCard(context, course, progress!)
              : _buildCourseCard(context, course);
        },
      ),
    );
  }

  Widget _buildStartedCourseCard(
    BuildContext context,
    CourseModel course,
    UserCourseProgress progress,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isComplete = progress.chapters.isNotEmpty &&
        progress.chapters.every((chapter) => chapter.isCompleted);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/course-details', arguments: course.slug),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.continueLearning, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (isComplete) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(course.openingName, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 5),
            Text(
                l10n.variationsDone(
                    progress.completedVariationCount, course.variationCount),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/course-details', arguments: course.slug),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
                child: Text(l10n.continueLearningButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isWhite = course.side.toLowerCase() == 'white';
    final sideLabel = isWhite ? l10n.sideWhite : l10n.sideBlack;
    final sideColor = isWhite ? AppColors.secondary : AppColors.primary;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/course-details',
        arguments: course.slug,
      ),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      isWhite ? l10n.sideWhiteInitial : l10n.sideBlackInitial,
                      style: TextStyle(
                        color: sideColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtleOf(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.courseMetaChip(sideLabel, course.chapterCount),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              course.openingName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  }
