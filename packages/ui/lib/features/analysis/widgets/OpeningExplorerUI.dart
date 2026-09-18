import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';


class OpeningExplorerView extends StatelessWidget {
  final OpeningExplorerResult? data;
  final ExplorerDatabase database;
  final Function(ExplorerDatabase) onDatabaseChanged;
  final Function(String san)? onMoveSelected;
  final void Function(TopGame game)? onGameSelected;
  final bool isLoading;
  final bool hasError;
  final bool isSignedIn;
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;

  // Filter state (lichess database only)
  final Set<String> selectedSpeeds;
  final Set<int> selectedRatings;
  final ValueChanged<Set<String>>? onSpeedsChanged;
  final ValueChanged<Set<int>>? onRatingsChanged;

  static const List<String> _speedOptions = [
    'bullet',
    'blitz',
    'rapid',
    'classical',
  ];

  /// Speed chip label in the on-screen language. The option keys themselves
  /// stay English for the Lichess API request.
  static String _speedLabel(AppLocalizations l10n, String speed) {
    switch (speed) {
      case 'bullet':
        return l10n.speedBullet;
      case 'blitz':
        return l10n.speedBlitz;
      case 'rapid':
        return l10n.speedRapid;
      case 'classical':
        return l10n.speedClassical;
      default:
        return speed;
    }
  }
  static const List<int> _ratingOptions = [
    1200,
    1400,
    1600,
    1800,
    2000,
    2200,
    2500,
  ];

  const OpeningExplorerView({
    super.key,
    required this.data,
    required this.database,
    required this.onDatabaseChanged,
    this.onMoveSelected,
    this.onGameSelected,
    this.isLoading = false,
    this.hasError = false,
    this.isSignedIn = true,
    this.onRetry,
    this.onSignIn,
    this.selectedSpeeds = const {'blitz', 'rapid', 'classical'},
    this.selectedRatings = const {1600, 1800, 2000, 2200, 2500},
    this.onSpeedsChanged,
    this.onRatingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isSignedIn) {
      return _buildSignInState(context, theme);
    }

    if (hasError) {
      return _buildErrorState(context, theme);
    }

    if (data == null || (data!.moves.isEmpty && data!.topGames.isEmpty)) {
      return _buildEmptyState(context, theme);
    }

    final result = data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, theme),
        if (database == ExplorerDatabase.lichess) ...[
          const SizedBox(height: 16),
          _buildFilters(context, theme),
        ],
        const SizedBox(height: 20),
        if (result.moves.isNotEmpty) ...[
          _buildSectionTitle(theme, AppLocalizations.of(context).theoreticalMoves),
          const SizedBox(height: 12),
          ...result.moves.map(
            (move) => MovePerformanceTile(
              move: move,
              onTap: onMoveSelected == null ? null : () => onMoveSelected!(move.san),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (result.topGames.isNotEmpty) ...[
          _buildSectionTitle(theme, AppLocalizations.of(context).topMasterGames),
          const SizedBox(height: 12),
          TopGamesList(
            games: result.topGames,
            onGameSelected: onGameSelected,
          ),
          const SizedBox(height: 24),
        ],
        if (result.recentGames.isNotEmpty) ...[
          _buildSectionTitle(theme, AppLocalizations.of(context).recentGames),
          const SizedBox(height: 12),
          TopGamesList(
            games: result.recentGames,
            onGameSelected: onGameSelected,
          ),
        ],
        const SizedBox(height: 20),
        _buildDatabaseToggle(context, theme, isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final eco = data?.eco;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.explore_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data?.openingName ?? l10n.openingExplorerTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (eco != null)
                Text(
                  l10n.ecoCodeLabel(eco),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseToggle(BuildContext context, ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            l10n.dbMasters,
            ExplorerDatabase.masters,
            theme,
            isDark,
          ),
          _buildToggleItem(
            'Lichess',
            ExplorerDatabase.lichess,
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  /// Speed + rating filter chips (lichess database only).
  Widget _buildFilters(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.filtersHeader,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final speed in _speedOptions)
              _buildFilterChip(
                _speedLabel(l10n, speed),
                selectedSpeeds.contains(speed),
                () {
                  final next = Set<String>.from(selectedSpeeds);
                  if (!next.add(speed)) next.remove(speed);
                  onSpeedsChanged?.call(next);
                },
                theme,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final rating in _ratingOptions)
              _buildFilterChip(
                '$rating+',
                selectedRatings.contains(rating),
                () {
                  final next = Set<int>.from(selectedRatings);
                  if (!next.add(rating)) next.remove(rating);
                  onRatingsChanged?.call(next);
                },
                theme,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.6)
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String label,
    ExplorerDatabase value,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = database == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onDatabaseChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  /// Prompts the user to authenticate with Lichess (OAuth) before the
  /// opening explorer can load data.
  Widget _buildSignInState(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 260,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.openingExplorerTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.explorerSignInDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              if (onSignIn != null)
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A7A7A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      l10n.signInWithLichess,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noOpeningData,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load opening data',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.retry),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MovePerformanceTile extends StatelessWidget {
  final OpeningMove move;
  final VoidCallback? onTap;

  const MovePerformanceTile({super.key, required this.move, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = move.totalGames;

    // Percentage calculation
    final whitePct = total == 0 ? 0.0 : move.white / total;
    final drawPct = total == 0 ? 0.0 : move.draws / total;
    final blackPct = total == 0 ? 0.0 : move.black / total;

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  move.san,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatGames(context, total),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              if (move.averageRating > 0)
                Text(
                  AppLocalizations.of(context).averageRatingLabel(move.averageRating),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          WdlBar(
            white: whitePct,
            draws: drawPct,
            black: blackPct,
            showLabels: true,
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );
  }

  String _formatGames(BuildContext context, int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return AppLocalizations.of(context).gamesCountLabel(value);
  }
}

class WdlBar extends StatelessWidget {
  final double white;
  final double draws;
  final double black;
  final bool showLabels;

  const WdlBar({
    super.key,
    required this.white,
    required this.draws,
    required this.black,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: showLabels ? 14 : 8,
        child: Row(
          children: [
            if (white > 0)
              Expanded(
                flex: (white * 100).round().clamp(1, 100),
                child: Container(
                  color: Colors.white,
                  child: showLabels && white > 0.12
                      ? Center(
                          child: Text(
                            '${(white * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            if (draws > 0)
              Expanded(
                flex: (draws * 100).round().clamp(1, 100),
                child: Container(
                  color: const Color(0xFF94A3B8),
                  child: showLabels && draws > 0.12
                      ? Center(
                          child: Text(
                            '${(draws * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            if (black > 0)
              Expanded(
                flex: (black * 100).round().clamp(1, 100),
                child: Container(
                  color: Colors.black,
                  child: showLabels && black > 0.12
                      ? Center(
                          child: Text(
                            '${(black * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TopGamesList extends StatelessWidget {
  final List<TopGame> games;
  final void Function(TopGame game)? onGameSelected;

  const TopGamesList({super.key, required this.games, this.onGameSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: games.map((game) {
        final tile = Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlayerRow(
                          context,
                          game.white,
                          true,
                          game.winner == 'white',
                          theme,
                        ),
                        const SizedBox(height: 4),
                        _buildPlayerRow(
                          context,
                          game.black,
                          false,
                          game.winner == 'black',
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        game.resultString,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatGameDate(context, game),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        if (onGameSelected == null) return tile;
        return InkWell(
          onTap: () => onGameSelected!(game),
          borderRadius: BorderRadius.circular(12),
          child: tile,
        );
      }).toList(),
    );
  }

  static List<String> _monthNames(AppLocalizations l10n) => [
        l10n.monthJanuary,
        l10n.monthFebruary,
        l10n.monthMarch,
        l10n.monthApril,
        l10n.monthMay,
        l10n.monthJune,
        l10n.monthJuly,
        l10n.monthAugust,
        l10n.monthSeptember,
        l10n.monthOctober,
        l10n.monthNovember,
        l10n.monthDecember,
      ];

  /// API returns month either as "2026-05" or a name like "March".
  String _formatGameDate(BuildContext context, TopGame game) {
    final month = game.month;
    if (month == null) return game.year.toString();
    final parts = month.split('-');
    if (parts.length == 2) {
      final year = int.tryParse(parts[0]);
      final monthNum = int.tryParse(parts[1]);
      if (year != null && monthNum != null && monthNum >= 1 && monthNum <= 12) {
        return '${_monthNames(AppLocalizations.of(context))[monthNum - 1]} $year';
      }
    }
    return '$month ${game.year}';
  }

  Widget _buildPlayerRow(
    BuildContext context,
    Map<String, dynamic> player,
    bool isWhite,
    bool isWinner,
    ThemeData theme,
  ) {
    final name = player['name'] ?? AppLocalizations.of(context).unknownPlayer;
    final rating = player['rating'];

    return Row(
      children: [
        Icon(
          Icons.person,
          size: 14,
          color: isWhite ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              color: isWinner
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        if (rating != null)
          Text(
            rating.toString(),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}
