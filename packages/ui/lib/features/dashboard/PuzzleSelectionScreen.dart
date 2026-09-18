import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AppBottomNav.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';
import 'package:atlas_ui/features/puzzles/DownloadPuzzlesDialog.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

/// Puzzle library screen.
///
/// A clean, typography-driven overview of the puzzle trainer. The layout is
/// intentionally calm: flat bordered cards on the warm ivory scaffold, no
/// oversized hero banners, and theme entries that rely on a thin accent bar
/// and text instead of icons so the list stays quiet and modern.
class PuzzleSelectionScreen extends StatefulWidget {
  const PuzzleSelectionScreen({super.key});

  @override
  State<PuzzleSelectionScreen> createState() => _PuzzleSelectionScreenState();
}

class _PuzzleSelectionScreenState extends State<PuzzleSelectionScreen> {
  // Live count of unsolved puzzles generated from the user's Pippo games.
  // Populated from UserPuzzleStorageService and refreshed whenever the
  // player screen is popped.
  int _puzzlesRemaining = 0;

  // Live count of puzzles previously downloaded for offline solving. This is
  // the value that gates the "Play Downloaded Puzzles" entry point (only ever
  // offered when the device is offline AND at least one puzzle is stored).
  int _downloadedCount = 0;

  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _refreshPuzzleCount();
    _refreshDownloadedCount();
  }

  Future<void> _refreshPuzzleCount() async {
    await UserPuzzleStorageService.init();
    if (!mounted) return;
    setState(() {
      _puzzlesRemaining = UserPuzzleStorageService.getPuzzleCount();
    });
  }

  Future<void> _refreshDownloadedCount() async {
    await DownloadedPuzzlesService.init();
    if (!mounted) return;
    setState(() {
      _downloadedCount = DownloadedPuzzlesService.getPuzzleCount();
    });
  }

  Future<void> _onSolveNow(BuildContext context) async {
    if (_puzzlesRemaining == 0) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noPuzzlesFromGamesMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.pushNamed(context, '/my-puzzles');
    _refreshPuzzleCount();
  }

  // =========================================================================
  // DOWNLOAD / OFFLINE FLOW
  // =========================================================================

  /// Opens the amount-selection dialog, then downloads that many puzzles into
  /// local storage ("Downloaded Puzzles") so they can be solved offline.
  Future<void> _onDownloadPuzzles() async {
    if (_isDownloading) return;

    // Cache the messenger synchronously so snackbars can be shown after the
    // async dialog/download steps without re-reading the BuildContext.
    final messenger = ScaffoldMessenger.of(context);

    // Read the entitlement before showing the amount selector. The same check
    // is repeated after the dialog, immediately before the network request.
    final initialPlan = await DailyUsageService.currentPlanStatus();
    if (!mounted) return;

    final count = await showDialog<int>(
      context: context,
      builder: (context) => DownloadPuzzlesDialog(
        canDownload: initialPlan.isPro,
      ),
    );
    if (count == -1) {
      if (mounted) Navigator.pushNamed(context, '/pricing');
      return;
    }
    if (count == null || count < 10) return;

    final currentPlan = await DailyUsageService.currentPlanStatus();
    if (!currentPlan.isPro) {
      if (mounted) Navigator.pushNamed(context, '/pricing');
      return;
    }

    // Force an immediate connectivity check so download never starts with a
    // dead network (the periodic monitor also runs in the background).
    if (!await ConnectivityService.checkNow()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'No internet connection — puzzles could not be downloaded.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      await DownloadedPuzzlesService.downloadPuzzles(count);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.puzzlesDownloadedSuccess(count)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Could not download puzzles. Check your connection and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _refreshDownloadedCount();
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Plays the stored "Downloaded Puzzles" set. Only reachable when the
  /// device is offline — when online this entry point is never shown and the
  /// player always fetches a fresh batch.
  Future<void> _onPlayDownloaded(BuildContext context) async {
    if (_downloadedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No downloaded puzzles available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.pushNamed(context, '/downloaded-puzzles');
    _refreshDownloadedCount();
  }

  // Five representative practice themes drawn from themes.txt (repo root):
  // Mate In 2 plus one from each of the other main groups. The full grouped
  // list lives behind the "Browse all themes" button. Warm accent tones
  // differentiate the rows without icons; no descriptions, just the names.
  // Names resolve through AppLocalizations at build time (see
  // _buildThemeRows); only the accent colors are static.
  static const List<Color> _themeAccents = [
    Color(0xFFD97706),
    Color(0xFFC2410C),
    Color(0xFFEA580C),
    Color(0xFFA16207),
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context) {
    // The screen changes based on connectivity:
    //   online  → Mixed Puzzles / themes / Download Puzzles are interactive and
    //             the offline banner is hidden.
    //   offline → the banner appears, Mixed Puzzles + themes are disabled, and
    //             "Play Downloaded Puzzles" is offered when at least one
    //             downloaded puzzle still exists.
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnline,
      builder: (context, isOnline, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            // Tab screen: users switch via the bottom nav, so no back arrow.
            automaticallyImplyLeading: false,
            titleSpacing: 8,
            title: Text(
              AppLocalizations.of(context).puzzlesTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: -0.3,
              ),
            ),
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.backgroundOf(context),
            foregroundColor: AppColors.textPrimaryOf(context),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!isOnline) ...[
                      OfflineBanner(),
                      const SizedBox(height: 20),
                    ],
                    _buildIntro(context),
                    const SizedBox(height: 26),
                    _buildYourGamesCard(context),
                    const SizedBox(height: 20),
                    _buildMixedPuzzlesButton(context, isOnline),
                    if (isOnline) ...[
                      const SizedBox(height: 16),
                      _buildDownloadPuzzlesButton(context),
                    ] else if (_downloadedCount > 0) ...[
                      const SizedBox(height: 16),
                      _buildPlayDownloadedCard(context),
                    ],
                    const SizedBox(height: 34),
                    _buildSectionHeader(context, AppLocalizations.of(context).practiceThemesSection),
                    const SizedBox(height: 18),
                    ..._buildThemeRows(context, isOnline),
                    const SizedBox(height: 22),
                    _buildMoreThemes(context, isOnline),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(active: AppTab.puzzles),
        );
      },
    );
  }

  // =========================================================================
  // INTRO
  // =========================================================================

  Widget _buildIntro(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.puzzlesIntroTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.puzzlesIntroSubtitle,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // YOUR GAMES (vs Pippo) — kept equal in weight to the rest of the screen
  // so it reads as a plain entry point rather than a hero.
  // =========================================================================

  Widget _buildYourGamesCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            l10n.puzzlesFromYourGamesTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 28),
          // Pippo avatar
          PippoAvatar(
            size: 96,
            cornerRadius: 26,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: _buildGhostAction(context, l10n.solveNowButton, () {
              _onSolveNow(context);
            }),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.puzzlesRemainingCount(_puzzlesRemaining),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Muted secondary action — primary-colored label on a subtle surface, the
  /// same treatment used by the "Browse all themes" row.
  Widget _buildGhostAction(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceSubtleOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // THEME LIST — name-only rows differentiated by a thin accent bar. Tapping
  // a row opens the full grouped list behind "Browse all themes".
  // =========================================================================

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: -0.2,
        color: AppColors.textPrimaryOf(context),
      ),
    );
  }

  List<Widget> _buildThemeRows(BuildContext context, bool isOnline) {
    final l10n = AppLocalizations.of(context);
    final themes = [
      {'name': l10n.themeMateIn2, 'accent': _themeAccents[0]},
      {'name': l10n.themeFork, 'accent': _themeAccents[1]},
      {'name': l10n.themeKingsideAttack, 'accent': _themeAccents[2]},
      {'name': l10n.themeEndgame, 'accent': _themeAccents[3]},
      {'name': l10n.themePromotion, 'accent': _themeAccents[4]},
    ];
    return themes.map((theme) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildThemeRow(
          context,
          name: theme['name'] as String,
          accent: theme['accent'] as Color,
          isOnline: isOnline,
        ),
      );
    }).toList();
  }

  Widget _buildThemeRow(
    BuildContext context, {
    required String name,
    required Color accent,
    required bool isOnline,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // Offline, themes cannot be played (they need a fresh fetch), so the
        // row is inert.
        onTap: isOnline ? () => Navigator.pushNamed(context, '/themes') : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 42,
                decoration: BoxDecoration(
                  color: isOnline ? accent : AppColors.textTertiaryOf(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    color: isOnline
                        ? AppColors.textPrimaryOf(context)
                        : AppColors.textTertiaryOf(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isOnline
                    ? AppColors.textTertiaryOf(context)
                    : AppColors.textTertiaryOf(context).withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MIXED PUZZLES — sits between "Puzzles from your games" and themes.
  // =========================================================================

  Widget _buildMixedPuzzlesButton(BuildContext context, bool isOnline) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: isOnline
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surfaceSubtleOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // Offline, mixed puzzles cannot start (a fresh batch would need the
        // network), so the card is disabled.
        onTap: isOnline ? () => Navigator.pushNamed(context, '/mixed-puzzles') : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: isOnline ? AppColors.primary.withValues(alpha: 0.25) : theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceSubtleOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: isOnline ? AppColors.primary : AppColors.textTertiaryOf(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mixedPuzzlesTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: isOnline
                            ? AppColors.textPrimaryOf(context)
                            : AppColors.textTertiaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? l10n.mixedPuzzlesSubtitle
                          : l10n.mixedPuzzlesRequiresInternet,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: isOnline
                            ? AppColors.textSecondaryOf(context)
                            : AppColors.textTertiaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isOnline ? AppColors.primary : AppColors.textTertiaryOf(context).withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DOWNLOAD PUZZLES — only while online. Downloads a user-chosen amount
  // (10–100) into local storage for offline solving.
  // =========================================================================

  Widget _buildDownloadPuzzlesButton(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surfaceSubtleOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _isDownloading ? null : _onDownloadPuzzles,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDownloading
                          ? l10n.downloadingPuzzlesStatus
                          : l10n.downloadPuzzlesTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.downloadPuzzlesSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PLAY DOWNLOADED — offline only. Shown when the connection is down and at
  // least one downloaded puzzle is still unsolved. Every solved puzzle is
  // deleted from the set, so once the last one is done this card disappears.
  // =========================================================================

  Widget _buildPlayDownloadedCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onPlayDownloaded(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.offline_pin_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.playDownloadedPuzzlesTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.downloadedPuzzlesSavedOffline(_downloadedCount),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MORE THEMES — quiet secondary affordance leading to the full theme list.
  // =========================================================================

  Widget _buildMoreThemes(BuildContext context, bool isOnline) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surfaceSubtleOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // Offline, the full theme browser cannot be used, so disable it too.
        onTap: isOnline ? () => Navigator.pushNamed(context, '/themes') : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnline ? l10n.browseAllThemesButton : l10n.themesRequireInternet,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isOnline
                      ? AppColors.primary
                      : AppColors.textTertiaryOf(context),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '→',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isOnline
                      ? AppColors.primary
                      : AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
