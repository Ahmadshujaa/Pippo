import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasCard.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class Puzzles extends StatelessWidget {
  const Puzzles({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.puzzleDecksTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final decks = [
            [
              l10n.deckRecentMistakes,
              l10n.deckRecentMistakesSubtitle,
              Icons.auto_graph
            ],
            [
              l10n.deckMatingPatterns,
              l10n.deckMatingPatternsSubtitle,
              Icons.grid_view
            ],
            [
              l10n.deckOpeningTraps,
              l10n.deckOpeningTrapsSubtitle,
              Icons.door_front_door
            ],
            [
              l10n.deckDailyChallenges,
              l10n.deckDailyChallengesSubtitle,
              Icons.event_available
            ],
          ];
          final deck = decks[index];
          return AtlasCard(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(deck[2] as IconData, color: AppColors.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck[0] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(deck[1] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}



