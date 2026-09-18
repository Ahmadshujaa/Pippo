// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'Joueur';

  @override
  String get notSignedIn => 'Non connecté';

  @override
  String get planAdmin => 'ADMIN';

  @override
  String get planPro => 'MEMBRE PRO';

  @override
  String get planFree => 'MEMBRE GRATUIT';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get appSettingsSection => 'Paramètres de l\'app';

  @override
  String get supportSection => 'Assistance';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceSubtitle => 'Thème clair, sombre ou système';

  @override
  String get subscriptionTitle => 'Abonnement';

  @override
  String get subscriptionSubtitle => 'Gérez votre offre Atlas Pro';

  @override
  String get languageTitle => 'Langue';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'Aide et assistance';

  @override
  String get helpSubtitle => 'FAQ et service client';

  @override
  String get contactSupportTitle => 'Contacter le support';

  @override
  String get contactSupportSubtitle => 'Contactez l\'équipe de support';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get chooseTheme => 'Choisir le thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get editDisplayName => 'Modifier le nom affiché';

  @override
  String displayNameRule(int maxLength) {
    return 'Choisissez un nom de $maxLength caractères maximum.';
  }

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get save => 'Enregistrer';

  @override
  String get languageSheetTitle => 'Choisir la langue';

  @override
  String get systemLanguage => 'Par défaut du système';

  @override
  String get supportTypeLabel => 'Type de problème';

  @override
  String get supportTypeHint =>
      'Choisissez l\'option qui décrit le mieux votre problème.';

  @override
  String get supportTypeUi => 'Interface';

  @override
  String get supportTypeError => 'Erreur';

  @override
  String get supportTypeOther => 'Autre';

  @override
  String get supportSubjectLabel => 'Objet';

  @override
  String get supportSubjectHint => 'Brève description de votre problème';

  @override
  String get supportMessageLabel => 'Message';

  @override
  String get supportMessageHint => 'Décrivez votre problème en détail...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max caractères';
  }

  @override
  String get supportSubmitButton => 'Envoyer le ticket';

  @override
  String get supportSuccessTitle => 'Ticket envoyé !';

  @override
  String get supportSuccessBody =>
      'Nous répondrons à votre e-mail sous 24 à 48 heures.';

  @override
  String get supportSuccessDone => 'Terminé';

  @override
  String get supportSignInTitle => 'Connectez-vous pour contacter le support';

  @override
  String get supportSignInBody =>
      'Les tickets sont liés à votre compte pour que nous puissions vous répondre. Connectez-vous et réessayez.';

  @override
  String get supportOfflineNotice =>
      'Vous êtes hors ligne. Reconnectez-vous pour envoyer votre ticket.';

  @override
  String get supportErrTypeRequired => 'Choisissez le type de problème.';

  @override
  String get supportErrSubjectRequired => 'Saisissez un objet.';

  @override
  String get supportErrMessageRequired => 'Saisissez un message.';

  @override
  String get supportErrSubjectTooLong => 'Votre objet est trop long.';

  @override
  String get supportErrMessageTooLong => 'Votre message est trop long.';

  @override
  String get supportErrGeneric =>
      'Impossible d\'envoyer votre ticket. Veuillez réessayer.';

  @override
  String get offlineBannerTitle => 'Pas de connexion Internet';

  @override
  String get retry => 'Réessayer';

  @override
  String get boardSettingsTitle => 'Réglages de l\'échiquier';

  @override
  String get pieceSetLabel => 'Jeu de pièces';

  @override
  String get boardThemeLabel => 'Thème de l\'échiquier';

  @override
  String get moveIndicatorLabel => 'Indicateur de coups';

  @override
  String get showCoordinatesLabel => 'Afficher les coordonnées';

  @override
  String get dragAndDropLabel => 'Glisser-déposer';

  @override
  String get soundLabel => 'Son';

  @override
  String get closeButton => 'Fermer';

  @override
  String get editExplanationTitle => 'Modifier l\'explication';

  @override
  String get writeExplanationHint => 'Rédigez l\'explication...';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get boardThemeEmerald => 'Émeraude';

  @override
  String get boardThemeMidnight => 'Minuit';

  @override
  String get boardThemePurple => 'Violet';

  @override
  String get boardThemeSand => 'Sable';

  @override
  String get boardThemeBlue => 'Bleu';

  @override
  String get boardThemeBrown => 'Marron';

  @override
  String get quotaUpgradeCta =>
      'Passez à Pro pour résoudre des puzzles illimités';

  @override
  String get downloadButton => 'Télécharger';

  @override
  String get upgradeNow => 'Passer à Pro';

  @override
  String get offlineDownloadsProNotice =>
      'Le téléchargement de puzzles hors ligne est réservé à Pro. Passez à Pro pour enregistrer des puzzles sur cet appareil.';

  @override
  String get savedForOffline =>
      'Enregistré sur cet appareil pour une résolution hors ligne';

  @override
  String get downloadPuzzlesTitle => 'Télécharger des puzzles';

  @override
  String get puzzleDecksTitle => 'Paquets de puzzles';

  @override
  String get deckRecentMistakes => 'Erreurs récentes';

  @override
  String get deckRecentMistakesSubtitle =>
      'Des tactiques tirées de vos parties perdues';

  @override
  String get deckMatingPatterns => 'Schémas de mat';

  @override
  String get deckMatingPatternsSubtitle => 'Maîtrisez les mats de finale';

  @override
  String get deckOpeningTraps => 'Pièges d\'ouverture';

  @override
  String get deckOpeningTrapsSubtitle =>
      'Les astuces courantes de votre répertoire';

  @override
  String get deckDailyChallenges => 'Défis quotidiens';

  @override
  String get deckDailyChallengesSubtitle => 'De nouveaux puzzles chaque jour';

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
  String get getStartedTitle => 'Commencer';

  @override
  String get welcomeTagline =>
      'Progressez vite aux échecs avec Pippo, votre coach personnel pour apprendre, vous améliorer et gagner plus de parties.';

  @override
  String get signInOrSignUpSubtitle =>
      'Connectez-vous ou créez un compte pour sauvegarder votre progression.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueAsGuest => 'Continuer en invité';

  @override
  String get errGoogleSignIn =>
      'Impossible de terminer la connexion avec Google.';

  @override
  String get signInTab => 'Connexion';

  @override
  String get signUpTab => 'Inscription';

  @override
  String get createAccountTitle => 'Créer un compte';

  @override
  String get orLabel => 'OU';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get welcomeBackTitle => 'Bon retour';

  @override
  String get signInSubtitle =>
      'Connectez-vous à votre compte et continuez à grimper au classement.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get emailHint => 'Saisissez votre e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signUpSubtitle =>
      'Rejoignez des milliers de joueurs et améliorez votre jeu.';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get firstNameHint => 'Jean';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get lastNameHint => 'Dupont';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get passwordUpdated => 'Mot de passe mis à jour.';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get enterResetCodeTitle => 'Saisir le code';

  @override
  String get resetIntro =>
      'Saisissez l\'e-mail de votre compte et nous vous enverrons un code de récupération.';

  @override
  String resetCodeSentIntro(String email) {
    return 'Nous avons envoyé un code de récupération à $email. Saisissez-le ci-dessous avec votre nouveau mot de passe.';
  }

  @override
  String get recoveryCodeLabel => 'Code de récupération';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmNewPasswordLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get updatePassword => 'Mettre à jour le mot de passe';

  @override
  String get sendRecoveryCode => 'Envoyer le code';

  @override
  String get errEnterValidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String get errEnterCodeFromEmail => 'Saisissez le code reçu par e-mail.';

  @override
  String get errPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get namePromptTitle => 'Comment doit-on vous appeler ?';

  @override
  String get namePromptSubtitle =>
      'Choisissez un nom pour votre profil afin que nous puissions personnaliser votre expérience.';

  @override
  String get yourNameHint => 'Votre nom';

  @override
  String get verifyEmailTitle => 'Vérifier l\'e-mail';

  @override
  String get enterVerificationCodeTitle => 'Saisissez le code de vérification';

  @override
  String get otpSentPrefix => 'Nous avons envoyé un code à 8 chiffres à\n';

  @override
  String get otpSentSuffix =>
      '. Vérifiez votre boîte de réception ou vos spams.';

  @override
  String get verifyCodeButton => 'Vérifier le code';

  @override
  String get didntReceiveCode => 'Vous n\'avez pas reçu le code ?';

  @override
  String get resend => 'Renvoyer';

  @override
  String resendInSeconds(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get verificationCodeResent => 'Code de vérification renvoyé';

  @override
  String helloGreeting(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get homeSubtitle =>
      'Prêt à apprendre quelque chose de nouveau aujourd\'hui ?';

  @override
  String get coursesSection => 'Cours';

  @override
  String get dailyPracticeSection => 'Entraînement du jour';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get todayLabel => 'AUJOURD\'HUI';

  @override
  String get gamesVsPippo => 'parties contre Pippo';

  @override
  String get puzzleRatingLabel => 'Classement puzzles';

  @override
  String get dailyStreakLabel => 'Série quotidienne';

  @override
  String get chaptersDoneLabel => 'Chapitres terminés';

  @override
  String get tacticsTrainingTitle => 'Entraînement tactique';

  @override
  String get tacticsTrainingSubtitle =>
      'Résolvez des puzzles et affûtez votre jeu';

  @override
  String get dailyPuzzleLabel => 'Puzzle du jour';

  @override
  String get playNow => 'Jouer';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCourses => 'Cours';

  @override
  String get navPuzzles => 'Puzzles';

  @override
  String get navAnalysis => 'Analyse';

  @override
  String get navMenu => 'Menu';

  @override
  String get planBadgeAdmin => 'ADMIN';

  @override
  String get planBadgeFree => 'GRATUIT';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return 'OFFRE $tier';
  }

  @override
  String get coursesComingSoon => 'Cours bientôt disponibles';

  @override
  String get continueLearning => 'Continuer l\'apprentissage';

  @override
  String get continueLearningButton => 'Continuer';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total variantes terminées',
      one: '$completed/$total variante terminée',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'Blancs';

  @override
  String get sideBlack => 'Noirs';

  @override
  String get sideWhiteInitial => 'B';

  @override
  String get sideBlackInitial => 'N';

  @override
  String courseMetaChip(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $count chapitres',
      one: '$side · 1 chapitre',
    );
    return '$_temp0';
  }

  @override
  String get puzzlesTitle => 'Puzzles';

  @override
  String get puzzlesIntroTitle => 'Affûtez votre tactique';

  @override
  String get puzzlesIntroSubtitle =>
      'Travaillez les thèmes qui comptent et corrigez les erreurs de vos parties.';

  @override
  String get puzzlesFromYourGamesTitle => 'Puzzles de vos parties';

  @override
  String get solveNowButton => 'Résoudre';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count puzzles restants';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'Pas encore de puzzles — terminez une partie contre Pippo et vos erreurs deviendront des puzzles.';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return '$count puzzles téléchargés — disponibles même hors ligne.';
  }

  @override
  String get mixedPuzzlesTitle => 'Puzzles mixtes';

  @override
  String get mixedPuzzlesSubtitle => 'Jouez des puzzles de thèmes variés';

  @override
  String get mixedPuzzlesRequiresInternet => 'Nécessite une connexion Internet';

  @override
  String get downloadingPuzzlesStatus => 'Téléchargement des puzzles...';

  @override
  String get downloadPuzzlesSubtitle =>
      'Gardez 10 à 100 puzzles pour résoudre hors ligne';

  @override
  String get playDownloadedPuzzlesTitle => 'Jouer les puzzles téléchargés';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count puzzles enregistrés — disponibles hors ligne';
  }

  @override
  String get practiceThemesSection => 'Travailler par thèmes';

  @override
  String get browseAllThemesButton => 'Voir tous les thèmes';

  @override
  String get themesRequireInternet => 'Les thèmes ont besoin d\'Internet';

  @override
  String get coursesTitle => 'Cours';

  @override
  String get coursesTabOpenings => 'Ouvertures';

  @override
  String get coursesTabMiddlegames => 'Milieu de jeu';

  @override
  String get coursesTabEndgames => 'Finales';

  @override
  String get noCoursesHereYet => 'Pas encore de cours ici.';

  @override
  String get tryAgainButton => 'Réessayer';

  @override
  String playAsSide(String side) {
    return 'Jouez les $side';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count chapitres';
  }

  @override
  String variationCountLabel(int count) {
    return '$count variantes';
  }

  @override
  String get courseDetailsTitle => 'Détails du cours';

  @override
  String get chaptersTitle => 'Chapitres';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO : $code';
  }

  @override
  String get noChaptersAvailable => 'Aucun chapitre disponible.';

  @override
  String get chapterCompletedBadge => 'Terminé';

  @override
  String get noVariationsAvailable => 'Aucune variante disponible';

  @override
  String get noVariationsForChapterYet =>
      'Pas encore de variantes pour ce chapitre.';

  @override
  String get learnButton => 'Apprendre';

  @override
  String get testButton => 'Test';

  @override
  String get pricingTitle => 'Passer Pro';

  @override
  String get pricingHeroTitle => 'Libérez tout\nvotre potentiel aux échecs.';

  @override
  String get pricingHeroSubtitle =>
      'Analyse avancée, puzzles illimités et coaching par IA.';

  @override
  String get pricingFaqHeader => 'QUESTIONS FRÉQUENTES';

  @override
  String get pricingFaqCancelQuestion => 'Puis-je annuler à tout moment ?';

  @override
  String get pricingFaqCancelAnswer =>
      'Oui, vous pouvez annuler votre abonnement Pro à tout moment. Vous gardez l\'accès jusqu\'à la fin de votre période.';

  @override
  String get pricingFaqTrialQuestion => 'Y a-t-il un essai gratuit ?';

  @override
  String get pricingFaqTrialAnswer =>
      'Pro inclut 7 jours d\'essai gratuit. Aucune carte bancaire pour commencer.';

  @override
  String get pricingFaqPaymentQuestion =>
      'Quels moyens de paiement acceptez-vous ?';

  @override
  String get pricingFaqPaymentAnswer =>
      'Nous acceptons les principales cartes bancaires, Apple Pay et Google Pay.';

  @override
  String get pricingMostPopularBadge => 'LE PLUS POPULAIRE';

  @override
  String get pricingFreeBadge => 'GRATUIT';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'Gratuit';

  @override
  String get pricingProPrice => '9,99 \$/mois';

  @override
  String get pricingFreePrice => '0 \$';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'Analyse moteur illimitée';

  @override
  String get pricingFeatureDeepClassification =>
      'Classification profonde des coups';

  @override
  String get pricingFeatureAiReview => 'Revue de parties par IA';

  @override
  String get pricingFeatureOpeningExplorer =>
      'Explorateur d\'ouvertures avancé';

  @override
  String get pricingFeatureUnlimitedPuzzles => 'Séries de puzzles illimitées';

  @override
  String get pricingFeatureTrainingPlans => 'Plans d\'entraînement pour vous';

  @override
  String get pricingFeaturePrioritySupport => 'Assistance prioritaire';

  @override
  String get pricingFeatureEarlyAccess =>
      'Accès en avant-première aux nouveautés';

  @override
  String get pricingFeatureBasicAnalysis => 'Analyse moteur de base';

  @override
  String get pricingFeatureStandardClassification =>
      'Classification standard des coups';

  @override
  String get pricingFeatureGameImport =>
      'Import de parties Lichess et Chess.com';

  @override
  String get pricingFeatureLimitedPuzzles => 'Séries de puzzles limitées';

  @override
  String get pricingFeatureCommunityAccess => 'Accès à la communauté';

  @override
  String get pricingStartTrialButton => 'Commencer l\'essai gratuit';

  @override
  String get pricingCurrentPlanButton => 'Offre actuelle';

  @override
  String get startingEngineStatus => 'Démarrage du moteur...';

  @override
  String get downloadPippoPrompt =>
      'Téléchargez Pippo (BaseModel.onnx) pour jouer hors ligne.';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received Mo / $total Mo';
  }

  @override
  String get downloadingStatus => 'Téléchargement...';

  @override
  String get downloadEngineButton => 'Télécharger le moteur';

  @override
  String get startChapterButton => 'Commencer le chapitre';

  @override
  String get finishChapterButton => 'Terminer le chapitre';

  @override
  String get takeTestButton => 'Passer le test';

  @override
  String get exploreBranchesButton => 'Explorer les variantes';

  @override
  String get moveToNextVariationButton => 'Passer à la variante suivante';

  @override
  String get variationsTitle => 'Variantes';

  @override
  String get alternativeBranchesTitle => 'Branches alternatives';

  @override
  String get noTheoryAvailable => 'Pas de théorie pour cette variante.';

  @override
  String get editBranchExplanationTooltip =>
      'Modifier l\'explication de la branche';

  @override
  String get editExplanationTooltip => 'Modifier l\'explication';

  @override
  String get editTheoryTooltip => 'Modifier la théorie';

  @override
  String branchEditTitle(String name) {
    return 'Branche : $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'Coup : $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'Chapitre : $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'Théorie : $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'Les comptes gratuits débloquent un nouveau chapitre par jour.';

  @override
  String playMovePrompt(String move) {
    return 'Jouez $move';
  }

  @override
  String get opponentThinking => 'Je réfléchis';

  @override
  String opponentPlayedMove(String move) {
    return 'L\'adversaire a joué $move';
  }

  @override
  String correctMoveWithName(String move) {
    return 'Correct ! $move';
  }

  @override
  String get notRightMove => 'Ce n\'est pas le bon coup';

  @override
  String get variationCompletedMessage => 'Variante terminée !';

  @override
  String get explanationUpdatedMessage =>
      'Explication mise à jour pour tous ceux qui étudient ce cours.';

  @override
  String thinkAboutMovesHint(String piece) {
    return 'Pensez aux coups de $piece...';
  }

  @override
  String get writeHintPlaceholder => 'Rédigez l\'indice...';

  @override
  String get hintUpdatedMessage =>
      'Indice mis à jour pour tous ceux qui passent ce test.';

  @override
  String get masteryTestTitle => 'Test final';

  @override
  String get thinkItThrough => 'Prenez le temps de réfléchir...';

  @override
  String get correctFeedback => 'Correct !';

  @override
  String get notQuiteTryAgain => 'Presque — réessayez';

  @override
  String get opponentThinkingTest => 'L\'adversaire réfléchit...';

  @override
  String get yourMovePlayOpeningLine => 'À vous — jouez la ligne d\'ouverture';

  @override
  String get editHintTooltip => 'Modifier l\'indice';

  @override
  String get variationLabelUpper => 'VARIANTE';

  @override
  String get overallProgressLabel => 'Progression totale';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total coups';
  }

  @override
  String get abortButton => 'Abandonner';

  @override
  String get getHintButton => 'Demander un indice';

  @override
  String get chapterPassedTitle => 'Chapitre réussi';

  @override
  String youInternalizedChapter(String chapter) {
    return 'Vous maîtrisez $chapter.';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count variantes terminées';
  }

  @override
  String get returnToCourseButton => 'Retour au cours';

  @override
  String hintForMoveTitle(String move) {
    return 'Indice pour $move';
  }

  @override
  String get dailyPuzzleTitle => 'Puzzle du jour';

  @override
  String get downloadedPuzzlesTitle => 'Puzzles téléchargés';

  @override
  String get whiteToPlay => 'Les Blancs jouent';

  @override
  String get blackToPlay => 'Les Noirs jouent';

  @override
  String hintLookAtPiece(String piece, String square) {
    return 'Regardez votre $piece en $square';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return 'Votre $piece en $square est la clé';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return 'Regardez bien la $piece qui est en $square';
  }

  @override
  String themeHintAbout(String theme) {
    return 'Ce puzzle parle de $theme';
  }

  @override
  String themeHintWayOut(String theme) {
    return '$theme est votre sortie ici';
  }

  @override
  String themeHintThinking(String theme) {
    return 'Essayez de penser en termes de $theme';
  }

  @override
  String get piecePawn => 'pion';

  @override
  String get pieceKnight => 'cavalier';

  @override
  String get pieceBishop => 'fou';

  @override
  String get pieceRook => 'tour';

  @override
  String get pieceQueen => 'dame';

  @override
  String get pieceKing => 'roi';

  @override
  String get pieceGeneric => 'pièce';

  @override
  String get mixedTacticsLabel => 'tactique mixte';

  @override
  String get allDownloadedSolvedMessage =>
      'Vous avez résolu tous les puzzles téléchargés — téléchargez-en plus à votre prochaine connexion.';

  @override
  String get loadingNextPuzzles => 'Chargement d\'autres puzzles...';

  @override
  String get noPuzzlesAvailable => 'Aucun puzzle disponible.';

  @override
  String get yourRatingLabel => 'Votre classement :';

  @override
  String get hintButton => 'Indice';

  @override
  String get showThemeButton => 'Voir le thème';

  @override
  String get hintUsedButton => 'Indice utilisé';

  @override
  String get doneButton => 'Terminé';

  @override
  String get nextButton => 'Suivant';

  @override
  String get retryButton => 'Réessayer';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'Vous avez joué $move dans cette position, et c\'était $classification. Cherchez un meilleur coup.';
  }

  @override
  String get notBestMoveTryAgain =>
      'Ce n\'est pas le meilleur coup ici. Réessayez et cherchez plus fort.';

  @override
  String get greatJobFoundBestMove =>
      'Bravo ! Vous avez trouvé le meilleur coup.';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return 'Regardez votre $piece en $square. C\'est la pièce à jouer.';
  }

  @override
  String get allMyPuzzlesSolvedMessage =>
      'Vous avez résolu tous les puzzles — beau travail !';

  @override
  String get noMyPuzzlesEmptyState =>
      'Aucun puzzle pour l\'instant.\n\nTerminez une partie contre Pippo — vos erreurs deviendront des puzzles toutes seules.';

  @override
  String puzzleCounterTitle(int current, int total) {
    return 'Puzzle $current sur $total';
  }

  @override
  String get finishButton => 'Terminer';

  @override
  String get nextPuzzleButton => 'Puzzle suivant';

  @override
  String get allThemesTitle => 'Tous les thèmes';

  @override
  String get allThemesIntro =>
      'Travaillez toutes sortes de puzzles au même endroit. Choisissez un thème, testez votre niveau et voyez comment vous vous en sortez dans chaque partie du jeu.';

  @override
  String get themesNeedInternetOffline =>
      'Les thèmes ont besoin d\'Internet pour charger de nouveaux puzzles. Vous êtes hors ligne en ce moment.';

  @override
  String get needsInternetForBatch =>
      'Internet requise pour charger des puzzles';

  @override
  String get themeGroupMates => 'Mats';

  @override
  String get themeGroupTactics => 'Tactique';

  @override
  String get themeGroupKingAttack => 'Attaque du roi';

  @override
  String get themeGroupEndgames => 'Finales';

  @override
  String get themeGroupPawnsPromotion => 'Pions et promotion';

  @override
  String get themeGroupStrategy => 'Stratégie';

  @override
  String get themeMateIn1 => 'Mat en 1';

  @override
  String get themeMateIn1Desc => 'Trouvez le mat en un seul coup.';

  @override
  String get themeMateIn2 => 'Mat en 2';

  @override
  String get themeMateIn2Desc =>
      'Préparez la position et terminez par un mat à votre prochain coup.';

  @override
  String get themeMateIn3 => 'Mat en 3';

  @override
  String get themeMateIn3Desc =>
      'Trouvez la suite gagnante qui mate en trois coups.';

  @override
  String get themeMateIn4 => 'Mat en 4';

  @override
  String get themeMateIn4Desc =>
      'Calculez quelques coups à l\'avance pour forcer le mat.';

  @override
  String get themeMateIn5 => 'Mat en 5';

  @override
  String get themeMateIn5Desc =>
      'Une longue suite de mat où chaque coup compte.';

  @override
  String get themeOtherMates => 'Autres mats';

  @override
  String get themeOtherMatesDesc =>
      'Des schémas spéciaux comme la rangée, l\'étouffé, Anastasia, l\'arabe, Boden, l\'Opéra et plus.';

  @override
  String get themeFork => 'Fourchette';

  @override
  String get themeForkDesc =>
      'Une pièce attaque deux cibles ou plus à la fois.';

  @override
  String get themePin => 'Clouage';

  @override
  String get themePinDesc =>
      'Une pièce reste coincée car partir exposerait quelque chose de plus précieux.';

  @override
  String get themeSkewer => 'Enfilade';

  @override
  String get themeSkewerDesc =>
      'Attaquez une pièce précieuse et prenez ce qui se cache derrière.';

  @override
  String get themeDiscoveredAttack => 'Attaque à la découverte';

  @override
  String get themeDiscoveredAttackDesc =>
      'Bougez une pièce pour libérer l\'attaque d\'une autre.';

  @override
  String get themeDiscoveredCheck => 'Échec à la découverte';

  @override
  String get themeDiscoveredCheckDesc =>
      'Faites échec en écartant une autre pièce du chemin.';

  @override
  String get themeDoubleCheck => 'Double échec';

  @override
  String get themeDoubleCheckDesc =>
      'Faites échec avec deux pièces en même temps.';

  @override
  String get themeSacrifice => 'Sacrifice';

  @override
  String get themeSacrificeDesc =>
      'Donnez du matériel pour obtenir quelque chose de plus fort en retour.';

  @override
  String get themeDeflection => 'Déviation';

  @override
  String get themeDeflectionDesc =>
      'Forcez une pièce à quitter l\'endroit où elle doit être.';

  @override
  String get themeClearance => 'Dégagement';

  @override
  String get themeClearanceDesc =>
      'Écartez une pièce pour ouvrir le chemin à une autre.';

  @override
  String get themeCapturingDefender => 'Prendre le défenseur';

  @override
  String get themeCapturingDefenderDesc =>
      'Éliminez la pièce qui protège une cible importante.';

  @override
  String get themeAdvancedTactics => 'Tactique avancée';

  @override
  String get themeAdvancedTacticsDesc =>
      'Des combinaisons plus dures avec plusieurs idées tactiques.';

  @override
  String get themeKingsideAttack => 'Attaque à l\'aile roi';

  @override
  String get themeKingsideAttackDesc =>
      'Lancez une attaque contre le roi à l\'aile roi.';

  @override
  String get themeQueensideAttack => 'Attaque à l\'aile dame';

  @override
  String get themeQueensideAttackDesc =>
      'Cherchez comment percer autour du roi adverse à l\'aile dame.';

  @override
  String get themeExposedKing => 'Roi exposé';

  @override
  String get themeExposedKingDesc =>
      'Profitez d\'un roi qui a perdu sa protection.';

  @override
  String get themeAttackingF2F7 => 'Attaque sur F2 F7';

  @override
  String get themeAttackingF2F7Desc =>
      'Visez la case faible f2 ou f7 près du roi.';

  @override
  String get themeEndgame => 'Finale';

  @override
  String get themeEndgameDesc =>
      'Trouvez la meilleure façon de jouer quand il reste peu de pièces.';

  @override
  String get themeRookEndgame => 'Finale de tours';

  @override
  String get themeRookEndgameDesc =>
      'Apprenez à tirer le meilleur de vos tours en finale.';

  @override
  String get themeQueenEndgame => 'Finale de dames';

  @override
  String get themeQueenEndgameDesc =>
      'Trouvez les bons coups dans les positions avec des dames sur l\'échiquier.';

  @override
  String get themeQueenRookEndgame => 'Finale dame et tour';

  @override
  String get themeQueenRookEndgameDesc =>
      'Jouez les finales où il reste dames et tours.';

  @override
  String get themeBishopEndgame => 'Finale de fous';

  @override
  String get themeBishopEndgameDesc =>
      'Utilisez votre fou et votre roi pour trouver le plan gagnant.';

  @override
  String get themeKnightEndgame => 'Finale de cavaliers';

  @override
  String get themeKnightEndgameDesc =>
      'Trouvez les bons coups dans les finales où les cavaliers comptent.';

  @override
  String get themePawnEndgame => 'Finale de pions';

  @override
  String get themePawnEndgameDesc =>
      'Calculez les courses de pions et trouvez le chemin vers la victoire.';

  @override
  String get themeZugzwang => 'Zugzwang';

  @override
  String get themeZugzwangDesc =>
      'Mettez l\'adversaire dans une position où tout coup aggrave tout.';

  @override
  String get themeAdvancedPawn => 'Pion avancé';

  @override
  String get themeAdvancedPawnDesc =>
      'Utilisez un pion dangereux entré loin en territoire adverse.';

  @override
  String get themePromotion => 'Promotion';

  @override
  String get themePromotionDesc =>
      'Amenez un pion au bout pour le changer en pièce plus forte.';

  @override
  String get themeUnderPromotion => 'Sous-promotion';

  @override
  String get themeUnderPromotionDesc =>
      'Changez en autre chose qu\'une dame quand c\'est ça qui gagne.';

  @override
  String get themeEnPassant => 'En passant';

  @override
  String get themeEnPassantDesc =>
      'Repérez la rare occasion de prendre en passant.';

  @override
  String get themeQuietMove => 'Coup calme';

  @override
  String get themeQuietMoveDesc =>
      'Trouvez un coup calme qui donne l\'avantage sans forcer la tactique.';

  @override
  String get themeDefensiveMove => 'Coup défensif';

  @override
  String get themeDefensiveMoveDesc =>
      'Trouvez le coup qui arrête la menace adverse.';

  @override
  String get themeAdvantage => 'Avantage';

  @override
  String get themeAdvantageDesc =>
      'Trouvez le coup qui garde ou augmente votre avantage.';

  @override
  String get themeEquality => 'Égalité';

  @override
  String get themeEqualityDesc =>
      'Trouvez le coup qui garde la position égale.';

  @override
  String get themeCrushing => 'Coup écrasant';

  @override
  String get themeCrushingDesc =>
      'Trouvez le coup fort qui change une bonne position en position gagnée.';

  @override
  String get pippoThinking2 => 'Laissez-moi chercher le meilleur coup';

  @override
  String get pippoThinking3 => 'Un moment... je vois quelques idées';

  @override
  String get pippoThinking4 => 'Je calcule ma réponse';

  @override
  String get pippoThreatAsk1 => 'Voyez-vous ce que ce coup menace ?';

  @override
  String get pippoThreatAsk2 => 'J\'ai une petite idée derrière ce coup...';

  @override
  String get pippoThreatAsk3 =>
      'Attention — ce coup met quelque chose sous pression.';

  @override
  String get pippoThreatAsk4 =>
      'Ce coup cache peut-être plus qu\'il n\'y paraît.';

  @override
  String get pippoGreat1 =>
      'Bravo d\'avoir trouvé le seul coup de la position !';

  @override
  String get pippoGreat2 => 'C\'était un super coup — très bien vu.';

  @override
  String get pippoGreat3 =>
      'Trouvaille excellente. Vous avez joué cette position à merveille.';

  @override
  String get pippoBrilliant1 =>
      'Brillant ! Ce coup était d\'une précision magnifique.';

  @override
  String get pippoBrilliant2 =>
      'Quelle idée brillante — je ne m\'y attendais pas.';

  @override
  String get pippoBrilliant3 =>
      'C\'était brillant. Vous avez trouvé un coup très créatif.';

  @override
  String get pippoFinished1 => 'Quelle belle partie ! On en rejoue une ?';

  @override
  String get pippoFinished2 => 'Bien joué ! Ça vous dit une autre partie ?';

  @override
  String get pippoFinished3 => 'Bonne partie — j\'ai aimé. Une revanche ?';

  @override
  String get classificationBookComment => 'Un coup du livre d\'ouvertures.';

  @override
  String get resignDialogTitle => 'Abandonner la partie ?';

  @override
  String get resignDialogBody =>
      'Voulez-vous vraiment abandonner ? Cela terminera la partie en cours.';

  @override
  String get resignConfirm => 'Abandonner';

  @override
  String get gameOverResignBlack => 'Les Noirs gagnent par abandon';

  @override
  String get gameOverResignWhite => 'Les Blancs gagnent par abandon';

  @override
  String get gameOverDefault => 'Partie terminée';

  @override
  String get gameOverMateBlack => 'Les Noirs gagnent par mat';

  @override
  String get gameOverMateWhite => 'Les Blancs gagnent par mat';

  @override
  String get gameOverStalemate => 'Nulle par pat';

  @override
  String get gameOverRepetition => 'Nulle par répétition';

  @override
  String get gameOverInsufficient => 'Nulle par manque de matériel';

  @override
  String get gameOverDrawn => 'Partie nulle';

  @override
  String get playStartFirst => 'Commencez une partie d\'abord';

  @override
  String get takebackTrainingOnly =>
      'Reprendre un coup n\'existe qu\'en mode Entraînement';

  @override
  String get takebackNoMoves => 'Aucun coup à reprendre';

  @override
  String get takebackDone => 'Coup repris';

  @override
  String get pippoMissBare =>
      'Vous avez raté un meilleur coup dans cette position.';

  @override
  String pippoMissWithMove(String move) {
    return 'Vous avez raté un meilleur coup dans cette position, il fallait jouer $move.';
  }

  @override
  String get pippoBlunderPause =>
      'Ce coup était une grosse erreur. Reprenez-le, ou continuez et je joue la suite.';

  @override
  String get hintTrainingOnly =>
      'Les indices n\'existent qu\'en mode Entraînement';

  @override
  String get hintYourTurnOnly => 'Les indices n\'existent qu\'à votre tour';

  @override
  String get hintStillAnalyzing =>
      'J\'analyse encore... réessayez dans un moment';

  @override
  String hintLookForPiece(String piece, String square) {
    return 'Cherchez un bon coup avec votre $piece en $square.';
  }

  @override
  String get playToolTakeback => 'Reprendre';

  @override
  String get playToolAskHint => 'Demander un indice à Pippo';

  @override
  String get playToolClassifyHeader => 'Classer';

  @override
  String get classifyYourMoves => 'Vos coups';

  @override
  String get classifyPippoMoves => 'Coups de Pippo';

  @override
  String get playingPippoTitle => 'Partie contre Pippo';

  @override
  String get resignButton => 'Abandonner';

  @override
  String get playAsHeader => 'JOUER';

  @override
  String get sideRandom => 'Aléatoire';

  @override
  String get strengthHeader => 'FORCE';

  @override
  String get optionsHeader => 'OPTIONS';

  @override
  String get modeLabel => 'Mode';

  @override
  String get modeChallenge => 'Défi';

  @override
  String get modeTraining => 'Entraînement';

  @override
  String get startGameButton => 'Commencer la partie';

  @override
  String get perkFeedback => 'Recevez des avis sur vos coups';

  @override
  String get perkSeeThreats => 'Voyez toutes les menaces';

  @override
  String get perkTakeback => 'Reprenez des coups quand vous voulez';

  @override
  String get perkBlunderPause =>
      'Pause la partie si vous faites une grosse erreur';

  @override
  String get perkHintsAllowed => 'Indices autorisés';

  @override
  String get perkNoFeedback => 'Aucun avis sur les coups';

  @override
  String get perkHiddenThreats => 'Menaces cachées';

  @override
  String get perkNoTakebacks => 'Aucune reprise';

  @override
  String get perkNoBlunderPause =>
      'La partie continue après les grosses erreurs';

  @override
  String get perkNoHints => 'Aucun indice';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'Cacher les menaces';

  @override
  String get showThreat => 'Voir la menace';

  @override
  String get blunderContinue => 'Continuer';

  @override
  String get gameOverFallback => 'Partie terminée';

  @override
  String get resultHome => 'Accueil';

  @override
  String get resultNewGame => 'Nouvelle partie';

  @override
  String get resultAnalyzeGame => 'Analyser la partie';

  @override
  String get gameToolsTooltip => 'Outils de jeu';

  @override
  String get movesHeader => 'Coups';

  @override
  String moveCountLabel(int count) {
    return '$count coups';
  }

  @override
  String get movesEmptyPlay => 'Vos coups apparaîtront ici pendant la partie.';

  @override
  String get puzzleNotBest => 'Pas le meilleur coup. Réessayez !';

  @override
  String get puzzleSessionComplete => 'Séance d\'entraînement terminée !';

  @override
  String get practiceTitle => 'Entraînement';

  @override
  String get puzzleEmpty => 'Aucun puzzle disponible.';

  @override
  String puzzleCounter(int current, int total) {
    return 'Puzzle $current/$total';
  }

  @override
  String get puzzleHint => 'Indice';

  @override
  String get puzzleShowMove => 'Voir le coup';

  @override
  String get puzzleUsedHint => 'Indice utilisé';

  @override
  String get puzzleNext => 'Puzzle suivant';

  @override
  String get analysisTitle => 'Analyse';

  @override
  String get addGameTooltip => 'Ajouter une partie ou une position';

  @override
  String get closeGameButton => 'Fermer';

  @override
  String get positionLoadedOk => 'Position chargée';

  @override
  String get gameImportedOk => 'Partie importée';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess vs $opponent';
  }

  @override
  String get youLabel => 'Vous';

  @override
  String explorerGameLoaded(String white, String black) {
    return '$white vs $black chargée';
  }

  @override
  String get reviewNoGame => 'Aucune partie à revoir';

  @override
  String get reviewQuotaUsed =>
      'Vous avez utilisé les revues du jour. Passez à Pro pour en avoir plus.';

  @override
  String get analysisNoMoves => 'Aucun coup à analyser';

  @override
  String get settingsEngineHeader => 'Moteur';

  @override
  String get settingsEnableEngine => 'Activer le moteur';

  @override
  String get settingsDepth => 'Profondeur';

  @override
  String get settingsClassificationHeader => 'Classification des coups';

  @override
  String get settingsEnableClassification => 'Activer la classification';

  @override
  String get settingsThreatHeader => 'Détecteur de menaces';

  @override
  String get settingsThreatToggle => 'Détecteur de menaces';

  @override
  String get settingsLinesLabel => 'Nombre de lignes';

  @override
  String get filterBook => 'Livre';

  @override
  String get filterBrilliant => 'Brillant';

  @override
  String get filterBlunder => 'Grosse erreur';

  @override
  String get showLess => 'Voir moins';

  @override
  String get showAll => 'Tout voir';

  @override
  String get analyzingBanner =>
      'Votre partie est en cours d\'analyse, vous pouvez quitter cet écran';

  @override
  String get fullViewTooltip => 'Vue complète';

  @override
  String get compactViewTooltip => 'Vue compacte';

  @override
  String get classifyingMove => 'Classification du coup...';

  @override
  String get phraseBest => 'le meilleur coup';

  @override
  String get phraseBrilliant => 'un coup brillant';

  @override
  String get phraseGreat => 'un super coup';

  @override
  String get phraseExcellent => 'un excellent coup';

  @override
  String get phraseGood => 'un bon coup';

  @override
  String get phraseInaccuracy => 'une imprécision';

  @override
  String get phraseMistake => 'une erreur';

  @override
  String get phraseBlunder => 'une grosse erreur';

  @override
  String get phraseMiss => 'une occasion ratée';

  @override
  String get phraseBook => 'un coup de livre';

  @override
  String get phraseForced => 'un coup forcé';

  @override
  String sentenceBestSuffix(String move) {
    return ', $move était le meilleur coup';
  }

  @override
  String get retryReview => 'Réessayer la revue';

  @override
  String get reviewWaiting => 'Votre partie est en cours de revue';

  @override
  String get pgnEmpty => 'Pas encore de coups';

  @override
  String get pgnResume => 'Reprendre';

  @override
  String get showBestTooltip => 'Voir le meilleur coup';

  @override
  String get tabMoves => 'Coups';

  @override
  String get tabExplorer => 'Explorateur';

  @override
  String get moveTreeHeader => 'Arbre des coups';

  @override
  String get moveTreeEmpty => 'Vos coups et variantes apparaîtront ici.';

  @override
  String get gameReportButton => 'Rapport de partie';

  @override
  String get gameAnalysisTitle => 'Analyse de partie';

  @override
  String get analyzeButton => 'Analyser';

  @override
  String get viewReportTooltip => 'Voir le rapport';

  @override
  String get noReportYet => 'Pas encore de rapport';

  @override
  String get addToAnalysisTitle => 'Ajouter à l\'analyse';

  @override
  String get addToAnalysisSubtitle =>
      'Partez d\'une partie, d\'une position ou d\'un échiquier libre.';

  @override
  String get importSegment => 'Importer';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'Placer';

  @override
  String get gameReportTitle => 'Rapport de partie';

  @override
  String get accuraciesHeader => 'Précision';

  @override
  String get accuracyRerunHint =>
      'Relancez l\'analyse complète pour calculer la précision.';

  @override
  String get pastePgnTooltip => 'Coller le PGN';

  @override
  String get pastePgnButton => 'Coller le PGN copié';

  @override
  String get searchingLabel => 'Recherche...';

  @override
  String get importingLabel => 'Import...';

  @override
  String get searchGamesButton => 'Chercher des parties';

  @override
  String get startAnalysisButton => 'Lancer l\'analyse';

  @override
  String get fenFieldLabel => 'Position (FEN)';

  @override
  String get pasteFenTooltip => 'Coller le FEN';

  @override
  String get pasteFenButton => 'Coller le FEN copié';

  @override
  String get loadPositionButton => 'Charger la position';

  @override
  String get inputPgnText => 'Texte PGN';

  @override
  String get inputUsername => 'Pseudo';

  @override
  String get inputGameUrl => 'Lien de partie';

  @override
  String get hintPastePgn => 'Collez le PGN ici...';

  @override
  String get hintEnterUsername => 'Tapez le pseudo...';

  @override
  String get dialogOk => 'OK';

  @override
  String get lichessSignInCancelled => 'Connexion Lichess annulée';

  @override
  String get boardSetupTitle => 'Placer la position';

  @override
  String get flipBoardTooltip => 'Retourner l\'échiquier';

  @override
  String get clearBoardButton => 'Vider l\'échiquier';

  @override
  String get startPositionButton => 'Position de départ';

  @override
  String get whoMovesHeader => 'QUI JOUE EN PREMIER';

  @override
  String get piecesHeader => 'PIÈCES';

  @override
  String get setupInstructions =>
      'Touchez une pièce pour la choisir puis touchez l\'échiquier pour la placer. Glissez une pièce sur l\'échiquier pour l\'ajouter, ou hors de l\'échiquier pour la retirer.';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'Terminer';

  @override
  String engineDepthLabel(int depth) {
    return 'Profondeur $depth';
  }

  @override
  String get analyzeGameTitle => 'Analyser la partie';

  @override
  String get reviewsUnlimited => 'Revues illimitées aujourd\'hui';

  @override
  String reviewsLeftToday(int done, int total) {
    return '$done/$total revues disponibles aujourd\'hui';
  }

  @override
  String get analyzeTypeHeader => 'Type';

  @override
  String get analyzeModeAnalysis => 'Analyse';

  @override
  String get analyzeModeAnalysisDesc =>
      'Classe tous les coups de votre partie avec Stockfish';

  @override
  String get analyzeModeReview => 'Revue';

  @override
  String get upgradeToProTitle => 'Passer à Pro';

  @override
  String get reviewModeDesc => 'Explications coup par coup de votre partie';

  @override
  String get reviewLockedDesc => 'Débloquez plus de revues chaque jour';

  @override
  String get engineDepthHeader => 'Profondeur du moteur';

  @override
  String depthValueLabel(int depth) {
    return 'Profondeur $depth';
  }

  @override
  String get depthHint =>
      'Plus de profondeur peut prendre plus de temps à analyser';

  @override
  String get selectGameTitle => 'Choisir une partie';

  @override
  String get versusShort => 'vs';

  @override
  String get speedBullet => 'Bullet';

  @override
  String get speedBlitz => 'Blitz';

  @override
  String get speedRapid => 'Rapides';

  @override
  String get speedClassical => 'Classiques';

  @override
  String get openingExplorerTitle => 'Explorateur d\'ouvertures';

  @override
  String get dbMasters => 'Maîtres';

  @override
  String get filtersHeader => 'Filtres';

  @override
  String get theoreticalMoves => 'Coups théoriques';

  @override
  String get topMasterGames => 'Meilleures parties de maîtres';

  @override
  String get recentGames => 'Parties récentes';

  @override
  String get explorerSignInDesc =>
      'Connectez-vous avec Lichess pour explorer des millions de parties, des parties de maîtres et des stats d\'ouvertures.';

  @override
  String get signInWithLichess => 'Se connecter avec Lichess';

  @override
  String get noOpeningData => 'Aucune donnée d\'ouverture';

  @override
  String gamesCountLabel(int count) {
    return '$count parties';
  }

  @override
  String get unknownPlayer => 'Inconnu';

  @override
  String get monthJanuary => 'janvier';

  @override
  String get monthFebruary => 'février';

  @override
  String get monthMarch => 'mars';

  @override
  String get monthApril => 'avril';

  @override
  String get monthMay => 'mai';

  @override
  String get monthJune => 'juin';

  @override
  String get monthJuly => 'juillet';

  @override
  String get monthAugust => 'août';

  @override
  String get monthSeptember => 'septembre';

  @override
  String get monthOctober => 'octobre';

  @override
  String get monthNovember => 'novembre';

  @override
  String get monthDecember => 'décembre';

  @override
  String get indicatorGreen => 'Vert';

  @override
  String get indicatorAmber => 'Ambre';

  @override
  String get indicatorRed => 'Rouge';

  @override
  String get clsBest => 'Le meilleur';

  @override
  String get clsBrilliant => 'Brillant';

  @override
  String get clsGreat => 'Super';

  @override
  String get clsExcellent => 'Excellent';

  @override
  String get clsGood => 'Bon';

  @override
  String get clsInaccuracy => 'Imprécision';

  @override
  String get clsMistake => 'Erreur';

  @override
  String get clsBlunder => 'Grosse erreur';

  @override
  String get clsBook => 'Livre';

  @override
  String get clsForced => 'Forcé';

  @override
  String get clsMiss => 'Occasion ratée';

  @override
  String averageRatingLabel(int rating) {
    return 'Moy. $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move est $label';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move était le meilleur coup.';
  }
}
