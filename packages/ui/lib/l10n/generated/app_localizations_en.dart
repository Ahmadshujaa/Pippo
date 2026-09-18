// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get planAdmin => 'ADMIN';

  @override
  String get planPro => 'PRO MEMBER';

  @override
  String get planFree => 'FREE MEMBER';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appSettingsSection => 'App Settings';

  @override
  String get supportSection => 'Support';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Light, dark, or system theme';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionSubtitle => 'Manage your Atlas Pro plan';

  @override
  String get languageTitle => 'Language';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpSubtitle => 'FAQs and customer service';

  @override
  String get contactSupportTitle => 'Contact Support';

  @override
  String get contactSupportSubtitle => 'Contact support team';

  @override
  String get logout => 'Log Out';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get editDisplayName => 'Edit Display Name';

  @override
  String displayNameRule(int maxLength) {
    return 'Choose a name up to $maxLength characters long.';
  }

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get save => 'Save';

  @override
  String get languageSheetTitle => 'Choose Language';

  @override
  String get systemLanguage => 'System Default';

  @override
  String get supportTypeLabel => 'Type of problem';

  @override
  String get supportTypeHint =>
      'Pick the option that best describes your issue.';

  @override
  String get supportTypeUi => 'UI';

  @override
  String get supportTypeError => 'Error';

  @override
  String get supportTypeOther => 'Other';

  @override
  String get supportSubjectLabel => 'Subject';

  @override
  String get supportSubjectHint => 'Brief description of your issue';

  @override
  String get supportMessageLabel => 'Message';

  @override
  String get supportMessageHint => 'Please describe your issue in detail...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max characters';
  }

  @override
  String get supportSubmitButton => 'Submit Ticket';

  @override
  String get supportSuccessTitle => 'Ticket Submitted!';

  @override
  String get supportSuccessBody =>
      'We will respond to your email within 24-48 hours.';

  @override
  String get supportSuccessDone => 'Done';

  @override
  String get supportSignInTitle => 'Sign in to contact support';

  @override
  String get supportSignInBody =>
      'Tickets are linked to your account so we can reply to you. Sign in and try again.';

  @override
  String get supportOfflineNotice =>
      'You are offline. Reconnect to submit your ticket.';

  @override
  String get supportErrTypeRequired => 'Choose the type of problem.';

  @override
  String get supportErrSubjectRequired => 'Enter a subject.';

  @override
  String get supportErrMessageRequired => 'Enter a message.';

  @override
  String get supportErrSubjectTooLong => 'Your subject is too long.';

  @override
  String get supportErrMessageTooLong => 'Your message is too long.';

  @override
  String get supportErrGeneric =>
      'Could not submit your ticket. Please try again.';

  @override
  String get offlineBannerTitle => 'No Internet Connection';

  @override
  String get retry => 'Retry';

  @override
  String get boardSettingsTitle => 'Board Settings';

  @override
  String get pieceSetLabel => 'Piece Set';

  @override
  String get boardThemeLabel => 'Board Theme';

  @override
  String get moveIndicatorLabel => 'Move Indicator';

  @override
  String get showCoordinatesLabel => 'Show Coordinates';

  @override
  String get dragAndDropLabel => 'Drag & Drop';

  @override
  String get soundLabel => 'Sound';

  @override
  String get closeButton => 'Close';

  @override
  String get editExplanationTitle => 'Edit Explanation';

  @override
  String get writeExplanationHint => 'Write the explanation...';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get boardThemeEmerald => 'Emerald';

  @override
  String get boardThemeMidnight => 'Midnight';

  @override
  String get boardThemePurple => 'Purple';

  @override
  String get boardThemeSand => 'Sand';

  @override
  String get boardThemeBlue => 'Blue';

  @override
  String get boardThemeBrown => 'Brown';

  @override
  String get quotaUpgradeCta => 'Upgrade to pro to solve unlimited puzzles';

  @override
  String get downloadButton => 'Download';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get offlineDownloadsProNotice =>
      'Offline puzzle downloads are available with Pro. Upgrade to save puzzles on this device.';

  @override
  String get savedForOffline => 'Saved on this device for offline solving';

  @override
  String get downloadPuzzlesTitle => 'Download Puzzles';

  @override
  String get puzzleDecksTitle => 'Puzzle Decks';

  @override
  String get deckRecentMistakes => 'Recent Mistakes';

  @override
  String get deckRecentMistakesSubtitle => 'Tactics from your lost games';

  @override
  String get deckMatingPatterns => 'Mating Patterns';

  @override
  String get deckMatingPatternsSubtitle => 'Master the endgame kills';

  @override
  String get deckOpeningTraps => 'Opening Traps';

  @override
  String get deckOpeningTrapsSubtitle => 'Common tricks in your repertoire';

  @override
  String get deckDailyChallenges => 'Daily Challenges';

  @override
  String get deckDailyChallengesSubtitle => 'Fresh puzzles every day';

  @override
  String selectedPuzzleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzzles',
      one: '1 puzzle',
    );
    return '$_temp0';
  }

  @override
  String get getStartedTitle => 'Get Started';

  @override
  String get welcomeTagline =>
      'Get better at chess fast with Pippo, your personal coach to help you learn, improve, and win more games.';

  @override
  String get signInOrSignUpSubtitle =>
      'Sign in or sign up to save your progress.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get errGoogleSignIn => 'Could not complete Google sign-in.';

  @override
  String get signInTab => 'Sign In';

  @override
  String get signUpTab => 'Sign Up';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get orLabel => 'OR';

  @override
  String get registerButton => 'Register';

  @override
  String get welcomeBackTitle => 'Welcome Back';

  @override
  String get signInSubtitle =>
      'Sign in to your account and keep climbing the ranks.';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signUpSubtitle =>
      'Join thousands of players and improve your game.';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get firstNameHint => 'John';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get lastNameHint => 'Doe';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get enterResetCodeTitle => 'Enter Reset Code';

  @override
  String get resetIntro =>
      'Enter your account email and we will send you a recovery code.';

  @override
  String resetCodeSentIntro(String email) {
    return 'We sent a recovery code to $email. Enter it below with your new password.';
  }

  @override
  String get recoveryCodeLabel => 'Recovery Code';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get sendRecoveryCode => 'Send Recovery Code';

  @override
  String get errEnterValidEmail => 'Enter a valid email address.';

  @override
  String get errEnterCodeFromEmail => 'Enter the code from your email.';

  @override
  String get errPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get namePromptTitle => 'What should we call you?';

  @override
  String get namePromptSubtitle =>
      'Choose a name for your profile so we can personalize your experience.';

  @override
  String get yourNameHint => 'Your name';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String get enterVerificationCodeTitle => 'Enter Verification Code';

  @override
  String get otpSentPrefix => 'We\'ve sent an 8-digit code to\n';

  @override
  String get otpSentSuffix => '. Please check your inbox or spam folder.';

  @override
  String get verifyCodeButton => 'Verify Code';

  @override
  String get didntReceiveCode => 'Didn\'t receive code?';

  @override
  String get resend => 'Resend';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verificationCodeResent => 'Verification code resent successfully';

  @override
  String helloGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeSubtitle => 'Ready to learn something new today?';

  @override
  String get coursesSection => 'Courses';

  @override
  String get dailyPracticeSection => 'Daily Practice';

  @override
  String get seeAll => 'See all';

  @override
  String get todayLabel => 'TODAY';

  @override
  String get gamesVsPippo => 'games vs Pippo';

  @override
  String get puzzleRatingLabel => 'Puzzle Rating';

  @override
  String get dailyStreakLabel => 'Daily Streak';

  @override
  String get chaptersDoneLabel => 'Chapters done';

  @override
  String get tacticsTrainingTitle => 'Tactics Training';

  @override
  String get tacticsTrainingSubtitle => 'Solve puzzles and sharpen your play';

  @override
  String get dailyPuzzleLabel => 'Daily Puzzle';

  @override
  String get playNow => 'Play Now';

  @override
  String get navHome => 'Home';

  @override
  String get navCourses => 'Courses';

  @override
  String get navPuzzles => 'Puzzles';

  @override
  String get navAnalysis => 'Analysis';

  @override
  String get navMenu => 'Menu';

  @override
  String get planBadgeAdmin => 'ADMIN';

  @override
  String get planBadgeFree => 'FREE';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return '$tier PLAN';
  }

  @override
  String get coursesComingSoon => 'Courses coming soon';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get continueLearningButton => 'Continue Learning';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total variations done',
      one: '$completed/$total variation done',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'White';

  @override
  String get sideBlack => 'Black';

  @override
  String get sideWhiteInitial => 'W';

  @override
  String get sideBlackInitial => 'B';

  @override
  String courseMetaChip(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $count Chapters',
      one: '$side · 1 Chapter',
    );
    return '$_temp0';
  }

  @override
  String get puzzlesTitle => 'Puzzles';

  @override
  String get puzzlesIntroTitle => 'Sharpen your tactics';

  @override
  String get puzzlesIntroSubtitle =>
      'Train on the themes that matter most and fix the mistakes you made in your games.';

  @override
  String get puzzlesFromYourGamesTitle => 'Puzzles from your games';

  @override
  String get solveNowButton => 'Solve Now';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count Puzzles Remaining';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'No puzzles yet — finish a game against Pippo and your mistakes will become puzzles.';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return '$count puzzles downloaded — available even when you are offline.';
  }

  @override
  String get mixedPuzzlesTitle => 'Mixed Puzzles';

  @override
  String get mixedPuzzlesSubtitle => 'Play puzzles of random themes';

  @override
  String get mixedPuzzlesRequiresInternet => 'Requires an internet connection';

  @override
  String get downloadingPuzzlesStatus => 'Downloading puzzles...';

  @override
  String get downloadPuzzlesSubtitle =>
      'Save 10–100 puzzles to solve without internet';

  @override
  String get playDownloadedPuzzlesTitle => 'Play Downloaded Puzzles';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count puzzles saved — available offline';
  }

  @override
  String get practiceThemesSection => 'Practice themes';

  @override
  String get browseAllThemesButton => 'Browse all themes';

  @override
  String get themesRequireInternet => 'Themes require internet';

  @override
  String get coursesTitle => 'Courses';

  @override
  String get coursesTabOpenings => 'Openings';

  @override
  String get coursesTabMiddlegames => 'Middlegames';

  @override
  String get coursesTabEndgames => 'Endgames';

  @override
  String get noCoursesHereYet => 'No courses here yet.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String playAsSide(String side) {
    return 'Play as $side';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count chapters';
  }

  @override
  String variationCountLabel(int count) {
    return '$count variations';
  }

  @override
  String get courseDetailsTitle => 'Course Details';

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO: $code';
  }

  @override
  String get noChaptersAvailable => 'No chapters available.';

  @override
  String get chapterCompletedBadge => 'Completed';

  @override
  String get noVariationsAvailable => 'No variations available';

  @override
  String get noVariationsForChapterYet =>
      'No variations available for this chapter yet.';

  @override
  String get learnButton => 'Learn';

  @override
  String get testButton => 'Test';

  @override
  String get pricingTitle => 'Go Pro';

  @override
  String get pricingHeroTitle => 'Unlock your full\nchess potential.';

  @override
  String get pricingHeroSubtitle =>
      'Get advanced analysis, unlimited puzzles, and AI-powered coaching.';

  @override
  String get pricingFaqHeader => 'FREQUENTLY ASKED';

  @override
  String get pricingFaqCancelQuestion => 'Can I cancel anytime?';

  @override
  String get pricingFaqCancelAnswer =>
      'Yes, you can cancel your Pro subscription at any time. You\'ll keep access until the end of your billing period.';

  @override
  String get pricingFaqTrialQuestion => 'Is there a free trial?';

  @override
  String get pricingFaqTrialAnswer =>
      'Pro comes with a 7-day free trial. No credit card required to start.';

  @override
  String get pricingFaqPaymentQuestion => 'What payment methods do you accept?';

  @override
  String get pricingFaqPaymentAnswer =>
      'We accept all major credit cards, Apple Pay, and Google Pay.';

  @override
  String get pricingMostPopularBadge => 'MOST POPULAR';

  @override
  String get pricingFreeBadge => 'FREE';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'Free';

  @override
  String get pricingProPrice => '\$9.99/mo';

  @override
  String get pricingFreePrice => '\$0';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'Unlimited engine analysis';

  @override
  String get pricingFeatureDeepClassification => 'Deep move classification';

  @override
  String get pricingFeatureAiReview => 'AI-powered game review';

  @override
  String get pricingFeatureOpeningExplorer => 'Advanced opening explorer';

  @override
  String get pricingFeatureUnlimitedPuzzles => 'Unlimited puzzle sets';

  @override
  String get pricingFeatureTrainingPlans => 'Personalized training plans';

  @override
  String get pricingFeaturePrioritySupport => 'Priority support';

  @override
  String get pricingFeatureEarlyAccess => 'Early access to new features';

  @override
  String get pricingFeatureBasicAnalysis => 'Basic engine analysis';

  @override
  String get pricingFeatureStandardClassification =>
      'Standard move classification';

  @override
  String get pricingFeatureGameImport => 'Game import from Lichess & Chess.com';

  @override
  String get pricingFeatureLimitedPuzzles => 'Limited puzzle sets';

  @override
  String get pricingFeatureCommunityAccess => 'Community access';

  @override
  String get pricingStartTrialButton => 'Start Free Trial';

  @override
  String get pricingCurrentPlanButton => 'Current Plan';

  @override
  String get startingEngineStatus => 'Starting engine...';

  @override
  String get downloadPippoPrompt =>
      'Download Pippo (BaseModel.onnx) to play offline.';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received MB / $total MB';
  }

  @override
  String get downloadingStatus => 'Downloading...';

  @override
  String get downloadEngineButton => 'Download Engine';

  @override
  String get startChapterButton => 'Start Chapter';

  @override
  String get finishChapterButton => 'Finish Chapter';

  @override
  String get takeTestButton => 'Take Test';

  @override
  String get exploreBranchesButton => 'Explore Branches';

  @override
  String get moveToNextVariationButton => 'Move to Next Variation';

  @override
  String get variationsTitle => 'Variations';

  @override
  String get alternativeBranchesTitle => 'Alternative Branches';

  @override
  String get noTheoryAvailable => 'No theory available for this variation.';

  @override
  String get editBranchExplanationTooltip => 'Edit branch explanation';

  @override
  String get editExplanationTooltip => 'Edit explanation';

  @override
  String get editTheoryTooltip => 'Edit theory';

  @override
  String branchEditTitle(String name) {
    return 'Branch: $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'Move: $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'Chapter: $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'Theory: $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'Free users can unlock one new chapter per day.';

  @override
  String playMovePrompt(String move) {
    return 'Play $move';
  }

  @override
  String get opponentThinking => 'I\'m thinking';

  @override
  String opponentPlayedMove(String move) {
    return 'Opponent played $move';
  }

  @override
  String correctMoveWithName(String move) {
    return 'Correct! $move';
  }

  @override
  String get notRightMove => 'That\'s not the right move';

  @override
  String get variationCompletedMessage => 'Variation Completed!';

  @override
  String get explanationUpdatedMessage =>
      'Explanation updated for everyone studying this course.';

  @override
  String thinkAboutMovesHint(String piece) {
    return 'Think about the $piece moves...';
  }

  @override
  String get writeHintPlaceholder => 'Write the hint...';

  @override
  String get hintUpdatedMessage =>
      'Hint updated for everyone testing this chapter.';

  @override
  String get masteryTestTitle => 'Mastery Test';

  @override
  String get thinkItThrough => 'Think it through...';

  @override
  String get correctFeedback => 'Correct!';

  @override
  String get notQuiteTryAgain => 'Not quite — try again';

  @override
  String get opponentThinkingTest => 'Opponent is thinking...';

  @override
  String get yourMovePlayOpeningLine => 'Your move — play the opening line';

  @override
  String get editHintTooltip => 'Edit hint';

  @override
  String get variationLabelUpper => 'VARIATION';

  @override
  String get overallProgressLabel => 'Overall progress';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total plies';
  }

  @override
  String get abortButton => 'Abort';

  @override
  String get getHintButton => 'Get Hint';

  @override
  String get chapterPassedTitle => 'Chapter Passed';

  @override
  String youInternalizedChapter(String chapter) {
    return 'You internalized $chapter.';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count variations completed';
  }

  @override
  String get returnToCourseButton => 'Return to Course';

  @override
  String hintForMoveTitle(String move) {
    return 'Hint for $move';
  }

  @override
  String get dailyPuzzleTitle => 'Daily Puzzle';

  @override
  String get downloadedPuzzlesTitle => 'Downloaded Puzzles';

  @override
  String get whiteToPlay => 'White to play';

  @override
  String get blackToPlay => 'Black to play';

  @override
  String hintLookAtPiece(String piece, String square) {
    return 'Look at your $piece on $square';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return 'Your $piece on $square is the key';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return 'Focus on the $piece sitting on $square';
  }

  @override
  String themeHintAbout(String theme) {
    return 'This puzzle is about $theme';
  }

  @override
  String themeHintWayOut(String theme) {
    return 'The $theme is your way out here';
  }

  @override
  String themeHintThinking(String theme) {
    return 'Try thinking in terms of $theme';
  }

  @override
  String get piecePawn => 'pawn';

  @override
  String get pieceKnight => 'knight';

  @override
  String get pieceBishop => 'bishop';

  @override
  String get pieceRook => 'rook';

  @override
  String get pieceQueen => 'queen';

  @override
  String get pieceKing => 'king';

  @override
  String get pieceGeneric => 'piece';

  @override
  String get mixedTacticsLabel => 'mixed tactics';

  @override
  String get allDownloadedSolvedMessage =>
      'All downloaded puzzles solved — download more next time you are online.';

  @override
  String get loadingNextPuzzles => 'Loading next puzzles...';

  @override
  String get noPuzzlesAvailable => 'No puzzles available.';

  @override
  String get yourRatingLabel => 'Your rating:';

  @override
  String get hintButton => 'Hint';

  @override
  String get showThemeButton => 'Show Theme';

  @override
  String get hintUsedButton => 'Hint Used';

  @override
  String get doneButton => 'Done';

  @override
  String get nextButton => 'Next';

  @override
  String get retryButton => 'Retry';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'You played $move in this position, which was $classification. Try to look for a better move.';
  }

  @override
  String get notBestMoveTryAgain =>
      'That is not the best move here. Try again and look for a stronger continuation.';

  @override
  String get greatJobFoundBestMove => 'Great job! You found the best move.';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return 'Look at your $piece on $square. That is the piece you need to move.';
  }

  @override
  String get allMyPuzzlesSolvedMessage => 'All puzzles solved — nice work!';

  @override
  String get noMyPuzzlesEmptyState =>
      'No puzzles available yet.\n\nFinish a game against Pippo — your mistakes will automatically become puzzles.';

  @override
  String puzzleCounterTitle(int current, int total) {
    return 'Puzzle $current of $total';
  }

  @override
  String get finishButton => 'Finish';

  @override
  String get nextPuzzleButton => 'Next Puzzle';

  @override
  String get allThemesTitle => 'All Themes';

  @override
  String get allThemesIntro =>
      'Practice all kinds of chess puzzles in one place. Pick a theme, test your skills, and see how well you can do across different parts of the game.';

  @override
  String get themesNeedInternetOffline =>
      'Themes need an internet connection to load a fresh batch. Your internet is offline right now.';

  @override
  String get needsInternetForBatch => 'Needs internet to load a fresh batch';

  @override
  String get themeGroupMates => 'Mates';

  @override
  String get themeGroupTactics => 'Tactics';

  @override
  String get themeGroupKingAttack => 'King Attack';

  @override
  String get themeGroupEndgames => 'Endgames';

  @override
  String get themeGroupPawnsPromotion => 'Pawns & Promotion';

  @override
  String get themeGroupStrategy => 'Strategy';

  @override
  String get themeMateIn1 => 'Mate In 1';

  @override
  String get themeMateIn1Desc => 'Find the checkmate in a single move.';

  @override
  String get themeMateIn2 => 'Mate In 2';

  @override
  String get themeMateIn2Desc =>
      'Set up the position and finish with checkmate on your next move.';

  @override
  String get themeMateIn3 => 'Mate In 3';

  @override
  String get themeMateIn3Desc =>
      'Find the winning sequence that leads to checkmate in three moves.';

  @override
  String get themeMateIn4 => 'Mate In 4';

  @override
  String get themeMateIn4Desc => 'Plan a few moves ahead to force checkmate.';

  @override
  String get themeMateIn5 => 'Mate In 5';

  @override
  String get themeMateIn5Desc =>
      'A longer mating sequence where every move matters.';

  @override
  String get themeOtherMates => 'Other Mates';

  @override
  String get themeOtherMatesDesc =>
      'Special mating patterns like Back Rank, Smothered, Anastasia, Arabian, Boden, Opera, and more.';

  @override
  String get themeFork => 'Fork';

  @override
  String get themeForkDesc => 'One piece attacks two or more targets at once.';

  @override
  String get themePin => 'Pin';

  @override
  String get themePinDesc =>
      'A piece is stuck because moving it would expose something more valuable.';

  @override
  String get themeSkewer => 'Skewer';

  @override
  String get themeSkewerDesc =>
      'Attack a valuable piece and win what is hiding behind it.';

  @override
  String get themeDiscoveredAttack => 'Discovered Attack';

  @override
  String get themeDiscoveredAttackDesc =>
      'Move one piece to uncover an attack from another.';

  @override
  String get themeDiscoveredCheck => 'Discovered Check';

  @override
  String get themeDiscoveredCheckDesc =>
      'Uncover a check by moving another piece out of the way.';

  @override
  String get themeDoubleCheck => 'Double Check';

  @override
  String get themeDoubleCheckDesc =>
      'Give check from two pieces at the same time.';

  @override
  String get themeSacrifice => 'Sacrifice';

  @override
  String get themeSacrificeDesc =>
      'Give up material to gain something stronger in return.';

  @override
  String get themeDeflection => 'Deflection';

  @override
  String get themeDeflectionDesc =>
      'Force a piece away from where it needs to be.';

  @override
  String get themeClearance => 'Clearance';

  @override
  String get themeClearanceDesc =>
      'Move a piece away to open the way for another piece.';

  @override
  String get themeCapturingDefender => 'Capturing Defender';

  @override
  String get themeCapturingDefenderDesc =>
      'Remove the piece protecting an important target.';

  @override
  String get themeAdvancedTactics => 'Advanced Tactics';

  @override
  String get themeAdvancedTacticsDesc =>
      'More difficult combinations involving several tactical ideas.';

  @override
  String get themeKingsideAttack => 'Kingside Attack';

  @override
  String get themeKingsideAttackDesc =>
      'Build an attack against the king on the kingside.';

  @override
  String get themeQueensideAttack => 'Queenside Attack';

  @override
  String get themeQueensideAttackDesc =>
      'Look for ways to break through around the enemy king on the queenside.';

  @override
  String get themeExposedKing => 'Exposed King';

  @override
  String get themeExposedKingDesc =>
      'Take advantage of a king that has lost its protection.';

  @override
  String get themeAttackingF2F7 => 'Attacking F2 F7';

  @override
  String get themeAttackingF2F7Desc =>
      'Target the weak f2 or f7 square near the king.';

  @override
  String get themeEndgame => 'Endgame';

  @override
  String get themeEndgameDesc =>
      'Find the best way to play when only a few pieces remain.';

  @override
  String get themeRookEndgame => 'Rook Endgame';

  @override
  String get themeRookEndgameDesc =>
      'Learn to make the most of your rooks in the endgame.';

  @override
  String get themeQueenEndgame => 'Queen Endgame';

  @override
  String get themeQueenEndgameDesc =>
      'Find the right moves in positions where queens remain on the board.';

  @override
  String get themeQueenRookEndgame => 'Queen Rook Endgame';

  @override
  String get themeQueenRookEndgameDesc =>
      'Handle endgames where queens and rooks are still in play.';

  @override
  String get themeBishopEndgame => 'Bishop Endgame';

  @override
  String get themeBishopEndgameDesc =>
      'Use your bishop and king to find the winning plan.';

  @override
  String get themeKnightEndgame => 'Knight Endgame';

  @override
  String get themeKnightEndgameDesc =>
      'Find the right moves in endgames where knights matter most.';

  @override
  String get themePawnEndgame => 'Pawn Endgame';

  @override
  String get themePawnEndgameDesc =>
      'Calculate pawn races and find the path to victory.';

  @override
  String get themeZugzwang => 'Zugzwang';

  @override
  String get themeZugzwangDesc =>
      'Put your opponent in a position where any move makes things worse.';

  @override
  String get themeAdvancedPawn => 'Advanced Pawn';

  @override
  String get themeAdvancedPawnDesc =>
      'Use a dangerous pawn that has pushed deep into enemy territory.';

  @override
  String get themePromotion => 'Promotion';

  @override
  String get themePromotionDesc =>
      'Push a pawn through to become a stronger piece.';

  @override
  String get themeUnderPromotion => 'Under Promotion';

  @override
  String get themeUnderPromotionDesc =>
      'Promote to something other than a queen when that\'s the winning move.';

  @override
  String get themeEnPassant => 'En Passant';

  @override
  String get themeEnPassantDesc =>
      'Spot the rare chance to capture a pawn using en passant.';

  @override
  String get themeQuietMove => 'Quiet Move';

  @override
  String get themeQuietMoveDesc =>
      'Find a calm move that creates a strong advantage without forcing tactics.';

  @override
  String get themeDefensiveMove => 'Defensive Move';

  @override
  String get themeDefensiveMoveDesc =>
      'Find the move that stops your opponent\'s threat.';

  @override
  String get themeAdvantage => 'Advantage';

  @override
  String get themeAdvantageDesc =>
      'Find the move that keeps or increases your advantage.';

  @override
  String get themeEquality => 'Equality';

  @override
  String get themeEqualityDesc =>
      'Find the move that keeps the position balanced.';

  @override
  String get themeCrushing => 'Crushing';

  @override
  String get themeCrushingDesc =>
      'Find the powerful move that turns a strong position into a winning one.';

  @override
  String get pippoThinking2 => 'Let me look for the best move';

  @override
  String get pippoThinking3 => 'One moment... I see a few ideas';

  @override
  String get pippoThinking4 => 'Calculating my reply';

  @override
  String get pippoThreatAsk1 => 'Can you spot what this move is threatening?';

  @override
  String get pippoThreatAsk2 => 'I have a little idea behind that move...';

  @override
  String get pippoThreatAsk3 =>
      'Watch out — that move puts something under pressure.';

  @override
  String get pippoThreatAsk4 =>
      'There may be more to that move than meets the eye.';

  @override
  String get pippoGreat1 => 'Great job finding the only move in this position!';

  @override
  String get pippoGreat2 => 'That was a great move — very well spotted.';

  @override
  String get pippoGreat3 =>
      'Excellent find. You handled that position beautifully.';

  @override
  String get pippoBrilliant1 => 'Brilliant! That move was wonderfully precise.';

  @override
  String get pippoBrilliant2 =>
      'What a brilliant idea — I did not expect that one.';

  @override
  String get pippoBrilliant3 =>
      'That was brilliant. You found a seriously creative move.';

  @override
  String get pippoFinished1 => 'That was a great game! Want to play again?';

  @override
  String get pippoFinished2 => 'Well played! Fancy another game?';

  @override
  String get pippoFinished3 => 'Good game — I enjoyed that one. Rematch?';

  @override
  String get classificationBookComment => 'A move from the opening book.';

  @override
  String get resignDialogTitle => 'Resign Game?';

  @override
  String get resignDialogBody =>
      'Are you sure you want to resign? This will end the current game.';

  @override
  String get resignConfirm => 'Resign';

  @override
  String get gameOverResignBlack => 'Black wins by resignation';

  @override
  String get gameOverResignWhite => 'White wins by resignation';

  @override
  String get gameOverDefault => 'Game Over';

  @override
  String get gameOverMateBlack => 'Black wins by Checkmate';

  @override
  String get gameOverMateWhite => 'White wins by Checkmate';

  @override
  String get gameOverStalemate => 'Draw by Stalemate';

  @override
  String get gameOverRepetition => 'Draw by Repetition';

  @override
  String get gameOverInsufficient => 'Draw by Insufficient Material';

  @override
  String get gameOverDrawn => 'Game Drawn';

  @override
  String get playStartFirst => 'Start a game first';

  @override
  String get takebackTrainingOnly =>
      'Takebacks are only available in Training mode';

  @override
  String get takebackNoMoves => 'No moves to take back';

  @override
  String get takebackDone => 'Move taken back';

  @override
  String get pippoMissBare => 'You missed a better move in this position.';

  @override
  String pippoMissWithMove(String move) {
    return 'You missed a better move in this position, you should have gone $move.';
  }

  @override
  String get pippoBlunderPause =>
      'That move was a blunder. Take it back, or continue and I will play on.';

  @override
  String get hintTrainingOnly => 'Hints are only available in Training mode';

  @override
  String get hintYourTurnOnly => 'Hints are only available on your turn';

  @override
  String get hintStillAnalyzing => 'Still analyzing... try again in a moment';

  @override
  String hintLookForPiece(String piece, String square) {
    return 'Look for a good move with your $piece on $square.';
  }

  @override
  String get playToolTakeback => 'Take back';

  @override
  String get playToolAskHint => 'Ask Pippo for a hint';

  @override
  String get playToolClassifyHeader => 'Classify';

  @override
  String get classifyYourMoves => 'Your moves';

  @override
  String get classifyPippoMoves => 'Pippo\'s moves';

  @override
  String get playingPippoTitle => 'Playing Pippo';

  @override
  String get resignButton => 'Resign';

  @override
  String get playAsHeader => 'PLAY AS';

  @override
  String get sideRandom => 'Random';

  @override
  String get strengthHeader => 'STRENGTH';

  @override
  String get optionsHeader => 'OPTIONS';

  @override
  String get modeLabel => 'Mode';

  @override
  String get modeChallenge => 'Challenge';

  @override
  String get modeTraining => 'Training';

  @override
  String get startGameButton => 'Start Game';

  @override
  String get perkFeedback => 'Get feedback on your moves';

  @override
  String get perkSeeThreats => 'See all threats';

  @override
  String get perkTakeback => 'Takeback moves whenever you want';

  @override
  String get perkBlunderPause => 'Pauses game when you make a blunder';

  @override
  String get perkHintsAllowed => 'Hints allowed';

  @override
  String get perkNoFeedback => 'No move feedback';

  @override
  String get perkHiddenThreats => 'Threats stay hidden';

  @override
  String get perkNoTakebacks => 'No takebacks';

  @override
  String get perkNoBlunderPause => 'Game keeps going after blunders';

  @override
  String get perkNoHints => 'No hints';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'Hide threats';

  @override
  String get showThreat => 'Show threat';

  @override
  String get blunderContinue => 'Continue';

  @override
  String get gameOverFallback => 'Game over';

  @override
  String get resultHome => 'Home';

  @override
  String get resultNewGame => 'New game';

  @override
  String get resultAnalyzeGame => 'Analyze game';

  @override
  String get gameToolsTooltip => 'Game tools';

  @override
  String get movesHeader => 'Moves';

  @override
  String moveCountLabel(int count) {
    return '$count moves';
  }

  @override
  String get movesEmptyPlay =>
      'Your moves will appear here as the game unfolds.';

  @override
  String get puzzleNotBest => 'Not the best move. Try again!';

  @override
  String get puzzleSessionComplete => 'Practice session complete!';

  @override
  String get practiceTitle => 'Practice';

  @override
  String get puzzleEmpty => 'No puzzles available.';

  @override
  String puzzleCounter(int current, int total) {
    return 'Puzzle $current/$total';
  }

  @override
  String get puzzleHint => 'Hint';

  @override
  String get puzzleShowMove => 'Show Move';

  @override
  String get puzzleUsedHint => 'Used Hint';

  @override
  String get puzzleNext => 'Next Puzzle';

  @override
  String get analysisTitle => 'Analysis';

  @override
  String get addGameTooltip => 'Add game or position';

  @override
  String get closeGameButton => 'Close';

  @override
  String get positionLoadedOk => 'Position loaded successfully';

  @override
  String get gameImportedOk => 'Game imported successfully';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess vs $opponent';
  }

  @override
  String get youLabel => 'You';

  @override
  String explorerGameLoaded(String white, String black) {
    return '$white vs $black loaded';
  }

  @override
  String get reviewNoGame => 'No game to review';

  @override
  String get reviewQuotaUsed =>
      'You have used today\'s game reviews. Upgrade to Pro for more.';

  @override
  String get analysisNoMoves => 'No moves to analyze';

  @override
  String get settingsEngineHeader => 'Engine';

  @override
  String get settingsEnableEngine => 'Enable Engine';

  @override
  String get settingsDepth => 'Depth';

  @override
  String get settingsClassificationHeader => 'Move Classification';

  @override
  String get settingsEnableClassification => 'Enable Classification';

  @override
  String get settingsThreatHeader => 'Threat Detector';

  @override
  String get settingsThreatToggle => 'Threat detector';

  @override
  String get settingsLinesLabel => 'Number of Lines (PV)';

  @override
  String get filterBook => 'Book';

  @override
  String get filterBrilliant => 'Brilliant';

  @override
  String get filterBlunder => 'Blunder';

  @override
  String get showLess => 'Show Less';

  @override
  String get showAll => 'Show All';

  @override
  String get analyzingBanner =>
      'Your game is being analyzed, you can leave this screen';

  @override
  String get fullViewTooltip => 'Full view';

  @override
  String get compactViewTooltip => 'Compact view';

  @override
  String get classifyingMove => 'Classifying move...';

  @override
  String get phraseBest => 'the best move';

  @override
  String get phraseBrilliant => 'a brilliant move';

  @override
  String get phraseGreat => 'a great move';

  @override
  String get phraseExcellent => 'an excellent move';

  @override
  String get phraseGood => 'a good move';

  @override
  String get phraseInaccuracy => 'an inaccuracy';

  @override
  String get phraseMistake => 'a mistake';

  @override
  String get phraseBlunder => 'a blunder';

  @override
  String get phraseMiss => 'a miss';

  @override
  String get phraseBook => 'a book move';

  @override
  String get phraseForced => 'a forced move';

  @override
  String sentenceBestSuffix(String move) {
    return ', $move was the best move';
  }

  @override
  String get retryReview => 'Retry review';

  @override
  String get reviewWaiting => 'Your game is being reviewed';

  @override
  String get pgnEmpty => 'No moves yet';

  @override
  String get pgnResume => 'Resume';

  @override
  String get showBestTooltip => 'Show best move';

  @override
  String get tabMoves => 'Moves';

  @override
  String get tabExplorer => 'Explorer';

  @override
  String get moveTreeHeader => 'Move tree';

  @override
  String get moveTreeEmpty => 'Your moves and variations will appear here.';

  @override
  String get gameReportButton => 'Game report';

  @override
  String get gameAnalysisTitle => 'Game Analysis';

  @override
  String get analyzeButton => 'Analyze';

  @override
  String get viewReportTooltip => 'View report';

  @override
  String get noReportYet => 'No Report Generated yet';

  @override
  String get addToAnalysisTitle => 'Add to analysis';

  @override
  String get addToAnalysisSubtitle =>
      'Start from a game, a position, or a custom board.';

  @override
  String get importSegment => 'Import';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'Setup';

  @override
  String get gameReportTitle => 'Game Report';

  @override
  String get accuraciesHeader => 'Accuracies';

  @override
  String get accuracyRerunHint =>
      'Re-run full-game analysis to compute accuracies.';

  @override
  String get pastePgnTooltip => 'Paste PGN';

  @override
  String get pastePgnButton => 'Paste copied PGN';

  @override
  String get searchingLabel => 'Searching...';

  @override
  String get importingLabel => 'Importing...';

  @override
  String get searchGamesButton => 'Search Games';

  @override
  String get startAnalysisButton => 'Start Analysis';

  @override
  String get fenFieldLabel => 'Board Position (FEN)';

  @override
  String get pasteFenTooltip => 'Paste FEN';

  @override
  String get pasteFenButton => 'Paste copied FEN';

  @override
  String get loadPositionButton => 'Load Position';

  @override
  String get inputPgnText => 'PGN Text';

  @override
  String get inputUsername => 'Username';

  @override
  String get inputGameUrl => 'Game URL';

  @override
  String get hintPastePgn => 'Paste PGN here...';

  @override
  String get hintEnterUsername => 'Enter username...';

  @override
  String get dialogOk => 'OK';

  @override
  String get lichessSignInCancelled => 'Lichess sign-in cancelled';

  @override
  String get boardSetupTitle => 'Board Setup';

  @override
  String get flipBoardTooltip => 'Flip board';

  @override
  String get clearBoardButton => 'Clear board';

  @override
  String get startPositionButton => 'Start position';

  @override
  String get whoMovesHeader => 'WHO MOVES FIRST';

  @override
  String get piecesHeader => 'PIECES';

  @override
  String get setupInstructions =>
      'Tap a piece to select it, then tap the board to place it. Drag a piece onto the board to add it, or drag it off the board to remove it.';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'Finish';

  @override
  String engineDepthLabel(int depth) {
    return 'Depth $depth';
  }

  @override
  String get analyzeGameTitle => 'Analyze Game';

  @override
  String get reviewsUnlimited => 'Unlimited game reviews available today';

  @override
  String reviewsLeftToday(int done, int total) {
    return '$done/$total game reviews available today';
  }

  @override
  String get analyzeTypeHeader => 'Type';

  @override
  String get analyzeModeAnalysis => 'Analysis';

  @override
  String get analyzeModeAnalysisDesc =>
      'Classifies all moves of your game using Stockfish';

  @override
  String get analyzeModeReview => 'Review';

  @override
  String get upgradeToProTitle => 'Upgrade to Pro';

  @override
  String get reviewModeDesc => 'Move-by-move explanations of your game';

  @override
  String get reviewLockedDesc => 'Unlock more game reviews every day';

  @override
  String get engineDepthHeader => 'Engine Depth';

  @override
  String depthValueLabel(int depth) {
    return 'Depth $depth';
  }

  @override
  String get depthHint => 'Higher depth can take more time to analyze';

  @override
  String get selectGameTitle => 'Select a Game';

  @override
  String get versusShort => 'vs';

  @override
  String get speedBullet => 'Bullet';

  @override
  String get speedBlitz => 'Blitz';

  @override
  String get speedRapid => 'Rapid';

  @override
  String get speedClassical => 'Classical';

  @override
  String get openingExplorerTitle => 'Opening Explorer';

  @override
  String get dbMasters => 'Masters';

  @override
  String get filtersHeader => 'Filters';

  @override
  String get theoreticalMoves => 'Theoretical Moves';

  @override
  String get topMasterGames => 'Top Master Games';

  @override
  String get recentGames => 'Recent Games';

  @override
  String get explorerSignInDesc =>
      'Sign in with Lichess to explore millions of games, top master games and opening statistics.';

  @override
  String get signInWithLichess => 'Sign in with Lichess';

  @override
  String get noOpeningData => 'No opening data available';

  @override
  String gamesCountLabel(int count) {
    return '$count games';
  }

  @override
  String get unknownPlayer => 'Unknown';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get indicatorGreen => 'Green';

  @override
  String get indicatorAmber => 'Amber';

  @override
  String get indicatorRed => 'Red';

  @override
  String get clsBest => 'Best';

  @override
  String get clsBrilliant => 'Brilliant';

  @override
  String get clsGreat => 'Great';

  @override
  String get clsExcellent => 'Excellent';

  @override
  String get clsGood => 'Good';

  @override
  String get clsInaccuracy => 'Inaccuracy';

  @override
  String get clsMistake => 'Mistake';

  @override
  String get clsBlunder => 'Blunder';

  @override
  String get clsBook => 'Book';

  @override
  String get clsForced => 'Forced';

  @override
  String get clsMiss => 'Miss';

  @override
  String averageRatingLabel(int rating) {
    return 'Avg. $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move is $label';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move was the best move.';
  }
}
