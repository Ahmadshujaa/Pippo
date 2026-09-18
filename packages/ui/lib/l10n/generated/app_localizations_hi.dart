// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'खिलाड़ी';

  @override
  String get notSignedIn => 'साइन इन नहीं हैं';

  @override
  String get planAdmin => 'एडमिन';

  @override
  String get planPro => 'PRO सदस्य';

  @override
  String get planFree => 'फ्री सदस्य';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get appSettingsSection => 'ऐप सेटिंग्स';

  @override
  String get supportSection => 'सहायता';

  @override
  String get appearanceTitle => 'दिखावट';

  @override
  String get appearanceSubtitle => 'लाइट, डार्क या सिस्टम थीम';

  @override
  String get subscriptionTitle => 'सदस्यता';

  @override
  String get subscriptionSubtitle => 'अपना Atlas Pro प्लान प्रबंधित करें';

  @override
  String get languageTitle => 'भाषा';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'मदद और सहायता';

  @override
  String get helpSubtitle => 'सामान्य प्रश्न और ग्राहक सेवा';

  @override
  String get contactSupportTitle => 'सहायता से संपर्क करें';

  @override
  String get contactSupportSubtitle => 'सहायता टीम से संपर्क करें';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get chooseTheme => 'थीम चुनें';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get editDisplayName => 'डिस्प्ले नाम बदलें';

  @override
  String displayNameRule(int maxLength) {
    return '$maxLength अक्षरों तक का नाम चुनें।';
  }

  @override
  String get displayNameLabel => 'डिस्प्ले नाम';

  @override
  String get save => 'सहेजें';

  @override
  String get languageSheetTitle => 'भाषा चुनें';

  @override
  String get systemLanguage => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get supportTypeLabel => 'समस्या का प्रकार';

  @override
  String get supportTypeHint =>
      'वह विकल्प चुनें जो आपकी समस्या का सबसे अच्छा वर्णन करता हो।';

  @override
  String get supportTypeUi => 'इंटरफ़ेस';

  @override
  String get supportTypeError => 'त्रुटि';

  @override
  String get supportTypeOther => 'अन्य';

  @override
  String get supportSubjectLabel => 'विषय';

  @override
  String get supportSubjectHint => 'आपकी समस्या का संक्षिप्त विवरण';

  @override
  String get supportMessageLabel => 'संदेश';

  @override
  String get supportMessageHint => 'कृपया अपनी समस्या विस्तार से बताएं...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max अक्षर';
  }

  @override
  String get supportSubmitButton => 'टिकट भेजें';

  @override
  String get supportSuccessTitle => 'टिकट भेज दिया गया!';

  @override
  String get supportSuccessBody =>
      'हम 24-48 घंटों में आपके ईमेल पर जवाब देंगे।';

  @override
  String get supportSuccessDone => 'हो गया';

  @override
  String get supportSignInTitle => 'सहायता से संपर्क करने के लिए साइन इन करें';

  @override
  String get supportSignInBody =>
      'टिकट आपके खाते से जुड़े होते हैं ताकि हम आपको जवाब दे सकें। साइन इन करके फिर से प्रयास करें।';

  @override
  String get supportOfflineNotice =>
      'आप ऑफ़लाइन हैं। टिकट भेजने के लिए दोबारा कनेक्ट करें।';

  @override
  String get supportErrTypeRequired => 'समस्या का प्रकार चुनें।';

  @override
  String get supportErrSubjectRequired => 'विषय दर्ज करें।';

  @override
  String get supportErrMessageRequired => 'संदेश दर्ज करें।';

  @override
  String get supportErrSubjectTooLong => 'आपका विषय बहुत लंबा है।';

  @override
  String get supportErrMessageTooLong => 'आपका संदेश बहुत लंबा है।';

  @override
  String get supportErrGeneric =>
      'आपका टिकट भेजा नहीं जा सका। कृपया फिर से प्रयास करें।';

  @override
  String get offlineBannerTitle => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get boardSettingsTitle => 'बोर्ड सेटिंग्स';

  @override
  String get pieceSetLabel => 'पीस सेट';

  @override
  String get boardThemeLabel => 'बोर्ड थीम';

  @override
  String get moveIndicatorLabel => 'चाल संकेत';

  @override
  String get showCoordinatesLabel => 'निर्देशांक दिखाएँ';

  @override
  String get dragAndDropLabel => 'खींचें और छोड़ें';

  @override
  String get soundLabel => 'ध्वनि';

  @override
  String get closeButton => 'बंद करें';

  @override
  String get editExplanationTitle => 'व्याख्या संपादित करें';

  @override
  String get writeExplanationHint => 'व्याख्या लिखें...';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get boardThemeEmerald => 'पन्ना';

  @override
  String get boardThemeMidnight => 'मध्यरात्रि';

  @override
  String get boardThemePurple => 'बैंगनी';

  @override
  String get boardThemeSand => 'रेत';

  @override
  String get boardThemeBlue => 'नीला';

  @override
  String get boardThemeBrown => 'भूरा';

  @override
  String get quotaUpgradeCta =>
      'असीमित पज़ल हल करने के लिए Pro में अपग्रेड करें';

  @override
  String get downloadButton => 'डाउनलोड';

  @override
  String get upgradeNow => 'अभी अपग्रेड करें';

  @override
  String get offlineDownloadsProNotice =>
      'ऑफ़लाइन पज़ल डाउनलोड Pro के साथ उपलब्ध हैं। इस डिवाइस पर पज़ल सहेजने के लिए अपग्रेड करें।';

  @override
  String get savedForOffline => 'ऑफ़लाइन हल करने के लिए इस डिवाइस पर सहेजा गया';

  @override
  String get downloadPuzzlesTitle => 'पज़ल डाउनलोड करें';

  @override
  String get puzzleDecksTitle => 'पज़ल डेक';

  @override
  String get deckRecentMistakes => 'हाल की गलतियाँ';

  @override
  String get deckRecentMistakesSubtitle => 'आपके हारे हुए गेम से टैक्टिक्स';

  @override
  String get deckMatingPatterns => 'मेट पैटर्न';

  @override
  String get deckMatingPatternsSubtitle => 'एंडगेम मेट में महारत हासिल करें';

  @override
  String get deckOpeningTraps => 'ओपनिंग ट्रैप';

  @override
  String get deckOpeningTrapsSubtitle => 'आपकी रेपर्टरी के आम ट्रिक्स';

  @override
  String get deckDailyChallenges => 'दैनिक चुनौतियाँ';

  @override
  String get deckDailyChallengesSubtitle => 'हर दिन नए पज़ल';

  @override
  String selectedPuzzleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पज़ल',
      one: '1 पज़ल',
    );
    return '$_temp0';
  }

  @override
  String get getStartedTitle => 'शुरू करें';

  @override
  String get welcomeTagline =>
      'Pippo के साथ तेज़ी से शतरंज में सुधार करें — आपका निजी कोच, जो सीखने, आगे बढ़ने और ज़्यादा गेम जीतने में मदद करता है।';

  @override
  String get signInOrSignUpSubtitle =>
      'अपनी प्रगति सहेजने के लिए साइन इन या साइन अप करें।';

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get continueAsGuest => 'मेहमान के रूप में जारी रखें';

  @override
  String get errGoogleSignIn => 'Google साइन-इन पूरा नहीं हो सका।';

  @override
  String get signInTab => 'साइन इन';

  @override
  String get signUpTab => 'साइन अप';

  @override
  String get createAccountTitle => 'खाता बनाएँ';

  @override
  String get orLabel => 'या';

  @override
  String get registerButton => 'रजिस्टर करें';

  @override
  String get welcomeBackTitle => 'वापसी पर स्वागत है';

  @override
  String get signInSubtitle => 'अपने खाते में साइन इन करें और आगे बढ़ते रहें।';

  @override
  String get emailLabel => 'ईमेल पता';

  @override
  String get emailHint => 'अपना ईमेल दर्ज करें';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get signUpSubtitle =>
      'हज़ारों खिलाड़ियों से जुड़ें और अपना खेल सुधारें।';

  @override
  String get firstNameLabel => 'पहला नाम';

  @override
  String get firstNameHint => 'राहुल';

  @override
  String get lastNameLabel => 'उपनाम';

  @override
  String get lastNameHint => 'शर्मा';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get passwordUpdated => 'पासवर्ड अपडेट हो गया।';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get enterResetCodeTitle => 'रीसेट कोड दर्ज करें';

  @override
  String get resetIntro =>
      'अपने खाते का ईमेल दर्ज करें, हम आपको रिकवरी कोड भेजेंगे।';

  @override
  String resetCodeSentIntro(String email) {
    return 'हमने $email पर रिकवरी कोड भेजा है। इसे नीचे अपने नए पासवर्ड के साथ दर्ज करें।';
  }

  @override
  String get recoveryCodeLabel => 'रिकवरी कोड';

  @override
  String get newPasswordLabel => 'नया पासवर्ड';

  @override
  String get confirmNewPasswordLabel => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get sendRecoveryCode => 'रिकवरी कोड भेजें';

  @override
  String get errEnterValidEmail => 'मान्य ईमेल पता दर्ज करें।';

  @override
  String get errEnterCodeFromEmail => 'अपने ईमेल पर मिला कोड दर्ज करें।';

  @override
  String get errPasswordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get namePromptTitle => 'हम आपको क्या कहें?';

  @override
  String get namePromptSubtitle =>
      'अपनी प्रोफ़ाइल के लिए एक नाम चुनें ताकि हम आपका अनुभव व्यक्तिगत बना सकें।';

  @override
  String get yourNameHint => 'आपका नाम';

  @override
  String get verifyEmailTitle => 'ईमेल सत्यापित करें';

  @override
  String get enterVerificationCodeTitle => 'सत्यापन कोड दर्ज करें';

  @override
  String get otpSentPrefix => 'हमने 8 अंकों का कोड भेजा है\n';

  @override
  String get otpSentSuffix => ' पर। कृपया अपना इनबॉक्स या स्पैम फ़ोल्डर देखें।';

  @override
  String get verifyCodeButton => 'कोड सत्यापित करें';

  @override
  String get didntReceiveCode => 'कोड नहीं मिला?';

  @override
  String get resend => 'फिर भेजें';

  @override
  String resendInSeconds(int seconds) {
    return '$seconds सेकंड में फिर भेजें';
  }

  @override
  String get verificationCodeResent => 'सत्यापन कोड फिर भेजा गया';

  @override
  String helloGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get homeSubtitle => 'आज कुछ नया सीखने के लिए तैयार हैं?';

  @override
  String get coursesSection => 'कोर्स';

  @override
  String get dailyPracticeSection => 'रोज़ का अभ्यास';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get todayLabel => 'आज';

  @override
  String get gamesVsPippo => 'Pippo के खिलाफ गेम';

  @override
  String get puzzleRatingLabel => 'पज़ल रेटिंग';

  @override
  String get dailyStreakLabel => 'रोज़ की लय';

  @override
  String get chaptersDoneLabel => 'पूरे किए अध्याय';

  @override
  String get tacticsTrainingTitle => 'टैक्टिक्स ट्रेनिंग';

  @override
  String get tacticsTrainingSubtitle => 'पज़ल हल करें और अपना खेल निखारें';

  @override
  String get dailyPuzzleLabel => 'आज का पज़ल';

  @override
  String get playNow => 'अभी खेलें';

  @override
  String get navHome => 'होम';

  @override
  String get navCourses => 'कोर्स';

  @override
  String get navPuzzles => 'पज़ल';

  @override
  String get navAnalysis => 'विश्लेषण';

  @override
  String get navMenu => 'मेन्यू';

  @override
  String get planBadgeAdmin => 'एडमिन';

  @override
  String get planBadgeFree => 'फ्री';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return '$tier प्लान';
  }

  @override
  String get coursesComingSoon => 'कोर्स जल्द आ रहे हैं';

  @override
  String get continueLearning => 'सीखना जारी रखें';

  @override
  String get continueLearningButton => 'सीखना जारी रखें';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total वैरिएशन पूरे',
      one: '$completed/$total वैरिएशन पूरा',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'सफ़ेद';

  @override
  String get sideBlack => 'काला';

  @override
  String get sideWhiteInitial => 'स';

  @override
  String get sideBlackInitial => 'क';

  @override
  String courseMetaChip(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $count अध्याय',
      one: '$side · 1 अध्याय',
    );
    return '$_temp0';
  }

  @override
  String get puzzlesTitle => 'पज़ल';

  @override
  String get puzzlesIntroTitle => 'अपनी टैक्टिक्स निखारें';

  @override
  String get puzzlesIntroSubtitle =>
      'उन थीम पर ट्रेनिंग करें जो सबसे ज़रूरी हैं, और अपने गेम की गलतियाँ सुधारें।';

  @override
  String get puzzlesFromYourGamesTitle => 'आपके गेम से पज़ल';

  @override
  String get solveNowButton => 'अभी हल करें';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count पज़ल बाकी';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'अभी कोई पज़ल नहीं — Pippo के साथ एक गेम पूरा करें, आपकी गलतियाँ पज़ल बन जाएँगी।';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return '$count पज़ल डाउनलोड हुए — ऑफ़लाइन भी उपलब्ध रहेंगे।';
  }

  @override
  String get mixedPuzzlesTitle => 'मिक्स पज़ल';

  @override
  String get mixedPuzzlesSubtitle => 'अलग-अलग थीम के पज़ल खेलें';

  @override
  String get mixedPuzzlesRequiresInternet => 'इंटरनेट कनेक्शन ज़रूरी है';

  @override
  String get downloadingPuzzlesStatus => 'पज़ल डाउनलोड हो रहे हैं...';

  @override
  String get downloadPuzzlesSubtitle =>
      'बिना इंटरनेट हल करने के लिए 10–100 पज़ल सहेजें';

  @override
  String get playDownloadedPuzzlesTitle => 'डाउनलोड किए पज़ल खेलें';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count पज़ल सहेजे गए — ऑफ़लाइन उपलब्ध';
  }

  @override
  String get practiceThemesSection => 'थीम से अभ्यास करें';

  @override
  String get browseAllThemesButton => 'सभी थीम देखें';

  @override
  String get themesRequireInternet => 'थीम के लिए इंटरनेट चाहिए';

  @override
  String get coursesTitle => 'कोर्स';

  @override
  String get coursesTabOpenings => 'ओपनिंग';

  @override
  String get coursesTabMiddlegames => 'मिडिलगेम';

  @override
  String get coursesTabEndgames => 'एंडगेम';

  @override
  String get noCoursesHereYet => 'यहाँ अभी कोई कोर्स नहीं है।';

  @override
  String get tryAgainButton => 'फिर कोशिश करें';

  @override
  String playAsSide(String side) {
    return '$side से खेलें';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count अध्याय';
  }

  @override
  String variationCountLabel(int count) {
    return '$count वैरिएशन';
  }

  @override
  String get courseDetailsTitle => 'कोर्स की जानकारी';

  @override
  String get chaptersTitle => 'अध्याय';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO: $code';
  }

  @override
  String get noChaptersAvailable => 'कोई अध्याय उपलब्ध नहीं है।';

  @override
  String get chapterCompletedBadge => 'पूरा हुआ';

  @override
  String get noVariationsAvailable => 'कोई वैरिएशन उपलब्ध नहीं';

  @override
  String get noVariationsForChapterYet =>
      'इस अध्याय के लिए अभी कोई वैरिएशन नहीं है।';

  @override
  String get learnButton => 'सीखें';

  @override
  String get testButton => 'टेस्ट';

  @override
  String get pricingTitle => 'Pro लें';

  @override
  String get pricingHeroTitle => 'शतरंज की अपनी पूरी\nताकत खोलें।';

  @override
  String get pricingHeroSubtitle =>
      'बेहतर विश्लेषण, असीमित पज़ल और AI कोचिंग पाएँ।';

  @override
  String get pricingFaqHeader => 'अक्सर पूछे जाने वाले सवाल';

  @override
  String get pricingFaqCancelQuestion => 'क्या मैं कभी भी रद्द कर सकता हूँ?';

  @override
  String get pricingFaqCancelAnswer =>
      'हाँ, आप Pro सदस्यता कभी भी रद्द कर सकते हैं। बिलिंग अवधि के अंत तक आपका एक्सेस बना रहेगा।';

  @override
  String get pricingFaqTrialQuestion => 'क्या मुफ़्त ट्रायल है?';

  @override
  String get pricingFaqTrialAnswer =>
      'Pro के साथ 7 दिन का मुफ़्त ट्रायल मिलता है। शुरू करने के लिए क्रेडिट कार्ड नहीं चाहिए।';

  @override
  String get pricingFaqPaymentQuestion =>
      'आप कौन से पेमेंट तरीके स्वीकार करते हैं?';

  @override
  String get pricingFaqPaymentAnswer =>
      'हम सभी बड़े क्रेडिट कार्ड, Apple Pay और Google Pay स्वीकार करते हैं।';

  @override
  String get pricingMostPopularBadge => 'सबसे लोकप्रिय';

  @override
  String get pricingFreeBadge => 'फ़्री';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'फ़्री';

  @override
  String get pricingProPrice => '\$9.99/माह';

  @override
  String get pricingFreePrice => '\$0';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'असीमित इंजन विश्लेषण';

  @override
  String get pricingFeatureDeepClassification => 'गहरी चाल वर्गीकरण';

  @override
  String get pricingFeatureAiReview => 'AI से गेम समीक्षा';

  @override
  String get pricingFeatureOpeningExplorer => 'बेहतर ओपनिंग एक्सप्लोरर';

  @override
  String get pricingFeatureUnlimitedPuzzles => 'असीमित पज़ल सेट';

  @override
  String get pricingFeatureTrainingPlans => 'आपके लिए ट्रेनिंग प्लान';

  @override
  String get pricingFeaturePrioritySupport => 'प्राथमिक सहायता';

  @override
  String get pricingFeatureEarlyAccess => 'नई सुविधाओं तक पहले पहुँच';

  @override
  String get pricingFeatureBasicAnalysis => 'बुनियादी इंजन विश्लेषण';

  @override
  String get pricingFeatureStandardClassification => 'साधारण चाल वर्गीकरण';

  @override
  String get pricingFeatureGameImport => 'Lichess और Chess.com से गेम लाएँ';

  @override
  String get pricingFeatureLimitedPuzzles => 'सीमित पज़ल सेट';

  @override
  String get pricingFeatureCommunityAccess => 'समुदाय तक पहुँच';

  @override
  String get pricingStartTrialButton => 'मुफ़्त ट्रायल शुरू करें';

  @override
  String get pricingCurrentPlanButton => 'मौजूदा प्लान';

  @override
  String get startingEngineStatus => 'इंजन शुरू हो रहा है...';

  @override
  String get downloadPippoPrompt =>
      'ऑफ़लाइन खेलने के लिए Pippo (BaseModel.onnx) डाउनलोड करें।';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received MB / $total MB';
  }

  @override
  String get downloadingStatus => 'डाउनलोड हो रहा है...';

  @override
  String get downloadEngineButton => 'इंजन डाउनलोड करें';

  @override
  String get startChapterButton => 'अध्याय शुरू करें';

  @override
  String get finishChapterButton => 'अध्याय पूरा करें';

  @override
  String get takeTestButton => 'टेस्ट दें';

  @override
  String get exploreBranchesButton => 'वैरिएशन देखें';

  @override
  String get moveToNextVariationButton => 'अगले वैरिएशन पर जाएँ';

  @override
  String get variationsTitle => 'वैरिएशन';

  @override
  String get alternativeBranchesTitle => 'वैकल्पिक शाखाएँ';

  @override
  String get noTheoryAvailable => 'इस वैरिएशन के लिए कोई थ्योरी नहीं है।';

  @override
  String get editBranchExplanationTooltip => 'शाखा की व्याख्या बदलें';

  @override
  String get editExplanationTooltip => 'व्याख्या बदलें';

  @override
  String get editTheoryTooltip => 'थ्योरी बदलें';

  @override
  String branchEditTitle(String name) {
    return 'शाखा: $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'चाल: $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'अध्याय: $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'थ्योरी: $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'फ़्री यूज़र रोज़ एक नया अध्याय खोल सकते हैं।';

  @override
  String playMovePrompt(String move) {
    return '$move चलें';
  }

  @override
  String get opponentThinking => 'मैं सोच रहा हूँ';

  @override
  String opponentPlayedMove(String move) {
    return 'विरोधी ने $move चला';
  }

  @override
  String correctMoveWithName(String move) {
    return 'सही! $move';
  }

  @override
  String get notRightMove => 'यह सही चाल नहीं है';

  @override
  String get variationCompletedMessage => 'वैरिएशन पूरा हुआ!';

  @override
  String get explanationUpdatedMessage =>
      'इस कोर्स को पढ़ने वाले सभी के लिए व्याख्या अपडेट हो गई।';

  @override
  String thinkAboutMovesHint(String piece) {
    return '$piece की चालों के बारे में सोचें...';
  }

  @override
  String get writeHintPlaceholder => 'संकेत लिखें...';

  @override
  String get hintUpdatedMessage =>
      'यह टेस्ट देने वाले सभी के लिए संकेत अपडेट हो गया।';

  @override
  String get masteryTestTitle => 'फ़ाइनल टेस्ट';

  @override
  String get thinkItThrough => 'आराम से सोचें...';

  @override
  String get correctFeedback => 'सही!';

  @override
  String get notQuiteTryAgain => 'लगभग — फिर कोशिश करें';

  @override
  String get opponentThinkingTest => 'विरोधी सोच रहा है...';

  @override
  String get yourMovePlayOpeningLine => 'आपकी चाल — ओपनिंग लाइन चलें';

  @override
  String get editHintTooltip => 'संकेत बदलें';

  @override
  String get variationLabelUpper => 'वैरिएशन';

  @override
  String get overallProgressLabel => 'कुल प्रगति';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total चालें';
  }

  @override
  String get abortButton => 'छोड़ें';

  @override
  String get getHintButton => 'संकेत लें';

  @override
  String get chapterPassedTitle => 'अध्याय पास';

  @override
  String youInternalizedChapter(String chapter) {
    return 'आपने $chapter आत्मसात कर लिया।';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count वैरिएशन पूरे';
  }

  @override
  String get returnToCourseButton => 'कोर्स पर वापस जाएँ';

  @override
  String hintForMoveTitle(String move) {
    return '$move के लिए संकेत';
  }

  @override
  String get dailyPuzzleTitle => 'आज का पज़ल';

  @override
  String get downloadedPuzzlesTitle => 'डाउनलोड किए पज़ल';

  @override
  String get whiteToPlay => 'सफ़ेद की चाल';

  @override
  String get blackToPlay => 'काले की चाल';

  @override
  String hintLookAtPiece(String piece, String square) {
    return '$square पर अपने $piece को देखें';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return '$square पर आपका $piece ही कुंजी है';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return '$square पर बैठे $piece पर ध्यान दें';
  }

  @override
  String themeHintAbout(String theme) {
    return 'यह पज़ल $theme के बारे में है';
  }

  @override
  String themeHintWayOut(String theme) {
    return 'यहाँ $theme ही आपका रास्ता है';
  }

  @override
  String themeHintThinking(String theme) {
    return '$theme के नज़रिए से सोचकर देखें';
  }

  @override
  String get piecePawn => 'प्यादा';

  @override
  String get pieceKnight => 'घोड़ा';

  @override
  String get pieceBishop => 'ऊँट';

  @override
  String get pieceRook => 'हाथी';

  @override
  String get pieceQueen => 'रानी';

  @override
  String get pieceKing => 'राजा';

  @override
  String get pieceGeneric => 'मोहरा';

  @override
  String get mixedTacticsLabel => 'मिली-जुली टैक्टिक्स';

  @override
  String get allDownloadedSolvedMessage =>
      'सभी डाउनलोड किए पज़ल हल हो गए — अगली बार ऑनलाइन आकर और डाउनलोड करें।';

  @override
  String get loadingNextPuzzles => 'और पज़ल लोड हो रहे हैं...';

  @override
  String get noPuzzlesAvailable => 'कोई पज़ल उपलब्ध नहीं है।';

  @override
  String get yourRatingLabel => 'आपकी रेटिंग:';

  @override
  String get hintButton => 'संकेत';

  @override
  String get showThemeButton => 'थीम देखें';

  @override
  String get hintUsedButton => 'संकेत लिया गया';

  @override
  String get doneButton => 'हो गया';

  @override
  String get nextButton => 'अगला';

  @override
  String get retryButton => 'फिर कोशिश करें';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'आपने इस स्थिति में $move चला, जो $classification था। बेहतर चाल खोजने की कोशिश करें।';
  }

  @override
  String get notBestMoveTryAgain =>
      'यहाँ यह सबसे अच्छी चाल नहीं है। फिर कोशिश करें और मज़बूत चाल खोजें।';

  @override
  String get greatJobFoundBestMove => 'शाबाश! आपको सबसे अच्छी चाल मिल गई।';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return '$square पर अपने $piece को देखें। आपको यही मोहरा चलना है।';
  }

  @override
  String get allMyPuzzlesSolvedMessage => 'सभी पज़ल हल हो गए — बहुत बढ़िया!';

  @override
  String get noMyPuzzlesEmptyState =>
      'अभी कोई पज़ल नहीं है।\n\nPippo के साथ एक गेम पूरा करें — आपकी गलतियाँ खुद पज़ल बन जाएँगी।';

  @override
  String puzzleCounterTitle(int current, int total) {
    return '$total में से $currentवाँ पज़ल';
  }

  @override
  String get finishButton => 'समाप्त करें';

  @override
  String get nextPuzzleButton => 'अगला पज़ल';

  @override
  String get allThemesTitle => 'सभी थीम';

  @override
  String get allThemesIntro =>
      'एक ही जगह हर तरह के शतरंज पज़ल का अभ्यास करें। कोई थीम चुनें, अपना स्तर परखें और देखें कि खेल के हर हिस्से में आप कितने अच्छे हैं।';

  @override
  String get themesNeedInternetOffline =>
      'नया पज़ल लाने के लिए थीम को इंटरनेट चाहिए। अभी आपका इंटरनेट बंद है।';

  @override
  String get needsInternetForBatch => 'नया पज़ल लाने के लिए इंटरनेट चाहिए';

  @override
  String get themeGroupMates => 'मेट';

  @override
  String get themeGroupTactics => 'टैक्टिक्स';

  @override
  String get themeGroupKingAttack => 'राजा पर हमला';

  @override
  String get themeGroupEndgames => 'एंडगेम';

  @override
  String get themeGroupPawnsPromotion => 'प्यादे और प्रमोशन';

  @override
  String get themeGroupStrategy => 'रणनीति';

  @override
  String get themeMateIn1 => '1 में मेट';

  @override
  String get themeMateIn1Desc => 'एक ही चाल में चेकमेट खोजें।';

  @override
  String get themeMateIn2 => '2 में मेट';

  @override
  String get themeMateIn2Desc =>
      'स्थिति तैयार करें और अगली चाल में चेकमेट करें।';

  @override
  String get themeMateIn3 => '3 में मेट';

  @override
  String get themeMateIn3Desc =>
      'वह जीतने वाली चालें खोजें जो तीन चालों में मेट दें।';

  @override
  String get themeMateIn4 => '4 में मेट';

  @override
  String get themeMateIn4Desc => 'मेट के लिए कुछ चालें आगे तक सोचें।';

  @override
  String get themeMateIn5 => '5 में मेट';

  @override
  String get themeMateIn5Desc =>
      'एक लंबी मेटिंग चाल जहाँ हर चाल मायने रखती है।';

  @override
  String get themeOtherMates => 'अन्य मेट';

  @override
  String get themeOtherMatesDesc =>
      'खास मेटिंग पैटर्न जैसे बैक रैंक, स्मदर्ड, अनास्तासिया, अरेबियन, बोडन, ओपेरा और भी।';

  @override
  String get themeFork => 'फोर्क';

  @override
  String get themeForkDesc =>
      'एक मोहरा एक साथ दो या ज़्यादा निशानों पर हमला करता है।';

  @override
  String get themePin => 'पिन';

  @override
  String get themePinDesc =>
      'एक मोहरा फँसा है क्योंकि हटने पर कुछ ज़्यादा कीमती खुल जाएगा।';

  @override
  String get themeSkewer => 'स्क्यूअर';

  @override
  String get themeSkewerDesc =>
      'कीमती मोहरे पर हमला करें और पीछे छिपा मोहरा जीतें।';

  @override
  String get themeDiscoveredAttack => 'डिस्कवर्ड अटैक';

  @override
  String get themeDiscoveredAttackDesc => 'एक मोहरा हटाकर दूसरे का हमला खोलें।';

  @override
  String get themeDiscoveredCheck => 'डिस्कवर्ड चेक';

  @override
  String get themeDiscoveredCheckDesc => 'दूसरा मोहरा हटाकर चेक दें।';

  @override
  String get themeDoubleCheck => 'डबल चेक';

  @override
  String get themeDoubleCheckDesc => 'एक साथ दो मोहरों से चेक दें।';

  @override
  String get themeSacrifice => 'बलिदान';

  @override
  String get themeSacrificeDesc => 'बदले में कुछ मज़बूत पाने के लिए मोहरा दें।';

  @override
  String get themeDeflection => 'भटकाव';

  @override
  String get themeDeflectionDesc =>
      'किसी मोहरे को उसकी ज़रूरी जगह से हटने पर मजबूर करें।';

  @override
  String get themeClearance => 'रास्ता खोलना';

  @override
  String get themeClearanceDesc =>
      'दूसरे मोहरे का रास्ता खोलने के लिए एक मोहरा हटाएँ।';

  @override
  String get themeCapturingDefender => 'रक्षक को पकड़ना';

  @override
  String get themeCapturingDefenderDesc =>
      'अहम निशाने की रक्षा करने वाला मोहरा हटाएँ।';

  @override
  String get themeAdvancedTactics => 'कठिन टैक्टिक्स';

  @override
  String get themeAdvancedTacticsDesc =>
      'कई टैक्टिकल आइडिया वाली मुश्किल चालें।';

  @override
  String get themeKingsideAttack => 'किंगसाइड हमला';

  @override
  String get themeKingsideAttackDesc => 'किंगसाइड में राजा पर हमला बनाएँ।';

  @override
  String get themeQueensideAttack => 'क्वीनसाइड हमला';

  @override
  String get themeQueensideAttackDesc =>
      'क्वीनसाइड में दुश्मन राजा के आसपास तोड़ने के रास्ते खोजें।';

  @override
  String get themeExposedKing => 'खुला राजा';

  @override
  String get themeExposedKingDesc =>
      'ऐसे राजा का फ़ायदा उठाएँ जिसकी सुरक्षा छूट गई हो।';

  @override
  String get themeAttackingF2F7 => 'F2 F7 पर हमला';

  @override
  String get themeAttackingF2F7Desc =>
      'राजा के पास कमज़ोर f2 या f7 खाने को निशाना बनाएँ।';

  @override
  String get themeEndgame => 'एंडगेम';

  @override
  String get themeEndgameDesc =>
      'जब कुछ ही मोहरे बचे हों तो सबसे अच्छा खेल खोजें।';

  @override
  String get themeRookEndgame => 'हाथी एंडगेम';

  @override
  String get themeRookEndgameDesc =>
      'एंडगेम में अपने हाथियों का सबसे अच्छा इस्तेमाल सीखें।';

  @override
  String get themeQueenEndgame => 'रानी एंडगेम';

  @override
  String get themeQueenEndgameDesc =>
      'रानी वाली स्थितियों में सही चालें खोजें।';

  @override
  String get themeQueenRookEndgame => 'रानी-हाथी एंडगेम';

  @override
  String get themeQueenRookEndgameDesc => 'रानी और हाथी वाले एंडगेम सँभालें।';

  @override
  String get themeBishopEndgame => 'ऊँट एंडगेम';

  @override
  String get themeBishopEndgameDesc =>
      'जीतने वाला प्लान खोजने के लिए अपने ऊँट और राजा का इस्तेमाल करें।';

  @override
  String get themeKnightEndgame => 'घोड़ा एंडगेम';

  @override
  String get themeKnightEndgameDesc =>
      'घोड़े अहम हों ऐसे एंडगेम में सही चालें खोजें।';

  @override
  String get themePawnEndgame => 'प्यादा एंडगेम';

  @override
  String get themePawnEndgameDesc =>
      'प्यादों की दौड़ गिनें और जीत का रास्ता खोजें।';

  @override
  String get themeZugzwang => 'ज़ुगज़वांग';

  @override
  String get themeZugzwangDesc =>
      'विरोधी को ऐसी स्थिति में डालें जहाँ हर चाल चीज़ें बिगाड़ दे।';

  @override
  String get themeAdvancedPawn => 'बढ़ा हुआ प्यादा';

  @override
  String get themeAdvancedPawnDesc =>
      'दुश्मन के इलाके में घुसे खतरनाक प्यादे का इस्तेमाल करें।';

  @override
  String get themePromotion => 'प्रमोशन';

  @override
  String get themePromotionDesc =>
      'प्यादे को आखिर तक पहुँचाकर मज़बूत मोहरा बनाएँ।';

  @override
  String get themeUnderPromotion => 'अंडर प्रमोशन';

  @override
  String get themeUnderPromotionDesc =>
      'जीतने वाली चाल हो तो रानी के बजाय कुछ और बनाएँ।';

  @override
  String get themeEnPassant => 'एन पासां';

  @override
  String get themeEnPassantDesc =>
      'एन पासां से प्यादा पकड़ने का दुर्लभ मौका पहचानें।';

  @override
  String get themeQuietMove => 'शांत चाल';

  @override
  String get themeQuietMoveDesc =>
      'बिना ज़ोर-ज़बरदस्ती फ़ायदा बनाने वाली शांत चाल खोजें।';

  @override
  String get themeDefensiveMove => 'रक्षात्मक चाल';

  @override
  String get themeDefensiveMoveDesc =>
      'विरोधी के खतरे को रोकने वाली चाल खोजें।';

  @override
  String get themeAdvantage => 'बढ़त';

  @override
  String get themeAdvantageDesc => 'अपनी बढ़त बनाए या बढ़ाने वाली चाल खोजें।';

  @override
  String get themeEquality => 'बराबरी';

  @override
  String get themeEqualityDesc => 'स्थिति बराबर रखने वाली चाल खोजें।';

  @override
  String get themeCrushing => 'करारी चाल';

  @override
  String get themeCrushingDesc =>
      'मज़बूत स्थिति को जीती हुई बनाने वाली दमदार चाल खोजें।';

  @override
  String get pippoThinking2 => 'सबसे अच्छी चाल खोजने दीजिए';

  @override
  String get pippoThinking3 => 'एक पल... कुछ आइडिया दिख रहे हैं';

  @override
  String get pippoThinking4 => 'अपना जवाब गिन रहा हूँ';

  @override
  String get pippoThreatAsk1 => 'समझे इस चाल में क्या खतरा है?';

  @override
  String get pippoThreatAsk2 => 'इस चाल के पीछे मेरा एक छोटा सा आइडिया है...';

  @override
  String get pippoThreatAsk3 => 'सावधान — यह चाल किसी चीज़ पर दबाव डाल रही है।';

  @override
  String get pippoThreatAsk4 =>
      'हो सकता है इस चाल में दिखने से ज़्यादा कुछ हो।';

  @override
  String get pippoGreat1 => 'इस स्थिति की इकलौती चाल खोजने के लिए शाबाश!';

  @override
  String get pippoGreat2 => 'बहुत बढ़िया चाल — खूब पहचानी।';

  @override
  String get pippoGreat3 => 'बेहतरीन खोज। आपने यह स्थिति सुंदरता से सँभाली।';

  @override
  String get pippoBrilliant1 => 'शानदार! यह चाल अद्भुत सटीक थी।';

  @override
  String get pippoBrilliant2 =>
      'क्या शानदार आइडिया — मुझे इसकी उम्मीद नहीं थी।';

  @override
  String get pippoBrilliant3 => 'वह शानदार थी। आपको सच में रचनात्मक चाल मिली।';

  @override
  String get pippoFinished1 => 'क्या बढ़िया गेम था! फिर खेलेंगे?';

  @override
  String get pippoFinished2 => 'बहुत खूब खेले! एक और गेम?';

  @override
  String get pippoFinished3 => 'अच्छा गेम — मुझे मज़ा आया। रीमैच?';

  @override
  String get classificationBookComment => 'ओपनिंग किताब की एक चाल।';

  @override
  String get resignDialogTitle => 'गेम छोड़ दें?';

  @override
  String get resignDialogBody =>
      'क्या आप सच में हार मानना चाहते हैं? इससे मौजूदा गेम खत्म हो जाएगा।';

  @override
  String get resignConfirm => 'हार मानें';

  @override
  String get gameOverResignBlack => 'काला हार मानने से जीता';

  @override
  String get gameOverResignWhite => 'सफ़ेद हार मानने से जीता';

  @override
  String get gameOverDefault => 'गेम खत्म';

  @override
  String get gameOverMateBlack => 'काला चेकमेट से जीता';

  @override
  String get gameOverMateWhite => 'सफ़ेद चेकमेट से जीता';

  @override
  String get gameOverStalemate => 'स्टेलमेट से ड्रॉ';

  @override
  String get gameOverRepetition => 'दोहराव से ड्रॉ';

  @override
  String get gameOverInsufficient => 'कम मोहरों से ड्रॉ';

  @override
  String get gameOverDrawn => 'गेम ड्रॉ';

  @override
  String get playStartFirst => 'पहले एक गेम शुरू करें';

  @override
  String get takebackTrainingOnly => 'चाल वापस लेना सिर्फ़ ट्रेनिंग मोड में है';

  @override
  String get takebackNoMoves => 'वापस लेने के लिए कोई चाल नहीं';

  @override
  String get takebackDone => 'चाल वापस ले ली';

  @override
  String get pippoMissBare => 'इस स्थिति में आपसे बेहतर चाल छूट गई।';

  @override
  String pippoMissWithMove(String move) {
    return 'इस स्थिति में आपसे बेहतर चाल छूट गई, आपको $move चलना चाहिए था।';
  }

  @override
  String get pippoBlunderPause =>
      'वह चाल बड़ी भूल थी। उसे वापस लें, या आगे बढ़ें और मैं खेलता रहूँगा।';

  @override
  String get hintTrainingOnly => 'संकेत सिर्फ़ ट्रेनिंग मोड में हैं';

  @override
  String get hintYourTurnOnly => 'संकेत सिर्फ़ आपकी बारी में हैं';

  @override
  String get hintStillAnalyzing =>
      'अभी विश्लेषण चल रहा है... थोड़ी देर में कोशिश करें';

  @override
  String hintLookForPiece(String piece, String square) {
    return '$square पर अपने $piece से अच्छी चाल खोजें।';
  }

  @override
  String get playToolTakeback => 'चाल वापस लें';

  @override
  String get playToolAskHint => 'Pippo से संकेत माँगें';

  @override
  String get playToolClassifyHeader => 'वर्गीकृत करें';

  @override
  String get classifyYourMoves => 'आपकी चालें';

  @override
  String get classifyPippoMoves => 'Pippo की चालें';

  @override
  String get playingPippoTitle => 'Pippo से खेल रहे हैं';

  @override
  String get resignButton => 'हार मानें';

  @override
  String get playAsHeader => 'किससे खेलें';

  @override
  String get sideRandom => 'कोई भी';

  @override
  String get strengthHeader => 'ताकत';

  @override
  String get optionsHeader => 'विकल्प';

  @override
  String get modeLabel => 'मोड';

  @override
  String get modeChallenge => 'चुनौती';

  @override
  String get modeTraining => 'ट्रेनिंग';

  @override
  String get startGameButton => 'गेम शुरू करें';

  @override
  String get perkFeedback => 'अपनी चालों पर राय पाएँ';

  @override
  String get perkSeeThreats => 'सभी खतरे देखें';

  @override
  String get perkTakeback => 'चाहे जब चाल वापस लें';

  @override
  String get perkBlunderPause => 'बड़ी भूल पर गेम रुक जाता है';

  @override
  String get perkHintsAllowed => 'संकेत मिल सकते हैं';

  @override
  String get perkNoFeedback => 'चालों पर कोई राय नहीं';

  @override
  String get perkHiddenThreats => 'खतरे छिपे रहते हैं';

  @override
  String get perkNoTakebacks => 'चाल वापस नहीं ले सकते';

  @override
  String get perkNoBlunderPause => 'बड़ी भूल के बाद भी गेम चलता रहता है';

  @override
  String get perkNoHints => 'कोई संकेत नहीं';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'खतरे छिपाएँ';

  @override
  String get showThreat => 'खतरा दिखाएँ';

  @override
  String get blunderContinue => 'जारी रखें';

  @override
  String get gameOverFallback => 'गेम खत्म';

  @override
  String get resultHome => 'होम';

  @override
  String get resultNewGame => 'नया गेम';

  @override
  String get resultAnalyzeGame => 'गेम का विश्लेषण करें';

  @override
  String get gameToolsTooltip => 'गेम के औज़ार';

  @override
  String get movesHeader => 'चालें';

  @override
  String moveCountLabel(int count) {
    return '$count चालें';
  }

  @override
  String get movesEmptyPlay => 'खेलते हुए आपकी चालें यहाँ दिखेंगी।';

  @override
  String get puzzleNotBest => 'सबसे अच्छी चाल नहीं है। फिर कोशिश करें!';

  @override
  String get puzzleSessionComplete => 'अभ्यास सत्र पूरा!';

  @override
  String get practiceTitle => 'अभ्यास';

  @override
  String get puzzleEmpty => 'कोई पज़ल उपलब्ध नहीं है।';

  @override
  String puzzleCounter(int current, int total) {
    return 'पज़ल $current/$total';
  }

  @override
  String get puzzleHint => 'संकेत';

  @override
  String get puzzleShowMove => 'चाल दिखाएँ';

  @override
  String get puzzleUsedHint => 'संकेत लिया गया';

  @override
  String get puzzleNext => 'अगला पज़ल';

  @override
  String get analysisTitle => 'विश्लेषण';

  @override
  String get addGameTooltip => 'गेम या स्थिति जोड़ें';

  @override
  String get closeGameButton => 'बंद करें';

  @override
  String get positionLoadedOk => 'स्थिति लोड हो गई';

  @override
  String get gameImportedOk => 'गेम आ गया';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess बनाम $opponent';
  }

  @override
  String get youLabel => 'आप';

  @override
  String explorerGameLoaded(String white, String black) {
    return '$white बनाम $black लोड हुआ';
  }

  @override
  String get reviewNoGame => 'समीक्षा के लिए कोई गेम नहीं';

  @override
  String get reviewQuotaUsed => 'आज की गेम समीक्षाएँ खत्म। और के लिए Pro लें।';

  @override
  String get analysisNoMoves => 'विश्लेषण के लिए कोई चाल नहीं';

  @override
  String get settingsEngineHeader => 'इंजन';

  @override
  String get settingsEnableEngine => 'इंजन चालू करें';

  @override
  String get settingsDepth => 'गहराई';

  @override
  String get settingsClassificationHeader => 'चाल वर्गीकरण';

  @override
  String get settingsEnableClassification => 'वर्गीकरण चालू करें';

  @override
  String get settingsThreatHeader => 'खतरा पकड़ने वाला';

  @override
  String get settingsThreatToggle => 'खतरा पकड़ने वाला';

  @override
  String get settingsLinesLabel => 'लाइनों की संख्या';

  @override
  String get filterBook => 'किताब';

  @override
  String get filterBrilliant => 'शानदार';

  @override
  String get filterBlunder => 'बड़ी भूल';

  @override
  String get showLess => 'कम दिखाएँ';

  @override
  String get showAll => 'सभी दिखाएँ';

  @override
  String get analyzingBanner =>
      'आपका गेम विश्लेषण हो रहा है, आप यह स्क्रीन छोड़ सकते हैं';

  @override
  String get fullViewTooltip => 'पूरा दृश्य';

  @override
  String get compactViewTooltip => 'छोटा दृश्य';

  @override
  String get classifyingMove => 'चाल वर्गीकृत हो रही है...';

  @override
  String get phraseBest => 'सबसे अच्छी चाल';

  @override
  String get phraseBrilliant => 'शानदार चाल';

  @override
  String get phraseGreat => 'बहुत बढ़िया चाल';

  @override
  String get phraseExcellent => 'बेहतरीन चाल';

  @override
  String get phraseGood => 'अच्छी चाल';

  @override
  String get phraseInaccuracy => 'एक चूक';

  @override
  String get phraseMistake => 'एक गलती';

  @override
  String get phraseBlunder => 'एक बड़ी भूल';

  @override
  String get phraseMiss => 'एक छूटा मौका';

  @override
  String get phraseBook => 'किताबी चाल';

  @override
  String get phraseForced => 'मजबूरी की चाल';

  @override
  String sentenceBestSuffix(String move) {
    return ', $move सबसे अच्छी चाल थी';
  }

  @override
  String get retryReview => 'समीक्षा फिर करें';

  @override
  String get reviewWaiting => 'आपके गेम की समीक्षा हो रही है';

  @override
  String get pgnEmpty => 'अभी कोई चाल नहीं';

  @override
  String get pgnResume => 'वापस जाएँ';

  @override
  String get showBestTooltip => 'सबसे अच्छी चाल दिखाएँ';

  @override
  String get tabMoves => 'चालें';

  @override
  String get tabExplorer => 'एक्सप्लोरर';

  @override
  String get moveTreeHeader => 'चालों का पेड़';

  @override
  String get moveTreeEmpty => 'आपकी चालें और वैरिएशन यहाँ दिखेंगे।';

  @override
  String get gameReportButton => 'गेम रिपोर्ट';

  @override
  String get gameAnalysisTitle => 'गेम विश्लेषण';

  @override
  String get analyzeButton => 'विश्लेषण करें';

  @override
  String get viewReportTooltip => 'रिपोर्ट देखें';

  @override
  String get noReportYet => 'अभी कोई रिपोर्ट नहीं बनी';

  @override
  String get addToAnalysisTitle => 'विश्लेषण में जोड़ें';

  @override
  String get addToAnalysisSubtitle =>
      'किसी गेम, स्थिति या खाली बोर्ड से शुरू करें।';

  @override
  String get importSegment => 'लाएँ';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'बिछाएँ';

  @override
  String get gameReportTitle => 'गेम रिपोर्ट';

  @override
  String get accuraciesHeader => 'सटीकता';

  @override
  String get accuracyRerunHint =>
      'सटीकता गिनने के लिए पूरा विश्लेषण फिर चलाएँ।';

  @override
  String get pastePgnTooltip => 'PGN चिपकाएँ';

  @override
  String get pastePgnButton => 'कॉपी किया PGN चिपकाएँ';

  @override
  String get searchingLabel => 'खोज रहे हैं...';

  @override
  String get importingLabel => 'ला रहे हैं...';

  @override
  String get searchGamesButton => 'गेम खोजें';

  @override
  String get startAnalysisButton => 'विश्लेषण शुरू करें';

  @override
  String get fenFieldLabel => 'बोर्ड स्थिति (FEN)';

  @override
  String get pasteFenTooltip => 'FEN चिपकाएँ';

  @override
  String get pasteFenButton => 'कॉपी किया FEN चिपकाएँ';

  @override
  String get loadPositionButton => 'स्थिति लोड करें';

  @override
  String get inputPgnText => 'PGN टेक्स्ट';

  @override
  String get inputUsername => 'यूज़रनेम';

  @override
  String get inputGameUrl => 'गेम का लिंक';

  @override
  String get hintPastePgn => 'PGN यहाँ चिपकाएँ...';

  @override
  String get hintEnterUsername => 'यूज़रनेम लिखें...';

  @override
  String get dialogOk => 'ठीक है';

  @override
  String get lichessSignInCancelled => 'Lichess साइन-इन रद्द';

  @override
  String get boardSetupTitle => 'बोर्ड बिछाएँ';

  @override
  String get flipBoardTooltip => 'बोर्ड पलटें';

  @override
  String get clearBoardButton => 'बोर्ड साफ़ करें';

  @override
  String get startPositionButton => 'शुरुआती स्थिति';

  @override
  String get whoMovesHeader => 'पहले कौन चलेगा';

  @override
  String get piecesHeader => 'मोहरे';

  @override
  String get setupInstructions =>
      'किसी मोहरे को चुनने के लिए उसे छुएँ, फिर बोर्ड पर छूकर रखें। जोड़ने के लिए मोहरे को बोर्ड पर घसीटें, हटाने के लिए बोर्ड से बाहर घसीटें।';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'समाप्त करें';

  @override
  String engineDepthLabel(int depth) {
    return 'गहराई $depth';
  }

  @override
  String get analyzeGameTitle => 'गेम का विश्लेषण करें';

  @override
  String get reviewsUnlimited => 'आज असीमित गेम समीक्षाएँ';

  @override
  String reviewsLeftToday(int done, int total) {
    return 'आज $done/$total गेम समीक्षाएँ बाकी';
  }

  @override
  String get analyzeTypeHeader => 'प्रकार';

  @override
  String get analyzeModeAnalysis => 'विश्लेषण';

  @override
  String get analyzeModeAnalysisDesc =>
      'Stockfish से आपके गेम की सभी चालें वर्गीकृत करता है';

  @override
  String get analyzeModeReview => 'समीक्षा';

  @override
  String get upgradeToProTitle => 'Pro में अपग्रेड करें';

  @override
  String get reviewModeDesc => 'आपके गेम की चाल-दर-चाल व्याख्या';

  @override
  String get reviewLockedDesc => 'रोज़ और गेम समीक्षाएँ खोलें';

  @override
  String get engineDepthHeader => 'इंजन की गहराई';

  @override
  String depthValueLabel(int depth) {
    return 'गहराई $depth';
  }

  @override
  String get depthHint =>
      'ज़्यादा गहराई में विश्लेषण में ज़्यादा समय लग सकता है';

  @override
  String get selectGameTitle => 'एक गेम चुनें';

  @override
  String get versusShort => 'बनाम';

  @override
  String get speedBullet => 'बुलेट';

  @override
  String get speedBlitz => 'ब्लिट्ज़';

  @override
  String get speedRapid => 'रैपिड';

  @override
  String get speedClassical => 'क्लासिकल';

  @override
  String get openingExplorerTitle => 'ओपनिंग एक्सप्लोरर';

  @override
  String get dbMasters => 'मास्टर्स';

  @override
  String get filtersHeader => 'फ़िल्टर';

  @override
  String get theoreticalMoves => 'थ्योरी की चालें';

  @override
  String get topMasterGames => 'मास्टर्स के बेहतरीन गेम';

  @override
  String get recentGames => 'हाल के गेम';

  @override
  String get explorerSignInDesc =>
      'लाखों गेम, मास्टर्स के गेम और ओपनिंग आँकड़े देखने के लिए Lichess से साइन इन करें।';

  @override
  String get signInWithLichess => 'Lichess से साइन इन करें';

  @override
  String get noOpeningData => 'ओपनिंग का कोई डेटा नहीं';

  @override
  String gamesCountLabel(int count) {
    return '$count गेम';
  }

  @override
  String get unknownPlayer => 'अज्ञात';

  @override
  String get monthJanuary => 'जनवरी';

  @override
  String get monthFebruary => 'फ़रवरी';

  @override
  String get monthMarch => 'मार्च';

  @override
  String get monthApril => 'अप्रैल';

  @override
  String get monthMay => 'मई';

  @override
  String get monthJune => 'जून';

  @override
  String get monthJuly => 'जुलाई';

  @override
  String get monthAugust => 'अगस्त';

  @override
  String get monthSeptember => 'सितंबर';

  @override
  String get monthOctober => 'अक्टूबर';

  @override
  String get monthNovember => 'नवंबर';

  @override
  String get monthDecember => 'दिसंबर';

  @override
  String get indicatorGreen => 'हरा';

  @override
  String get indicatorAmber => 'पीला';

  @override
  String get indicatorRed => 'लाल';

  @override
  String get clsBest => 'सबसे अच्छी';

  @override
  String get clsBrilliant => 'शानदार';

  @override
  String get clsGreat => 'बहुत बढ़िया';

  @override
  String get clsExcellent => 'बेहतरीन';

  @override
  String get clsGood => 'अच्छी';

  @override
  String get clsInaccuracy => 'चूक';

  @override
  String get clsMistake => 'गलती';

  @override
  String get clsBlunder => 'बड़ी भूल';

  @override
  String get clsBook => 'किताबी';

  @override
  String get clsForced => 'मजबूरी की';

  @override
  String get clsMiss => 'छूटा मौका';

  @override
  String averageRatingLabel(int rating) {
    return 'औसत $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move $label है';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move सबसे अच्छी चाल थी।';
  }
}
