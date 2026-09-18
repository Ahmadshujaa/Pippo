import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

/// One main group from themes.txt (kept at the repository root).
class _ThemeGroup {
  const _ThemeGroup(this.name, this.themes);

  /// English group name, matching themes.txt. Used only as a stable key —
  /// the header shown on screen resolves through [_groupName].
  final String name;
  final List<({String name, String description})> themes;
}

/// Every theme group, name and description exactly as written in themes.txt —
/// group name as the header, its themes listed verbatim beneath it with their
/// descriptions. Keep this list in sync with themes.txt.
const List<_ThemeGroup> _themeGroups = [
  _ThemeGroup('Mates', [
    (name: 'Mate In 1', description: 'Find the checkmate in a single move.'),
    (
      name: 'Mate In 2',
      description:
          'Set up the position and finish with checkmate on your next move.',
    ),
    (
      name: 'Mate In 3',
      description:
          'Find the winning sequence that leads to checkmate in three moves.',
    ),
    (
      name: 'Mate In 4',
      description: 'Plan a few moves ahead to force checkmate.',
    ),
    (
      name: 'Mate In 5',
      description: 'A longer mating sequence where every move matters.',
    ),
    (
      name: 'Other Mates',
      description:
          'Special mating patterns like Back Rank, Smothered, Anastasia, Arabian, Boden, Opera, and more.',
    ),
  ]),
  _ThemeGroup('Tactics', [
    (name: 'Fork', description: 'One piece attacks two or more targets at once.'),
    (
      name: 'Pin',
      description:
          'A piece is stuck because moving it would expose something more valuable.',
    ),
    (
      name: 'Skewer',
      description: 'Attack a valuable piece and win what is hiding behind it.',
    ),
    (
      name: 'Discovered Attack',
      description: 'Move one piece to uncover an attack from another.',
    ),
    (
      name: 'Discovered Check',
      description: 'Uncover a check by moving another piece out of the way.',
    ),
    (
      name: 'Double Check',
      description: 'Give check from two pieces at the same time.',
    ),
    (
      name: 'Sacrifice',
      description: 'Give up material to gain something stronger in return.',
    ),
    (
      name: 'Deflection',
      description: 'Force a piece away from where it needs to be.',
    ),
    (
      name: 'Clearance',
      description: 'Move a piece away to open the way for another piece.',
    ),
    (
      name: 'Capturing Defender',
      description: 'Remove the piece protecting an important target.',
    ),
    (
      name: 'Advanced Tactics',
      description:
          'More difficult combinations involving several tactical ideas.',
    ),
  ]),
  _ThemeGroup('King Attack', [
    (
      name: 'Kingside Attack',
      description: 'Build an attack against the king on the kingside.',
    ),
    (
      name: 'Queenside Attack',
      description:
          'Look for ways to break through around the enemy king on the queenside.',
    ),
    (
      name: 'Exposed King',
      description: 'Take advantage of a king that has lost its protection.',
    ),
    (
      name: 'Attacking F2 F7',
      description: 'Target the weak f2 or f7 square near the king.',
    ),
  ]),
  _ThemeGroup('Endgames', [
    (
      name: 'Endgame',
      description: 'Find the best way to play when only a few pieces remain.',
    ),
    (
      name: 'Rook Endgame',
      description: 'Learn to make the most of your rooks in the endgame.',
    ),
    (
      name: 'Queen Endgame',
      description:
          'Find the right moves in positions where queens remain on the board.',
    ),
    (
      name: 'Queen Rook Endgame',
      description:
          'Handle endgames where queens and rooks are still in play.',
    ),
    (
      name: 'Bishop Endgame',
      description: 'Use your bishop and king to find the winning plan.',
    ),
    (
      name: 'Knight Endgame',
      description:
          'Find the right moves in endgames where knights matter most.',
    ),
    (
      name: 'Pawn Endgame',
      description: 'Calculate pawn races and find the path to victory.',
    ),
    (
      name: 'Zugzwang',
      description:
          'Put your opponent in a position where any move makes things worse.',
    ),
  ]),
  _ThemeGroup('Pawns & Promotion', [
    (
      name: 'Advanced Pawn',
      description:
          'Use a dangerous pawn that has pushed deep into enemy territory.',
    ),
    (
      name: 'Promotion',
      description: 'Push a pawn through to become a stronger piece.',
    ),
    (
      name: 'Under Promotion',
      description:
          "Promote to something other than a queen when that's the winning move.",
    ),
    (
      name: 'En Passant',
      description: 'Spot the rare chance to capture a pawn using en passant.',
    ),
  ]),
  _ThemeGroup('Strategy', [
    (
      name: 'Quiet Move',
      description:
          'Find a calm move that creates a strong advantage without forcing tactics.',
    ),
    (
      name: 'Defensive Move',
      description: "Find the move that stops your opponent's threat.",
    ),
    (
      name: 'Advantage',
      description: 'Find the move that keeps or increases your advantage.',
    ),
    (
      name: 'Equality',
      description: 'Find the move that keeps the position balanced.',
    ),
    (
      name: 'Crushing',
      description:
          'Find the powerful move that turns a strong position into a winning one.',
    ),
  ]),
];

/// Display name of a theme group in the on-screen language.
///
/// The entries of [_themeGroups] stay in English on purpose: they mirror
/// themes.txt and the backend expects those exact slugs when a themed batch
/// is fetched. Only what the user reads is translated.
String _groupName(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'Mates':
      return l10n.themeGroupMates;
    case 'Tactics':
      return l10n.themeGroupTactics;
    case 'King Attack':
      return l10n.themeGroupKingAttack;
    case 'Endgames':
      return l10n.themeGroupEndgames;
    case 'Pawns & Promotion':
      return l10n.themeGroupPawnsPromotion;
    case 'Strategy':
      return l10n.themeGroupStrategy;
    default:
      return slug;
  }
}

/// Display name of one theme in the on-screen language. [slug] is the
/// English themes.txt name, which is also what the backend fetch needs.
String _themeDisplayName(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'Mate In 1':
      return l10n.themeMateIn1;
    case 'Mate In 2':
      return l10n.themeMateIn2;
    case 'Mate In 3':
      return l10n.themeMateIn3;
    case 'Mate In 4':
      return l10n.themeMateIn4;
    case 'Mate In 5':
      return l10n.themeMateIn5;
    case 'Other Mates':
      return l10n.themeOtherMates;
    case 'Fork':
      return l10n.themeFork;
    case 'Pin':
      return l10n.themePin;
    case 'Skewer':
      return l10n.themeSkewer;
    case 'Discovered Attack':
      return l10n.themeDiscoveredAttack;
    case 'Discovered Check':
      return l10n.themeDiscoveredCheck;
    case 'Double Check':
      return l10n.themeDoubleCheck;
    case 'Sacrifice':
      return l10n.themeSacrifice;
    case 'Deflection':
      return l10n.themeDeflection;
    case 'Clearance':
      return l10n.themeClearance;
    case 'Capturing Defender':
      return l10n.themeCapturingDefender;
    case 'Advanced Tactics':
      return l10n.themeAdvancedTactics;
    case 'Kingside Attack':
      return l10n.themeKingsideAttack;
    case 'Queenside Attack':
      return l10n.themeQueensideAttack;
    case 'Exposed King':
      return l10n.themeExposedKing;
    case 'Attacking F2 F7':
      return l10n.themeAttackingF2F7;
    case 'Endgame':
      return l10n.themeEndgame;
    case 'Rook Endgame':
      return l10n.themeRookEndgame;
    case 'Queen Endgame':
      return l10n.themeQueenEndgame;
    case 'Queen Rook Endgame':
      return l10n.themeQueenRookEndgame;
    case 'Bishop Endgame':
      return l10n.themeBishopEndgame;
    case 'Knight Endgame':
      return l10n.themeKnightEndgame;
    case 'Pawn Endgame':
      return l10n.themePawnEndgame;
    case 'Zugzwang':
      return l10n.themeZugzwang;
    case 'Advanced Pawn':
      return l10n.themeAdvancedPawn;
    case 'Promotion':
      return l10n.themePromotion;
    case 'Under Promotion':
      return l10n.themeUnderPromotion;
    case 'En Passant':
      return l10n.themeEnPassant;
    case 'Quiet Move':
      return l10n.themeQuietMove;
    case 'Defensive Move':
      return l10n.themeDefensiveMove;
    case 'Advantage':
      return l10n.themeAdvantage;
    case 'Equality':
      return l10n.themeEquality;
    case 'Crushing':
      return l10n.themeCrushing;
    default:
      return slug;
  }
}

/// One-line help of a theme in the on-screen language.
String _themeDisplayDescription(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'Mate In 1':
      return l10n.themeMateIn1Desc;
    case 'Mate In 2':
      return l10n.themeMateIn2Desc;
    case 'Mate In 3':
      return l10n.themeMateIn3Desc;
    case 'Mate In 4':
      return l10n.themeMateIn4Desc;
    case 'Mate In 5':
      return l10n.themeMateIn5Desc;
    case 'Other Mates':
      return l10n.themeOtherMatesDesc;
    case 'Fork':
      return l10n.themeForkDesc;
    case 'Pin':
      return l10n.themePinDesc;
    case 'Skewer':
      return l10n.themeSkewerDesc;
    case 'Discovered Attack':
      return l10n.themeDiscoveredAttackDesc;
    case 'Discovered Check':
      return l10n.themeDiscoveredCheckDesc;
    case 'Double Check':
      return l10n.themeDoubleCheckDesc;
    case 'Sacrifice':
      return l10n.themeSacrificeDesc;
    case 'Deflection':
      return l10n.themeDeflectionDesc;
    case 'Clearance':
      return l10n.themeClearanceDesc;
    case 'Capturing Defender':
      return l10n.themeCapturingDefenderDesc;
    case 'Advanced Tactics':
      return l10n.themeAdvancedTacticsDesc;
    case 'Kingside Attack':
      return l10n.themeKingsideAttackDesc;
    case 'Queenside Attack':
      return l10n.themeQueensideAttackDesc;
    case 'Exposed King':
      return l10n.themeExposedKingDesc;
    case 'Attacking F2 F7':
      return l10n.themeAttackingF2F7Desc;
    case 'Endgame':
      return l10n.themeEndgameDesc;
    case 'Rook Endgame':
      return l10n.themeRookEndgameDesc;
    case 'Queen Endgame':
      return l10n.themeQueenEndgameDesc;
    case 'Queen Rook Endgame':
      return l10n.themeQueenRookEndgameDesc;
    case 'Bishop Endgame':
      return l10n.themeBishopEndgameDesc;
    case 'Knight Endgame':
      return l10n.themeKnightEndgameDesc;
    case 'Pawn Endgame':
      return l10n.themePawnEndgameDesc;
    case 'Zugzwang':
      return l10n.themeZugzwangDesc;
    case 'Advanced Pawn':
      return l10n.themeAdvancedPawnDesc;
    case 'Promotion':
      return l10n.themePromotionDesc;
    case 'Under Promotion':
      return l10n.themeUnderPromotionDesc;
    case 'En Passant':
      return l10n.themeEnPassantDesc;
    case 'Quiet Move':
      return l10n.themeQuietMoveDesc;
    case 'Defensive Move':
      return l10n.themeDefensiveMoveDesc;
    case 'Advantage':
      return l10n.themeAdvantageDesc;
    case 'Equality':
      return l10n.themeEqualityDesc;
    case 'Crushing':
      return l10n.themeCrushingDesc;
    default:
      return '';
  }
}

/// Full puzzle-theme library: each main group is a card whose header expands
/// (chevron flips) to reveal that group's themes.
class AllThemesScreen extends StatefulWidget {
  const AllThemesScreen({super.key});

  @override
  State<AllThemesScreen> createState() => _AllThemesScreenState();
}

class _AllThemesScreenState extends State<AllThemesScreen> {
  final Set<int> _expandedGroups = {};

  void _toggleGroup(int index) {
    setState(() {
      if (!_expandedGroups.remove(index)) {
        _expandedGroups.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reacts to the global connectivity monitor: offline, the offline banner
    // appears and every theme button is disabled because themed batches need
    // a fresh fetch from the network.
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnline,
      builder: (context, isOnline, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).allThemesTitle,
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
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (!isOnline) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OfflineBanner(),
                ),
              ],
              // Intro sentence above all the themes.
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 16),
                child: Text(
                  isOnline
                      ? AppLocalizations.of(context).allThemesIntro
                      : AppLocalizations.of(context).themesNeedInternetOffline,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
              for (int i = 0; i < _themeGroups.length; i++) ...[
                _buildGroupCard(
                  context,
                  index: i,
                  group: _themeGroups[i],
                  isExpanded: _expandedGroups.contains(i),
                  isOnline: isOnline,
                ),
                if (i < _themeGroups.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(
    BuildContext context, {
    required int index,
    required _ThemeGroup group,
    required bool isExpanded,
    required bool isOnline,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Group header — tap to expand / collapse.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleGroup(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _groupName(AppLocalizations.of(context), group.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 24,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Theme list — revealed under the header when expanded.
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded ? _buildThemeList(context, group.themes, isOnline) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList(
    BuildContext context,
    List<({String name, String description})> themes,
    bool isOnline,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < themes.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor,
            ),
          InkWell(
            // Tap a theme -> themed puzzle batch. Reuses the mixed-puzzles
            // play screen; the theme name is passed as a route argument.
            // Offline the button is inert — themed batches need a fetch.
            onTap: isOnline
                ? () => Navigator.pushNamed(
                    context,
                    '/mixed-puzzles',
                    arguments: themes[i].name,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _themeDisplayName(l10n, themes[i].name),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.1,
                            color: isOnline
                                ? AppColors.textPrimaryOf(context)
                                : AppColors.textTertiaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOnline
                              ? _themeDisplayDescription(l10n, themes[i].name)
                              : l10n.needsInternetForBatch,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: isOnline
                                ? AppColors.textSecondaryOf(context)
                                : AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}
