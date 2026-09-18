import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// Every themes.txt slug the resolvers below know, in English.
///
/// The backend sometimes reports a puzzle's theme in its own casing, so
/// callers match against this list case-insensitively instead of assuming
/// the exact display spelling.
const List<String> knownThemeSlugs = [
  'Mate In 1',
  'Mate In 2',
  'Mate In 3',
  'Mate In 4',
  'Mate In 5',
  'Other Mates',
  'Fork',
  'Pin',
  'Skewer',
  'Discovered Attack',
  'Discovered Check',
  'Double Check',
  'Sacrifice',
  'Deflection',
  'Clearance',
  'Capturing Defender',
  'Advanced Tactics',
  'Kingside Attack',
  'Queenside Attack',
  'Exposed King',
  'Attacking F2 F7',
  'Endgame',
  'Rook Endgame',
  'Queen Endgame',
  'Queen Rook Endgame',
  'Bishop Endgame',
  'Knight Endgame',
  'Pawn Endgame',
  'Zugzwang',
  'Advanced Pawn',
  'Promotion',
  'Under Promotion',
  'En Passant',
  'Quiet Move',
  'Defensive Move',
  'Advantage',
  'Equality',
  'Crushing',
];

/// Localized display strings for puzzle themes.
///
/// Entries in themes.txt (and the backend that serves themed batches) use
/// fixed English slugs such as `'Fork'` or `'Mate In 2'`. Those slugs must
/// never be sent translated, but everything the user reads goes through
/// these resolvers so the whole app can run in another language.
String themeGroupDisplayName(AppLocalizations l10n, String slug) {
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
String themeDisplayName(AppLocalizations l10n, String slug) {
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
String themeDisplayDescription(AppLocalizations l10n, String slug) {
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
