import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class GameListDialog extends StatelessWidget {
  final List<GameSummary> games;
  final Function(GameSummary) onGameSelected;

  const GameListDialog({
    super.key,
    required this.games,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  AppLocalizations.of(context).selectGameTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: games.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final game = games[index];
                return _GameItem(
                  game: game,
                  onTap: () {
                    Navigator.pop(context);
                    onGameSelected(game);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameItem extends StatelessWidget {
  final GameSummary game;
  final VoidCallback onTap;

  const _GameItem({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildPlayer(game.white, game.whiteRating, true, theme),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(AppLocalizations.of(context).versusShort, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                ),
                _buildPlayer(game.black, game.blackRating, false, theme),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.result,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy', Localizations.localeOf(context).languageCode).format(game.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                    game.source == 'Lichess' ? Icons.public_rounded : Icons.grid_view_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(String name, int? rating, bool isWhite, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isWhite ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          if (rating != null)
            Text(
              '($rating)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
