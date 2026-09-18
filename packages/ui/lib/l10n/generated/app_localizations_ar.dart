// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'لاعب';

  @override
  String get notSignedIn => 'لم يتم تسجيل الدخول';

  @override
  String get planAdmin => 'مشرف';

  @override
  String get planPro => 'عضو PRO';

  @override
  String get planFree => 'عضو مجاني';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appSettingsSection => 'إعدادات التطبيق';

  @override
  String get supportSection => 'الدعم';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get appearanceSubtitle => 'فاتح أو داكن أو حسب النظام';

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get subscriptionSubtitle => 'إدارة خطة Atlas Pro';

  @override
  String get languageTitle => 'اللغة';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'المساعدة والدعم';

  @override
  String get helpSubtitle => 'الأسئلة الشائعة وخدمة العملاء';

  @override
  String get contactSupportTitle => 'تواصل مع الدعم';

  @override
  String get contactSupportSubtitle => 'تواصل مع فريق الدعم';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get chooseTheme => 'اختر المظهر';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get systemDefault => 'حسب النظام';

  @override
  String get editDisplayName => 'تعديل الاسم الظاهر';

  @override
  String displayNameRule(int maxLength) {
    return 'اختر اسمًا لا يتجاوز $maxLength أحرف.';
  }

  @override
  String get displayNameLabel => 'الاسم الظاهر';

  @override
  String get save => 'حفظ';

  @override
  String get languageSheetTitle => 'اختر اللغة';

  @override
  String get systemLanguage => 'حسب النظام';

  @override
  String get supportTypeLabel => 'نوع المشكلة';

  @override
  String get supportTypeHint => 'اختر الخيار الأقرب لوصف مشكلتك.';

  @override
  String get supportTypeUi => 'واجهة المستخدم';

  @override
  String get supportTypeError => 'خطأ';

  @override
  String get supportTypeOther => 'أخرى';

  @override
  String get supportSubjectLabel => 'الموضوع';

  @override
  String get supportSubjectHint => 'وصف موجز لمشكلتك';

  @override
  String get supportMessageLabel => 'الرسالة';

  @override
  String get supportMessageHint => 'يرجى وصف مشكلتك بالتفصيل...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max حرفًا';
  }

  @override
  String get supportSubmitButton => 'إرسال التذكرة';

  @override
  String get supportSuccessTitle => 'تم إرسال التذكرة!';

  @override
  String get supportSuccessBody => 'سنرد على بريدك الإلكتروني خلال 24-48 ساعة.';

  @override
  String get supportSuccessDone => 'تم';

  @override
  String get supportSignInTitle => 'سجّل الدخول للتواصل مع الدعم';

  @override
  String get supportSignInBody =>
      'ترتبط التذاكر بحسابك حتى نتمكن من الرد عليك. سجّل الدخول ثم أعد المحاولة.';

  @override
  String get supportOfflineNotice =>
      'أنت غير متصل بالإنترنت. أعد الاتصال لإرسال تذكرتك.';

  @override
  String get supportErrTypeRequired => 'اختر نوع المشكلة.';

  @override
  String get supportErrSubjectRequired => 'أدخل موضوعًا.';

  @override
  String get supportErrMessageRequired => 'أدخل رسالة.';

  @override
  String get supportErrSubjectTooLong => 'الموضوع طويل جدًا.';

  @override
  String get supportErrMessageTooLong => 'الرسالة طويلة جدًا.';

  @override
  String get supportErrGeneric => 'تعذّر إرسال تذكرتك. حاول مرة أخرى.';

  @override
  String get offlineBannerTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get boardSettingsTitle => 'إعدادات الرقعة';

  @override
  String get pieceSetLabel => 'طقم القطع';

  @override
  String get boardThemeLabel => 'مظهر الرقعة';

  @override
  String get moveIndicatorLabel => 'مؤشر النقلات';

  @override
  String get showCoordinatesLabel => 'إظهار الإحداثيات';

  @override
  String get dragAndDropLabel => 'السحب والإفلات';

  @override
  String get soundLabel => 'الصوت';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get editExplanationTitle => 'تعديل الشرح';

  @override
  String get writeExplanationHint => 'اكتب الشرح...';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get boardThemeEmerald => 'زمردي';

  @override
  String get boardThemeMidnight => 'منتصف الليل';

  @override
  String get boardThemePurple => 'بنفسجي';

  @override
  String get boardThemeSand => 'رملي';

  @override
  String get boardThemeBlue => 'أزرق';

  @override
  String get boardThemeBrown => 'بني';

  @override
  String get quotaUpgradeCta => 'قم بالترقية إلى Pro لحل ألغاز غير محدودة';

  @override
  String get downloadButton => 'تنزيل';

  @override
  String get upgradeNow => 'الترقية الآن';

  @override
  String get offlineDownloadsProNotice =>
      'تنزيل الألغاز دون اتصال متاح مع Pro. قم بالترقية لحفظ الألغاز على هذا الجهاز.';

  @override
  String get savedForOffline => 'محفوظ على هذا الجهاز للحل دون اتصال';

  @override
  String get downloadPuzzlesTitle => 'تنزيل الألغاز';

  @override
  String get puzzleDecksTitle => 'مجموعات الألغاز';

  @override
  String get deckRecentMistakes => 'الأخطاء الأخيرة';

  @override
  String get deckRecentMistakesSubtitle => 'تكتيكات من مبارياتك الخاسرة';

  @override
  String get deckMatingPatterns => 'أنماط الإماتة';

  @override
  String get deckMatingPatternsSubtitle => 'أتقن إماتات نهاية اللعب';

  @override
  String get deckOpeningTraps => 'مصائد الافتتاح';

  @override
  String get deckOpeningTrapsSubtitle => 'الحيل الشائعة في افتتاحياتك';

  @override
  String get deckDailyChallenges => 'التحديات اليومية';

  @override
  String get deckDailyChallengesSubtitle => 'ألغاز جديدة كل يوم';

  @override
  String selectedPuzzleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغز',
      many: '$count لغزًا',
      few: '$count ألغاز',
      two: 'لغزان',
      one: 'لغز واحد',
      zero: 'لا ألغاز',
    );
    return '$_temp0';
  }

  @override
  String get getStartedTitle => 'ابدأ الآن';

  @override
  String get welcomeTagline =>
      'تحسّن في الشطرنج بسرعة مع بيبو، مدرّبك الشخصي لتتعلّم وتتطوّر وتفوز بمزيد من المباريات.';

  @override
  String get signInOrSignUpSubtitle =>
      'سجّل الدخول أو أنشئ حسابًا لحفظ تقدّمك.';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get continueAsGuest => 'المتابعة كزائر';

  @override
  String get errGoogleSignIn => 'تعذّر إكمال تسجيل الدخول عبر Google.';

  @override
  String get signInTab => 'تسجيل الدخول';

  @override
  String get signUpTab => 'إنشاء حساب';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get orLabel => 'أو';

  @override
  String get registerButton => 'تسجيل';

  @override
  String get welcomeBackTitle => 'أهلًا بعودتك';

  @override
  String get signInSubtitle =>
      'سجّل الدخول إلى حسابك وواصل التقدّم في التصنيف.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get signUpSubtitle => 'انضم إلى آلاف اللاعبين وطوّر مستواك.';

  @override
  String get firstNameLabel => 'الاسم الأول';

  @override
  String get firstNameHint => 'أحمد';

  @override
  String get lastNameLabel => 'اسم العائلة';

  @override
  String get lastNameHint => 'محمد';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور.';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get enterResetCodeTitle => 'أدخل رمز الاستعادة';

  @override
  String get resetIntro => 'أدخل بريد حسابك وسنرسل لك رمز الاستعادة.';

  @override
  String resetCodeSentIntro(String email) {
    return 'أرسلنا رمز استعادة إلى $email. أدخله أدناه مع كلمة المرور الجديدة.';
  }

  @override
  String get recoveryCodeLabel => 'رمز الاستعادة';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get sendRecoveryCode => 'إرسال رمز الاستعادة';

  @override
  String get errEnterValidEmail => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get errEnterCodeFromEmail => 'أدخل الرمز المرسل إلى بريدك.';

  @override
  String get errPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get namePromptTitle => 'بماذا نناديك؟';

  @override
  String get namePromptSubtitle => 'اختر اسمًا لملفك الشخصي حتى نخصّص تجربتك.';

  @override
  String get yourNameHint => 'اسمك';

  @override
  String get verifyEmailTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get enterVerificationCodeTitle => 'أدخل رمز التحقق';

  @override
  String get otpSentPrefix => 'أرسلنا رمزًا مكوّنًا من 8 أرقام إلى\n';

  @override
  String get otpSentSuffix =>
      '. يرجى التحقق من صندوق الوارد أو مجلد الرسائل غير المرغوب فيها.';

  @override
  String get verifyCodeButton => 'تأكيد الرمز';

  @override
  String get didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String resendInSeconds(int seconds) {
    return 'إعادة الإرسال بعد $seconds ثانية';
  }

  @override
  String get verificationCodeResent => 'تمت إعادة إرسال رمز التحقق';

  @override
  String helloGreeting(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get homeSubtitle => 'هل أنت مستعد لتعلّم شيء جديد اليوم؟';

  @override
  String get coursesSection => 'الدورات';

  @override
  String get dailyPracticeSection => 'التدريب اليومي';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get gamesVsPippo => 'مباريات ضد بيبو';

  @override
  String get puzzleRatingLabel => 'تصنيف الألغاز';

  @override
  String get dailyStreakLabel => 'التتابع اليومي';

  @override
  String get chaptersDoneLabel => 'الفصول المكتملة';

  @override
  String get tacticsTrainingTitle => 'تدريب التكتيك';

  @override
  String get tacticsTrainingSubtitle => 'حل الألغاز وطوّر مستواك';

  @override
  String get dailyPuzzleLabel => 'لغز اليوم';

  @override
  String get playNow => 'العب الآن';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCourses => 'الدورات';

  @override
  String get navPuzzles => 'الألغاز';

  @override
  String get navAnalysis => 'التحليل';

  @override
  String get navMenu => 'القائمة';

  @override
  String get planBadgeAdmin => 'مشرف';

  @override
  String get planBadgeFree => 'مجاني';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return 'خطة $tier';
  }

  @override
  String get coursesComingSoon => 'الدورات قريبًا';

  @override
  String get continueLearning => 'متابعة التعلّم';

  @override
  String get continueLearningButton => 'متابعة التعلّم';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total تنويع مكتمل',
      many: '$completed/$total تنويعًا مكتملًا',
      few: '$completed/$total تنويعات مكتملة',
      two: '$completed/$total تنويعان مكتملان',
      one: '$completed/$total تنويع مكتمل',
      zero: '$completed/$total تنويع مكتمل',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'الأبيض';

  @override
  String get sideBlack => 'الأسود';

  @override
  String get sideWhiteInitial => 'W';

  @override
  String get sideBlackInitial => 'B';

  @override
  String courseMetaChip(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $count فصل',
      many: '$side · $count فصلًا',
      few: '$side · $count فصول',
      two: '$side · فصلان',
      one: '$side · فصل واحد',
      zero: '$side · بدون فصول',
    );
    return '$_temp0';
  }

  @override
  String get puzzlesTitle => 'ألغاز';

  @override
  String get puzzlesIntroTitle => 'صقل تكتيكك';

  @override
  String get puzzlesIntroSubtitle =>
      'تدرّب على أهم المواضيع وأصلح أخطاء مبارياتك.';

  @override
  String get puzzlesFromYourGamesTitle => 'ألغاز من مبارياتك';

  @override
  String get solveNowButton => 'حل الآن';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count ألغاز متبقية';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'لا ألغاز بعد — أنهِ مباراة ضد بيبو وستتحول أخطاؤك إلى ألغاز.';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return 'تم تنزيل $count ألغاز — متوفرة حتى دون اتصال.';
  }

  @override
  String get mixedPuzzlesTitle => 'ألغاز منوعة';

  @override
  String get mixedPuzzlesSubtitle => 'العب ألغازًا من مواضيع مختلفة';

  @override
  String get mixedPuzzlesRequiresInternet => 'يحتاج اتصالًا بالإنترنت';

  @override
  String get downloadingPuzzlesStatus => 'جارٍ تنزيل الألغاز...';

  @override
  String get downloadPuzzlesSubtitle =>
      'احفظ من 10 إلى 100 لغز للحل دون إنترنت';

  @override
  String get playDownloadedPuzzlesTitle => 'العب الألغاز المنزلة';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count ألغاز محفوظة — متوفرة دون اتصال';
  }

  @override
  String get practiceThemesSection => 'تدرّب حسب المواضيع';

  @override
  String get browseAllThemesButton => 'عرض كل المواضيع';

  @override
  String get themesRequireInternet => 'المواضيع تحتاج الإنترنت';

  @override
  String get coursesTitle => 'الدورات';

  @override
  String get coursesTabOpenings => 'الافتتاحيات';

  @override
  String get coursesTabMiddlegames => 'وسط اللعب';

  @override
  String get coursesTabEndgames => 'نهايات اللعب';

  @override
  String get noCoursesHereYet => 'لا دورات هنا بعد.';

  @override
  String get tryAgainButton => 'حاول مجددًا';

  @override
  String playAsSide(String side) {
    return 'العب بـ$side';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count فصول';
  }

  @override
  String variationCountLabel(int count) {
    return '$count تنويعات';
  }

  @override
  String get courseDetailsTitle => 'تفاصيل الدورة';

  @override
  String get chaptersTitle => 'الفصول';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO: $code';
  }

  @override
  String get noChaptersAvailable => 'لا فصول متوفرة.';

  @override
  String get chapterCompletedBadge => 'مكتمل';

  @override
  String get noVariationsAvailable => 'لا تنويعات متوفرة';

  @override
  String get noVariationsForChapterYet => 'لا تنويعات لهذا الفصل بعد.';

  @override
  String get learnButton => 'تعلّم';

  @override
  String get testButton => 'اختبر';

  @override
  String get pricingTitle => 'اشترك في Pro';

  @override
  String get pricingHeroTitle => 'أطلق كامل\nإمكاناتك في الشطرنج.';

  @override
  String get pricingHeroSubtitle =>
      'تحليل متقدم وألغاز غير محدودة وتدريب بالذكاء الاصطناعي.';

  @override
  String get pricingFaqHeader => 'أسئلة شائعة';

  @override
  String get pricingFaqCancelQuestion => 'هل يمكنني الإلغاء في أي وقت؟';

  @override
  String get pricingFaqCancelAnswer =>
      'نعم، يمكنك إلغاء اشتراك Pro في أي وقت. وستحتفظ بالوصول حتى نهاية فترة الدفع.';

  @override
  String get pricingFaqTrialQuestion => 'هل توجد تجربة مجانية؟';

  @override
  String get pricingFaqTrialAnswer =>
      'يأتي Pro مع تجربة مجانية لمدة 7 أيام. لا حاجة لبطاقة ائتمان للبدء.';

  @override
  String get pricingFaqPaymentQuestion => 'ما طرق الدفع التي تقبلونها؟';

  @override
  String get pricingFaqPaymentAnswer =>
      'نقبل جميع بطاقات الائتمان الرئيسية وApple Pay وGoogle Pay.';

  @override
  String get pricingMostPopularBadge => 'الأكثر شعبية';

  @override
  String get pricingFreeBadge => 'مجاني';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'مجاني';

  @override
  String get pricingProPrice => '\$9.99/شهريًا';

  @override
  String get pricingFreePrice => '\$0';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'تحليل غير محدود بالمحرك';

  @override
  String get pricingFeatureDeepClassification => 'تصنيف عميق للنقلات';

  @override
  String get pricingFeatureAiReview => 'مراجعة المباريات بالذكاء الاصطناعي';

  @override
  String get pricingFeatureOpeningExplorer => 'مستكشف افتتاحيات متقدم';

  @override
  String get pricingFeatureUnlimitedPuzzles => 'مجموعات ألغاز غير محدودة';

  @override
  String get pricingFeatureTrainingPlans => 'خطط تدريب لك';

  @override
  String get pricingFeaturePrioritySupport => 'دعم ذو أولوية';

  @override
  String get pricingFeatureEarlyAccess => 'وصول مبكر للميزات الجديدة';

  @override
  String get pricingFeatureBasicAnalysis => 'تحليل أساسي بالمحرك';

  @override
  String get pricingFeatureStandardClassification => 'تصنيف عادي للنقلات';

  @override
  String get pricingFeatureGameImport =>
      'استيراد المباريات من Lichess وChess.com';

  @override
  String get pricingFeatureLimitedPuzzles => 'مجموعات ألغاز محدودة';

  @override
  String get pricingFeatureCommunityAccess => 'الوصول إلى المجتمع';

  @override
  String get pricingStartTrialButton => 'ابدأ التجربة المجانية';

  @override
  String get pricingCurrentPlanButton => 'الخطة الحالية';

  @override
  String get startingEngineStatus => 'جارٍ تشغيل المحرك...';

  @override
  String get downloadPippoPrompt =>
      'نزّل بيبو (BaseModel.onnx) للعب دون اتصال.';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received م.ب / $total م.ب';
  }

  @override
  String get downloadingStatus => 'جارٍ التنزيل...';

  @override
  String get downloadEngineButton => 'تنزيل المحرك';

  @override
  String get startChapterButton => 'ابدأ الفصل';

  @override
  String get finishChapterButton => 'أنهِ الفصل';

  @override
  String get takeTestButton => 'ابدأ الاختبار';

  @override
  String get exploreBranchesButton => 'استكشف التنويعات';

  @override
  String get moveToNextVariationButton => 'انتقل إلى التنويع التالي';

  @override
  String get variationsTitle => 'التنويعات';

  @override
  String get alternativeBranchesTitle => 'الفروع البديلة';

  @override
  String get noTheoryAvailable => 'لا نظرية لهذا التنويع.';

  @override
  String get editBranchExplanationTooltip => 'تعديل شرح الفرع';

  @override
  String get editExplanationTooltip => 'تعديل الشرح';

  @override
  String get editTheoryTooltip => 'تعديل النظرية';

  @override
  String branchEditTitle(String name) {
    return 'الفرع: $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'النقلة: $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'الفصل: $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'النظرية: $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'يمكن للمستخدمين المجانيين فتح فصل جديد واحد يوميًا.';

  @override
  String playMovePrompt(String move) {
    return 'العب $move';
  }

  @override
  String get opponentThinking => 'أنا أفكر';

  @override
  String opponentPlayedMove(String move) {
    return 'لعب الخصم $move';
  }

  @override
  String correctMoveWithName(String move) {
    return 'صحيح! $move';
  }

  @override
  String get notRightMove => 'هذه ليست النقلة الصحيحة';

  @override
  String get variationCompletedMessage => 'اكتمل التنويع!';

  @override
  String get explanationUpdatedMessage =>
      'تم تحديث الشرح للجميع ممن يدرسون هذه الدورة.';

  @override
  String thinkAboutMovesHint(String piece) {
    return 'فكّر في نقلات $piece...';
  }

  @override
  String get writeHintPlaceholder => 'اكتب التلميح...';

  @override
  String get hintUpdatedMessage =>
      'تم تحديث التلميح للجميع ممن يختبرون هذا الفصل.';

  @override
  String get masteryTestTitle => 'الاختبار النهائي';

  @override
  String get thinkItThrough => 'فكّر بهدوء...';

  @override
  String get correctFeedback => 'صحيح!';

  @override
  String get notQuiteTryAgain => 'قريب — حاول مجددًا';

  @override
  String get opponentThinkingTest => 'الخصم يفكر...';

  @override
  String get yourMovePlayOpeningLine => 'دورك — العب سطر الافتتاح';

  @override
  String get editHintTooltip => 'تعديل التلميح';

  @override
  String get variationLabelUpper => 'التنويع';

  @override
  String get overallProgressLabel => 'التقدم الكلي';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total نقلات';
  }

  @override
  String get abortButton => 'إيقاف';

  @override
  String get getHintButton => 'اطلب تلميحًا';

  @override
  String get chapterPassedTitle => 'تم اجتياز الفصل';

  @override
  String youInternalizedChapter(String chapter) {
    return 'لقد أتقنت $chapter.';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count تنويعات مكتملة';
  }

  @override
  String get returnToCourseButton => 'عودة إلى الدورة';

  @override
  String hintForMoveTitle(String move) {
    return 'تلميح لـ$move';
  }

  @override
  String get dailyPuzzleTitle => 'لغز اليوم';

  @override
  String get downloadedPuzzlesTitle => 'الألغاز المنزلة';

  @override
  String get whiteToPlay => 'الأبيض ليلعب';

  @override
  String get blackToPlay => 'الأسود ليلعب';

  @override
  String hintLookAtPiece(String piece, String square) {
    return 'انظر إلى $piece على $square';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return '$piece على $square هي المفتاح';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return 'ركّز على $piece الموجودة على $square';
  }

  @override
  String themeHintAbout(String theme) {
    return 'هذا اللغز عن $theme';
  }

  @override
  String themeHintWayOut(String theme) {
    return '$theme هو مخرجك هنا';
  }

  @override
  String themeHintThinking(String theme) {
    return 'حاول التفكير من زاوية $theme';
  }

  @override
  String get piecePawn => 'بيدق';

  @override
  String get pieceKnight => 'حصان';

  @override
  String get pieceBishop => 'فيل';

  @override
  String get pieceRook => 'قلعة';

  @override
  String get pieceQueen => 'ملكة';

  @override
  String get pieceKing => 'ملك';

  @override
  String get pieceGeneric => 'قطعة';

  @override
  String get mixedTacticsLabel => 'تكتيك منوع';

  @override
  String get allDownloadedSolvedMessage =>
      'حللت كل الألغاز المنزلة — نزّل المزيد عندما تكون متصلًا.';

  @override
  String get loadingNextPuzzles => 'جارٍ تحميل المزيد من الألغاز...';

  @override
  String get noPuzzlesAvailable => 'لا ألغاز متوفرة.';

  @override
  String get yourRatingLabel => 'تصنيفك:';

  @override
  String get hintButton => 'تلميح';

  @override
  String get showThemeButton => 'عرض الموضوع';

  @override
  String get hintUsedButton => 'تم استخدام التلميح';

  @override
  String get doneButton => 'تم';

  @override
  String get nextButton => 'التالي';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'لعبت $move في هذا الموقف، وكانت $classification. حاول إيجاد نقلة أفضل.';
  }

  @override
  String get notBestMoveTryAgain =>
      'ليست أفضل نقلة هنا. حاول مجددًا وابحث عن تكملة أقوى.';

  @override
  String get greatJobFoundBestMove => 'أحسنت! وجدت أفضل نقلة.';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return 'انظر إلى $piece على $square. هذه هي القطعة التي يجب تحريكها.';
  }

  @override
  String get allMyPuzzlesSolvedMessage => 'حللت كل الألغاز — عمل رائع!';

  @override
  String get noMyPuzzlesEmptyState =>
      'لا ألغاز بعد.\n\nأنهِ مباراة ضد بيبو — ستتحول أخطاؤك إلى ألغاز تلقائيًا.';

  @override
  String puzzleCounterTitle(int current, int total) {
    return 'اللغز $current من $total';
  }

  @override
  String get finishButton => 'إنهاء';

  @override
  String get nextPuzzleButton => 'اللغز التالي';

  @override
  String get allThemesTitle => 'كل المواضيع';

  @override
  String get allThemesIntro =>
      'تدرّب على كل أنواع ألغاز الشطرنج في مكان واحد. اختر موضوعًا واختبر مستواك وشاهد أداءك في كل جزء من اللعب.';

  @override
  String get themesNeedInternetOffline =>
      'تحتاج المواضيع إلى الإنترنت لتحميل دفعة جديدة. أنت دون اتصال الآن.';

  @override
  String get needsInternetForBatch => 'يحتاج الإنترنت لتحميل دفعة جديدة';

  @override
  String get themeGroupMates => 'الإماتات';

  @override
  String get themeGroupTactics => 'التكتيك';

  @override
  String get themeGroupKingAttack => 'الهجوم على الملك';

  @override
  String get themeGroupEndgames => 'نهايات اللعب';

  @override
  String get themeGroupPawnsPromotion => 'البيادق والترقية';

  @override
  String get themeGroupStrategy => 'الاستراتيجية';

  @override
  String get themeMateIn1 => 'مات في 1';

  @override
  String get themeMateIn1Desc => 'جد الإماتة في نقلة واحدة.';

  @override
  String get themeMateIn2 => 'مات في 2';

  @override
  String get themeMateIn2Desc => 'جهّز الموقف وأنهِ بالإماتة في نقلتك التالية.';

  @override
  String get themeMateIn3 => 'مات في 3';

  @override
  String get themeMateIn3Desc =>
      'جد السلسلة الفائزة التي تؤدي إلى الإماتة في ثلاث نقلات.';

  @override
  String get themeMateIn4 => 'مات في 4';

  @override
  String get themeMateIn4Desc => 'خطط لبضع نقلات قادمة لإجبار الإماتة.';

  @override
  String get themeMateIn5 => 'مات في 5';

  @override
  String get themeMateIn5Desc => 'سلسلة إماتة أطول تكون فيها كل نقلة مهمة.';

  @override
  String get themeOtherMates => 'إماتات أخرى';

  @override
  String get themeOtherMatesDesc =>
      'أنماط خاصة مثل الصف الخلفي والمخنوق وأناستازيا والعربي وبودن والأوبرا وغيرها.';

  @override
  String get themeFork => 'الشوكة';

  @override
  String get themeForkDesc => 'قطعة واحدة تهاجم هدفين أو أكثر معًا.';

  @override
  String get themePin => 'التثبيت';

  @override
  String get themePinDesc => 'قطعة عالقة لأن تحريكها سيكشف شيئًا أثمن.';

  @override
  String get themeSkewer => 'السيخ';

  @override
  String get themeSkewerDesc => 'هاجم قطعة ثمينة واكسب ما يختبئ خلفها.';

  @override
  String get themeDiscoveredAttack => 'الهجوم المكشوف';

  @override
  String get themeDiscoveredAttackDesc => 'حرّك قطعة لتكشف هجوم قطعة أخرى.';

  @override
  String get themeDiscoveredCheck => 'الكش المكشوف';

  @override
  String get themeDiscoveredCheckDesc =>
      'اكشف الكش بتحريك قطعة أخرى من الطريق.';

  @override
  String get themeDoubleCheck => 'الكش المزدوج';

  @override
  String get themeDoubleCheckDesc => 'أعطِ الكش بقطعتين في نفس الوقت.';

  @override
  String get themeSacrifice => 'التضحية';

  @override
  String get themeSacrificeDesc => 'ضحِّ بمواد لتحصل على شيء أقوى في المقابل.';

  @override
  String get themeDeflection => 'الإبعاد';

  @override
  String get themeDeflectionDesc => 'أجبر قطعة على مغادرة مكانها الضروري.';

  @override
  String get themeClearance => 'الإخلاء';

  @override
  String get themeClearanceDesc => 'أبعد قطعة لتفتح الطريق لقطعة أخرى.';

  @override
  String get themeCapturingDefender => 'أخذ المدافع';

  @override
  String get themeCapturingDefenderDesc => 'أزل القطعة التي تحمي هدفًا مهمًا.';

  @override
  String get themeAdvancedTactics => 'تكتيك متقدم';

  @override
  String get themeAdvancedTacticsDesc => 'تركيبات أصعب تشمل عدة أفكار تكتيكية.';

  @override
  String get themeKingsideAttack => 'هجوم جناح الملك';

  @override
  String get themeKingsideAttackDesc => 'ابنِ هجومًا ضد الملك في جناح الملك.';

  @override
  String get themeQueensideAttack => 'هجوم جناح الملكة';

  @override
  String get themeQueensideAttackDesc =>
      'ابحث عن طرق للاختراق حول ملك الخصم في جناح الملكة.';

  @override
  String get themeExposedKing => 'ملك مكشوف';

  @override
  String get themeExposedKingDesc => 'استغل ملكًا فقد حمايته.';

  @override
  String get themeAttackingF2F7 => 'الهجوم على F2 F7';

  @override
  String get themeAttackingF2F7Desc => 'استهدف مربع f2 أو f7 الضعيف قرب الملك.';

  @override
  String get themeEndgame => 'نهاية اللعب';

  @override
  String get themeEndgameDesc => 'جد أفضل طريقة للعب عندما تبقى قطع قليلة.';

  @override
  String get themeRookEndgame => 'نهاية القلاع';

  @override
  String get themeRookEndgameDesc =>
      'تعلّم الاستفادة القصوى من قلاعك في النهاية.';

  @override
  String get themeQueenEndgame => 'نهاية الملكات';

  @override
  String get themeQueenEndgameDesc =>
      'جد النقلات الصحيحة في مواقف تبقى فيها الملكات على الرقعة.';

  @override
  String get themeQueenRookEndgame => 'نهاية الملكة والقلعة';

  @override
  String get themeQueenRookEndgameDesc =>
      'تعامل مع النهايات التي تبقى فيها الملكات والقلاع.';

  @override
  String get themeBishopEndgame => 'نهاية الأفيال';

  @override
  String get themeBishopEndgameDesc =>
      'استخدم فيلك وملكك لإيجاد الخطة الفائزة.';

  @override
  String get themeKnightEndgame => 'نهاية الأحصنة';

  @override
  String get themeKnightEndgameDesc =>
      'جد النقلات الصحيحة في نهايات تكون فيها الأحصنة أهم.';

  @override
  String get themePawnEndgame => 'نهاية البيادق';

  @override
  String get themePawnEndgameDesc => 'احسب سباقات البيادق وجد طريق الفوز.';

  @override
  String get themeZugzwang => 'زوجزوانج';

  @override
  String get themeZugzwangDesc =>
      'ضع خصمك في موقف تجعل فيه أي نقلة الأمور أسوأ.';

  @override
  String get themeAdvancedPawn => 'بيدق متقدم';

  @override
  String get themeAdvancedPawnDesc =>
      'استخدم بيدقًا خطيرًا توغّل في أرض الخصم.';

  @override
  String get themePromotion => 'الترقية';

  @override
  String get themePromotionDesc => 'ادفع بيدقًا حتى النهاية ليصبح قطعة أقوى.';

  @override
  String get themeUnderPromotion => 'الترقية الصغرى';

  @override
  String get themeUnderPromotionDesc =>
      'رقِّ إلى غير الملكة عندما تكون تلك النقلة الفائزة.';

  @override
  String get themeEnPassant => 'الأخذ بالتعدي';

  @override
  String get themeEnPassantDesc => 'لاحظ الفرصة النادرة لأخذ بيدق بالتعدي.';

  @override
  String get themeQuietMove => 'النقلة الهادئة';

  @override
  String get themeQuietMoveDesc =>
      'جد نقلة هادئة تصنع أفضلية قوية دون تكتيك إجباري.';

  @override
  String get themeDefensiveMove => 'النقلة الدفاعية';

  @override
  String get themeDefensiveMoveDesc => 'جد النقلة التي توقف تهديد خصمك.';

  @override
  String get themeAdvantage => 'الأفضلية';

  @override
  String get themeAdvantageDesc =>
      'جد النقلة التي تحافظ على أفضليتك أو تزيدها.';

  @override
  String get themeEquality => 'التعادل';

  @override
  String get themeEqualityDesc => 'جد النقلة التي تُبقي الموقف متوازنًا.';

  @override
  String get themeCrushing => 'النقلة الساحقة';

  @override
  String get themeCrushingDesc =>
      'جد النقلة القوية التي تحوّل الموقف الجيد إلى فوز.';

  @override
  String get pippoThinking2 => 'دعني أبحث عن أفضل نقلة';

  @override
  String get pippoThinking3 => 'لحظة... أرى بعض الأفكار';

  @override
  String get pippoThinking4 => 'أحسب ردّي';

  @override
  String get pippoThreatAsk1 => 'هل ترى ما تهدده هذه النقلة؟';

  @override
  String get pippoThreatAsk2 => 'لدي فكرة صغيرة وراء تلك النقلة...';

  @override
  String get pippoThreatAsk3 => 'احذر — تلك النقلة تضع شيئًا تحت الضغط.';

  @override
  String get pippoThreatAsk4 => 'قد يكون لتلك النقلة أكثر مما يبدو.';

  @override
  String get pippoGreat1 => 'أحسنت لإيجاد النقلة الوحيدة في هذا الموقف!';

  @override
  String get pippoGreat2 => 'كانت نقلة رائعة — ملاحظة موفقة.';

  @override
  String get pippoGreat3 => 'اكتشاف ممتاز. تعاملت مع هذا الموقف بجمال.';

  @override
  String get pippoBrilliant1 => 'رائع! كانت تلك النقلة دقيقة بشكل جميل.';

  @override
  String get pippoBrilliant2 => 'يا لها من فكرة رائعة — لم أتوقعها.';

  @override
  String get pippoBrilliant3 => 'كان ذلك رائعًا. وجدت نقلة مبدعة حقًا.';

  @override
  String get pippoFinished1 => 'كانت مباراة رائعة! هل نلعب مجددًا؟';

  @override
  String get pippoFinished2 => 'أحسنت اللعب! هل تريد مباراة أخرى؟';

  @override
  String get pippoFinished3 => 'مباراة جيدة — استمتعت بها. مباراة ثأرية؟';

  @override
  String get classificationBookComment => 'نقلة من كتاب الافتتاحيات.';

  @override
  String get resignDialogTitle => 'الاستسلام في المباراة؟';

  @override
  String get resignDialogBody =>
      'هل أنت متأكد من الاستسلام؟ سينهي هذا المباراة الحالية.';

  @override
  String get resignConfirm => 'استسلام';

  @override
  String get gameOverResignBlack => 'الأسود يفوز بالاستسلام';

  @override
  String get gameOverResignWhite => 'الأبيض يفوز بالاستسلام';

  @override
  String get gameOverDefault => 'انتهت المباراة';

  @override
  String get gameOverMateBlack => 'الأسود يفوز بالإماتة';

  @override
  String get gameOverMateWhite => 'الأبيض يفوز بالإماتة';

  @override
  String get gameOverStalemate => 'تعادل بالجمود';

  @override
  String get gameOverRepetition => 'تعادل بالتكرار';

  @override
  String get gameOverInsufficient => 'تعادل لعدم كفاية المواد';

  @override
  String get gameOverDrawn => 'تعادلت المباراة';

  @override
  String get playStartFirst => 'ابدأ مباراة أولًا';

  @override
  String get takebackTrainingOnly => 'التراجع متاح في وضع التدريب فقط';

  @override
  String get takebackNoMoves => 'لا نقلات للتراجع عنها';

  @override
  String get takebackDone => 'تم التراجع عن النقلة';

  @override
  String get pippoMissBare => 'فوّت نقلة أفضل في هذا الموقف.';

  @override
  String pippoMissWithMove(String move) {
    return 'فوّت نقلة أفضل في هذا الموقف، وكان عليك لعب $move.';
  }

  @override
  String get pippoBlunderPause =>
      'كانت تلك النقلة خطأ فادحًا. تراجع عنها، أو تابع وسأكمل اللعب.';

  @override
  String get hintTrainingOnly => 'التلميحات متاحة في وضع التدريب فقط';

  @override
  String get hintYourTurnOnly => 'التلميحات متاحة في دورك فقط';

  @override
  String get hintStillAnalyzing => 'ما زلت أحلل... حاول بعد لحظة';

  @override
  String hintLookForPiece(String piece, String square) {
    return 'ابحث عن نقلة جيدة بـ$piece على $square.';
  }

  @override
  String get playToolTakeback => 'تراجع';

  @override
  String get playToolAskHint => 'اطلب تلميحًا من بيبو';

  @override
  String get playToolClassifyHeader => 'تصنيف';

  @override
  String get classifyYourMoves => 'نقلاتك';

  @override
  String get classifyPippoMoves => 'نقلات بيبو';

  @override
  String get playingPippoTitle => 'تلعب ضد بيبو';

  @override
  String get resignButton => 'استسلام';

  @override
  String get playAsHeader => 'العب بـ';

  @override
  String get sideRandom => 'عشوائي';

  @override
  String get strengthHeader => 'القوة';

  @override
  String get optionsHeader => 'الخيارات';

  @override
  String get modeLabel => 'الوضع';

  @override
  String get modeChallenge => 'التحدي';

  @override
  String get modeTraining => 'التدريب';

  @override
  String get startGameButton => 'ابدأ المباراة';

  @override
  String get perkFeedback => 'احصل على ملاحظات عن نقلاتك';

  @override
  String get perkSeeThreats => 'شاهد كل التهديدات';

  @override
  String get perkTakeback => 'تراجع عن النقلات متى شئت';

  @override
  String get perkBlunderPause => 'تتوقف المباراة عند الخطأ الفادح';

  @override
  String get perkHintsAllowed => 'التلميحات مسموحة';

  @override
  String get perkNoFeedback => 'لا ملاحظات عن النقلات';

  @override
  String get perkHiddenThreats => 'التهديدات تبقى مخفية';

  @override
  String get perkNoTakebacks => 'لا تراجع';

  @override
  String get perkNoBlunderPause => 'تستمر المباراة بعد الأخطاء الفادحة';

  @override
  String get perkNoHints => 'لا تلميحات';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'إخفاء التهديدات';

  @override
  String get showThreat => 'إظهار التهديد';

  @override
  String get blunderContinue => 'تابع';

  @override
  String get gameOverFallback => 'انتهت المباراة';

  @override
  String get resultHome => 'الرئيسية';

  @override
  String get resultNewGame => 'مباراة جديدة';

  @override
  String get resultAnalyzeGame => 'تحليل المباراة';

  @override
  String get gameToolsTooltip => 'أدوات اللعب';

  @override
  String get movesHeader => 'النقلات';

  @override
  String moveCountLabel(int count) {
    return '$count نقلات';
  }

  @override
  String get movesEmptyPlay => 'ستظهر نقلاتك هنا أثناء اللعب.';

  @override
  String get puzzleNotBest => 'ليست أفضل نقلة. حاول مجددًا!';

  @override
  String get puzzleSessionComplete => 'اكتملت جلسة التدريب!';

  @override
  String get practiceTitle => 'تدريب';

  @override
  String get puzzleEmpty => 'لا ألغاز متوفرة.';

  @override
  String puzzleCounter(int current, int total) {
    return 'اللغز $current/$total';
  }

  @override
  String get puzzleHint => 'تلميح';

  @override
  String get puzzleShowMove => 'عرض النقلة';

  @override
  String get puzzleUsedHint => 'تم استخدام التلميح';

  @override
  String get puzzleNext => 'اللغز التالي';

  @override
  String get analysisTitle => 'التحليل';

  @override
  String get addGameTooltip => 'أضف مباراة أو موقفًا';

  @override
  String get closeGameButton => 'إغلاق';

  @override
  String get positionLoadedOk => 'تم تحميل الموقف';

  @override
  String get gameImportedOk => 'تم استيراد المباراة';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess ضد $opponent';
  }

  @override
  String get youLabel => 'أنت';

  @override
  String explorerGameLoaded(String white, String black) {
    return 'تم تحميل $white ضد $black';
  }

  @override
  String get reviewNoGame => 'لا مباراة للمراجعة';

  @override
  String get reviewQuotaUsed => 'استخدمت مراجعات اليوم. اشترك في Pro للمزيد.';

  @override
  String get analysisNoMoves => 'لا نقلات للتحليل';

  @override
  String get settingsEngineHeader => 'المحرك';

  @override
  String get settingsEnableEngine => 'تفعيل المحرك';

  @override
  String get settingsDepth => 'العمق';

  @override
  String get settingsClassificationHeader => 'تصنيف النقلات';

  @override
  String get settingsEnableClassification => 'تفعيل التصنيف';

  @override
  String get settingsThreatHeader => 'كاشف التهديدات';

  @override
  String get settingsThreatToggle => 'كاشف التهديدات';

  @override
  String get settingsLinesLabel => 'عدد الخطوط';

  @override
  String get filterBook => 'الكتاب';

  @override
  String get filterBrilliant => 'رائعة';

  @override
  String get filterBlunder => 'خطأ فادح';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get showAll => 'عرض الكل';

  @override
  String get analyzingBanner => 'مباراتك قيد التحليل، يمكنك مغادرة هذه الشاشة';

  @override
  String get fullViewTooltip => 'عرض كامل';

  @override
  String get compactViewTooltip => 'عرض مضغوط';

  @override
  String get classifyingMove => 'جارٍ تصنيف النقلة...';

  @override
  String get phraseBest => 'أفضل نقلة';

  @override
  String get phraseBrilliant => 'نقلة رائعة';

  @override
  String get phraseGreat => 'نقلة عظيمة';

  @override
  String get phraseExcellent => 'نقلة ممتازة';

  @override
  String get phraseGood => 'نقلة جيدة';

  @override
  String get phraseInaccuracy => 'عدم دقة';

  @override
  String get phraseMistake => 'خطأ';

  @override
  String get phraseBlunder => 'خطأ فادح';

  @override
  String get phraseMiss => 'فرصة ضائعة';

  @override
  String get phraseBook => 'نقلة كتاب';

  @override
  String get phraseForced => 'نقلة إجبارية';

  @override
  String sentenceBestSuffix(String move) {
    return '، $move كانت أفضل نقلة';
  }

  @override
  String get retryReview => 'إعادة المراجعة';

  @override
  String get reviewWaiting => 'مباراتك قيد المراجعة';

  @override
  String get pgnEmpty => 'لا نقلات بعد';

  @override
  String get pgnResume => 'عودة';

  @override
  String get showBestTooltip => 'عرض أفضل نقلة';

  @override
  String get tabMoves => 'النقلات';

  @override
  String get tabExplorer => 'المستكشف';

  @override
  String get moveTreeHeader => 'شجرة النقلات';

  @override
  String get moveTreeEmpty => 'ستظهر نقلاتك وتنويعاتك هنا.';

  @override
  String get gameReportButton => 'تقرير المباراة';

  @override
  String get gameAnalysisTitle => 'تحليل المباراة';

  @override
  String get analyzeButton => 'تحليل';

  @override
  String get viewReportTooltip => 'عرض التقرير';

  @override
  String get noReportYet => 'لا تقرير بعد';

  @override
  String get addToAnalysisTitle => 'أضف إلى التحليل';

  @override
  String get addToAnalysisSubtitle => 'ابدأ من مباراة أو موقف أو رقعة حرة.';

  @override
  String get importSegment => 'استيراد';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'تركيب';

  @override
  String get gameReportTitle => 'تقرير المباراة';

  @override
  String get accuraciesHeader => 'الدقة';

  @override
  String get accuracyRerunHint => 'أعد التحليل الكامل لحساب الدقة.';

  @override
  String get pastePgnTooltip => 'لصق PGN';

  @override
  String get pastePgnButton => 'لصق PGN المنسوخ';

  @override
  String get searchingLabel => 'جارٍ البحث...';

  @override
  String get importingLabel => 'جارٍ الاستيراد...';

  @override
  String get searchGamesButton => 'البحث عن مباريات';

  @override
  String get startAnalysisButton => 'بدء التحليل';

  @override
  String get fenFieldLabel => 'الموقف (FEN)';

  @override
  String get pasteFenTooltip => 'لصق FEN';

  @override
  String get pasteFenButton => 'لصق FEN المنسوخ';

  @override
  String get loadPositionButton => 'تحميل الموقف';

  @override
  String get inputPgnText => 'نص PGN';

  @override
  String get inputUsername => 'اسم المستخدم';

  @override
  String get inputGameUrl => 'رابط المباراة';

  @override
  String get hintPastePgn => 'الصق PGN هنا...';

  @override
  String get hintEnterUsername => 'أدخل اسم المستخدم...';

  @override
  String get dialogOk => 'حسنًا';

  @override
  String get lichessSignInCancelled => 'تم إلغاء الدخول عبر Lichess';

  @override
  String get boardSetupTitle => 'تركيب الموقف';

  @override
  String get flipBoardTooltip => 'قلب الرقعة';

  @override
  String get clearBoardButton => 'مسح الرقعة';

  @override
  String get startPositionButton => 'الوضع الابتدائي';

  @override
  String get whoMovesHeader => 'من يلعب أولًا';

  @override
  String get piecesHeader => 'القطع';

  @override
  String get setupInstructions =>
      'المس قطعة لاختيارها ثم المس الرقعة لوضعها. اسحب قطعة إلى الرقعة لإضافتها، أو خارج الرقعة لإزالتها.';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'إنهاء';

  @override
  String engineDepthLabel(int depth) {
    return 'العمق $depth';
  }

  @override
  String get analyzeGameTitle => 'تحليل المباراة';

  @override
  String get reviewsUnlimited => 'مراجعات غير محدودة اليوم';

  @override
  String reviewsLeftToday(int done, int total) {
    return '$done/$total مراجعات متاحة اليوم';
  }

  @override
  String get analyzeTypeHeader => 'النوع';

  @override
  String get analyzeModeAnalysis => 'تحليل';

  @override
  String get analyzeModeAnalysisDesc =>
      'يصنّف كل نقلات مباراتك باستخدام Stockfish';

  @override
  String get analyzeModeReview => 'مراجعة';

  @override
  String get upgradeToProTitle => 'الترقية إلى Pro';

  @override
  String get reviewModeDesc => 'شروح نقلة بنقلة لمباراتك';

  @override
  String get reviewLockedDesc => 'افتح مراجعات أكثر كل يوم';

  @override
  String get engineDepthHeader => 'عمق المحرك';

  @override
  String depthValueLabel(int depth) {
    return 'العمق $depth';
  }

  @override
  String get depthHint => 'العمق الأعلى قد يستغرق وقتًا أطول في التحليل';

  @override
  String get selectGameTitle => 'اختر مباراة';

  @override
  String get versusShort => 'ضد';

  @override
  String get speedBullet => 'رصاصة';

  @override
  String get speedBlitz => 'خاطفة';

  @override
  String get speedRapid => 'سريعة';

  @override
  String get speedClassical => 'كلاسيكية';

  @override
  String get openingExplorerTitle => 'مستكشف الافتتاحيات';

  @override
  String get dbMasters => 'الأساتذة';

  @override
  String get filtersHeader => 'المرشحات';

  @override
  String get theoreticalMoves => 'النقلات النظرية';

  @override
  String get topMasterGames => 'أفضل مباريات الأساتذة';

  @override
  String get recentGames => 'المباريات الأخيرة';

  @override
  String get explorerSignInDesc =>
      'سجّل الدخول عبر Lichess لاستكشاف ملايين المباريات ومباريات الأساتذة وإحصاءات الافتتاحيات.';

  @override
  String get signInWithLichess => 'الدخول عبر Lichess';

  @override
  String get noOpeningData => 'لا بيانات افتتاح متوفرة';

  @override
  String gamesCountLabel(int count) {
    return '$count مباريات';
  }

  @override
  String get unknownPlayer => 'غير معروف';

  @override
  String get monthJanuary => 'يناير';

  @override
  String get monthFebruary => 'فبراير';

  @override
  String get monthMarch => 'مارس';

  @override
  String get monthApril => 'أبريل';

  @override
  String get monthMay => 'مايو';

  @override
  String get monthJune => 'يونيو';

  @override
  String get monthJuly => 'يوليو';

  @override
  String get monthAugust => 'أغسطس';

  @override
  String get monthSeptember => 'سبتمبر';

  @override
  String get monthOctober => 'أكتوبر';

  @override
  String get monthNovember => 'نوفمبر';

  @override
  String get monthDecember => 'ديسمبر';

  @override
  String get indicatorGreen => 'أخضر';

  @override
  String get indicatorAmber => 'كهرماني';

  @override
  String get indicatorRed => 'أحمر';

  @override
  String get clsBest => 'الأفضل';

  @override
  String get clsBrilliant => 'رائعة';

  @override
  String get clsGreat => 'عظيمة';

  @override
  String get clsExcellent => 'ممتازة';

  @override
  String get clsGood => 'جيدة';

  @override
  String get clsInaccuracy => 'عدم دقة';

  @override
  String get clsMistake => 'خطأ';

  @override
  String get clsBlunder => 'خطأ فادح';

  @override
  String get clsBook => 'الكتاب';

  @override
  String get clsForced => 'إجبارية';

  @override
  String get clsMiss => 'فرصة ضائعة';

  @override
  String averageRatingLabel(int rating) {
    return 'متوسط $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move $label';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move كانت أفضل نقلة.';
  }
}
