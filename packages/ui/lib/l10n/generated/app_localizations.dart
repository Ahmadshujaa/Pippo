import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('pt'),
  ];

  /// App name shown in the task switcher. Brand name; rarely translated.
  ///
  /// In en, this message translates to:
  /// **'Pippo'**
  String get appTitle;

  /// Fallback display name when the user has not set one.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// Shown in the profile header when there is no session.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @planAdmin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get planAdmin;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'PRO MEMBER'**
  String get planPro;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'FREE MEMBER'**
  String get planFree;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsSection;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, or system theme'**
  String get appearanceSubtitle;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your Atlas Pro plan'**
  String get subscriptionSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Subtitle under the Language row showing the currently selected language.
  ///
  /// In en, this message translates to:
  /// **'{language}'**
  String languageSubtitle(String language);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs and customer service'**
  String get helpSubtitle;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support team'**
  String get contactSupportSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @editDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Edit Display Name'**
  String get editDisplayName;

  /// No description provided for @displayNameRule.
  ///
  /// In en, this message translates to:
  /// **'Choose a name up to {maxLength} characters long.'**
  String displayNameRule(int maxLength);

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get languageSheetTitle;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemLanguage;

  /// No description provided for @supportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of problem'**
  String get supportTypeLabel;

  /// No description provided for @supportTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the option that best describes your issue.'**
  String get supportTypeHint;

  /// No description provided for @supportTypeUi.
  ///
  /// In en, this message translates to:
  /// **'UI'**
  String get supportTypeUi;

  /// No description provided for @supportTypeError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get supportTypeError;

  /// No description provided for @supportTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportTypeOther;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubjectLabel;

  /// No description provided for @supportSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your issue'**
  String get supportSubjectHint;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue in detail...'**
  String get supportMessageHint;

  /// No description provided for @supportMessageCounter.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} characters'**
  String supportMessageCounter(int count, int max);

  /// No description provided for @supportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get supportSubmitButton;

  /// No description provided for @supportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket Submitted!'**
  String get supportSuccessTitle;

  /// No description provided for @supportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'We will respond to your email within 24-48 hours.'**
  String get supportSuccessBody;

  /// No description provided for @supportSuccessDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get supportSuccessDone;

  /// No description provided for @supportSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to contact support'**
  String get supportSignInTitle;

  /// No description provided for @supportSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Tickets are linked to your account so we can reply to you. Sign in and try again.'**
  String get supportSignInBody;

  /// No description provided for @supportOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Reconnect to submit your ticket.'**
  String get supportOfflineNotice;

  /// No description provided for @supportErrTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of problem.'**
  String get supportErrTypeRequired;

  /// No description provided for @supportErrSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a subject.'**
  String get supportErrSubjectRequired;

  /// No description provided for @supportErrMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a message.'**
  String get supportErrMessageRequired;

  /// No description provided for @supportErrSubjectTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your subject is too long.'**
  String get supportErrSubjectTooLong;

  /// No description provided for @supportErrMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your message is too long.'**
  String get supportErrMessageTooLong;

  /// No description provided for @supportErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your ticket. Please try again.'**
  String get supportErrGeneric;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get offlineBannerTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @boardSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Board Settings'**
  String get boardSettingsTitle;

  /// Heading above the piece-style picker. Its options are piece-set font names, which stay untranslated.
  ///
  /// In en, this message translates to:
  /// **'Piece Set'**
  String get pieceSetLabel;

  /// Heading above the board colour picker. Its options are colour words, and those ARE translated.
  ///
  /// In en, this message translates to:
  /// **'Board Theme'**
  String get boardThemeLabel;

  /// No description provided for @moveIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Move Indicator'**
  String get moveIndicatorLabel;

  /// No description provided for @showCoordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Coordinates'**
  String get showCoordinatesLabel;

  /// No description provided for @dragAndDropLabel.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop'**
  String get dragAndDropLabel;

  /// No description provided for @soundLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundLabel;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @editExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Explanation'**
  String get editExplanationTitle;

  /// No description provided for @writeExplanationHint.
  ///
  /// In en, this message translates to:
  /// **'Write the explanation...'**
  String get writeExplanationHint;

  /// Dismisses a dialog without saving. Distinct from the logout row.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @boardThemeEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get boardThemeEmerald;

  /// No description provided for @boardThemeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get boardThemeMidnight;

  /// No description provided for @boardThemePurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get boardThemePurple;

  /// No description provided for @boardThemeSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get boardThemeSand;

  /// No description provided for @boardThemeBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get boardThemeBlue;

  /// No description provided for @boardThemeBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get boardThemeBrown;

  /// No description provided for @quotaUpgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to pro to solve unlimited puzzles'**
  String get quotaUpgradeCta;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @offlineDownloadsProNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline puzzle downloads are available with Pro. Upgrade to save puzzles on this device.'**
  String get offlineDownloadsProNotice;

  /// No description provided for @savedForOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device for offline solving'**
  String get savedForOffline;

  /// No description provided for @downloadPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Puzzles'**
  String get downloadPuzzlesTitle;

  /// No description provided for @puzzleDecksTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Decks'**
  String get puzzleDecksTitle;

  /// No description provided for @deckRecentMistakes.
  ///
  /// In en, this message translates to:
  /// **'Recent Mistakes'**
  String get deckRecentMistakes;

  /// No description provided for @deckRecentMistakesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tactics from your lost games'**
  String get deckRecentMistakesSubtitle;

  /// No description provided for @deckMatingPatterns.
  ///
  /// In en, this message translates to:
  /// **'Mating Patterns'**
  String get deckMatingPatterns;

  /// Tactics card subtitle. 'Endgame kills' is chess slang for winning mating combinations late in the game, not literal killing.
  ///
  /// In en, this message translates to:
  /// **'Master the endgame kills'**
  String get deckMatingPatternsSubtitle;

  /// No description provided for @deckOpeningTraps.
  ///
  /// In en, this message translates to:
  /// **'Opening Traps'**
  String get deckOpeningTraps;

  /// No description provided for @deckOpeningTrapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Common tricks in your repertoire'**
  String get deckOpeningTrapsSubtitle;

  /// No description provided for @deckDailyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenges'**
  String get deckDailyChallenges;

  /// No description provided for @deckDailyChallengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh puzzles every day'**
  String get deckDailyChallengesSubtitle;

  /// Shown above the download-size slider as the user drags it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 puzzle} other{{count} puzzles}}'**
  String selectedPuzzleCount(int count);

  /// Primary call to action on the welcome screen; also the heading of the auth entry screen.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedTitle;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Get better at chess fast with Pippo, your personal coach to help you learn, improve, and win more games.'**
  String get welcomeTagline;

  /// No description provided for @signInOrSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or sign up to save your progress.'**
  String get signInOrSignUpSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @errGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not complete Google sign-in.'**
  String get errGoogleSignIn;

  /// No description provided for @signInTab.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTab;

  /// No description provided for @signUpTab.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTab;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Divider label between the Google button and the email form. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account and keep climbing the ranks.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of players and improve your game.'**
  String get signUpSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// Placeholder example first name. Use a common name in the target locale.
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get firstNameHint;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// Placeholder example last name. Use a common name in the target locale.
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get lastNameHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @enterResetCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCodeTitle;

  /// No description provided for @resetIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we will send you a recovery code.'**
  String get resetIntro;

  /// No description provided for @resetCodeSentIntro.
  ///
  /// In en, this message translates to:
  /// **'We sent a recovery code to {email}. Enter it below with your new password.'**
  String resetCodeSentIntro(String email);

  /// No description provided for @recoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery Code'**
  String get recoveryCodeLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @sendRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Code'**
  String get sendRecoveryCode;

  /// No description provided for @errEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errEnterValidEmail;

  /// No description provided for @errEnterCodeFromEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email.'**
  String get errEnterCodeFromEmail;

  /// No description provided for @errPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errPasswordsDoNotMatch;

  /// No description provided for @namePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get namePromptTitle;

  /// No description provided for @namePromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a name for your profile so we can personalize your experience.'**
  String get namePromptSubtitle;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @enterVerificationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCodeTitle;

  /// First half of the OTP sentence. The account email is rendered in bold between this and otpSentSuffix.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an 8-digit code to\n'**
  String get otpSentPrefix;

  /// Second half of the OTP sentence, following the bolded account email.
  ///
  /// In en, this message translates to:
  /// **'. Please check your inbox or spam folder.'**
  String get otpSentSuffix;

  /// No description provided for @verifyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCodeButton;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent successfully'**
  String get verificationCodeResent;

  /// No description provided for @helloGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloGreeting(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn something new today?'**
  String get homeSubtitle;

  /// No description provided for @coursesSection.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get coursesSection;

  /// No description provided for @dailyPracticeSection.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice'**
  String get dailyPracticeSection;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Heading of the daily stats card. Rendered uppercase; keep it terse.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayLabel;

  /// No description provided for @gamesVsPippo.
  ///
  /// In en, this message translates to:
  /// **'games vs Pippo'**
  String get gamesVsPippo;

  /// No description provided for @puzzleRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Rating'**
  String get puzzleRatingLabel;

  /// No description provided for @dailyStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreakLabel;

  /// No description provided for @chaptersDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapters done'**
  String get chaptersDoneLabel;

  /// No description provided for @tacticsTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tactics Training'**
  String get tacticsTrainingTitle;

  /// No description provided for @tacticsTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solve puzzles and sharpen your play'**
  String get tacticsTrainingSubtitle;

  /// No description provided for @dailyPuzzleLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Puzzle'**
  String get dailyPuzzleLabel;

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get playNow;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get navCourses;

  /// No description provided for @navPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Puzzles'**
  String get navPuzzles;

  /// No description provided for @navAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get navAnalysis;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// Short plan badge in the home app bar. Distinct from planAdmin, which spells out 'ADMIN' on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get planBadgeAdmin;

  /// No description provided for @planBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get planBadgeFree;

  /// No description provided for @planBadgePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get planBadgePro;

  /// Plan pill under the greeting. tier is one of the planBadge* strings.
  ///
  /// In en, this message translates to:
  /// **'{tier} PLAN'**
  String planChipLabel(String tier);

  /// No description provided for @coursesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Courses coming soon'**
  String get coursesComingSoon;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @continueLearningButton.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearningButton;

  /// No description provided for @variationsDone.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{completed}/{total} variation done} other{{completed}/{total} variations done}}'**
  String variationsDone(int completed, int total);

  /// No description provided for @sideWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get sideWhite;

  /// No description provided for @sideBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get sideBlack;

  /// Single-letter badge for the side a course teaches. The letter for 'white' in the target language.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get sideWhiteInitial;

  /// Single-letter badge for the side a course teaches. The letter for 'black' in the target language.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get sideBlackInitial;

  /// Chip on a course card, e.g. 'White · 6 Chapters'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{side} · 1 Chapter} other{{side} · {count} Chapters}}'**
  String courseMetaChip(String side, int count);

  /// No description provided for @puzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzles'**
  String get puzzlesTitle;

  /// No description provided for @puzzlesIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharpen your tactics'**
  String get puzzlesIntroTitle;

  /// No description provided for @puzzlesIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Train on the themes that matter most and fix the mistakes you made in your games.'**
  String get puzzlesIntroSubtitle;

  /// No description provided for @puzzlesFromYourGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzles from your games'**
  String get puzzlesFromYourGamesTitle;

  /// No description provided for @solveNowButton.
  ///
  /// In en, this message translates to:
  /// **'Solve Now'**
  String get solveNowButton;

  /// No description provided for @puzzlesRemainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Puzzles Remaining'**
  String puzzlesRemainingCount(int count);

  /// No description provided for @noPuzzlesFromGamesMessage.
  ///
  /// In en, this message translates to:
  /// **'No puzzles yet — finish a game against Pippo and your mistakes will become puzzles.'**
  String get noPuzzlesFromGamesMessage;

  /// No description provided for @puzzlesDownloadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} puzzles downloaded — available even when you are offline.'**
  String puzzlesDownloadedSuccess(int count);

  /// No description provided for @mixedPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Mixed Puzzles'**
  String get mixedPuzzlesTitle;

  /// No description provided for @mixedPuzzlesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play puzzles of random themes'**
  String get mixedPuzzlesSubtitle;

  /// No description provided for @mixedPuzzlesRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Requires an internet connection'**
  String get mixedPuzzlesRequiresInternet;

  /// No description provided for @downloadingPuzzlesStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading puzzles...'**
  String get downloadingPuzzlesStatus;

  /// No description provided for @downloadPuzzlesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save 10–100 puzzles to solve without internet'**
  String get downloadPuzzlesSubtitle;

  /// No description provided for @playDownloadedPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Play Downloaded Puzzles'**
  String get playDownloadedPuzzlesTitle;

  /// No description provided for @downloadedPuzzlesSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'{count} puzzles saved — available offline'**
  String downloadedPuzzlesSavedOffline(int count);

  /// No description provided for @practiceThemesSection.
  ///
  /// In en, this message translates to:
  /// **'Practice themes'**
  String get practiceThemesSection;

  /// No description provided for @browseAllThemesButton.
  ///
  /// In en, this message translates to:
  /// **'Browse all themes'**
  String get browseAllThemesButton;

  /// No description provided for @themesRequireInternet.
  ///
  /// In en, this message translates to:
  /// **'Themes require internet'**
  String get themesRequireInternet;

  /// No description provided for @coursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get coursesTitle;

  /// No description provided for @coursesTabOpenings.
  ///
  /// In en, this message translates to:
  /// **'Openings'**
  String get coursesTabOpenings;

  /// No description provided for @coursesTabMiddlegames.
  ///
  /// In en, this message translates to:
  /// **'Middlegames'**
  String get coursesTabMiddlegames;

  /// No description provided for @coursesTabEndgames.
  ///
  /// In en, this message translates to:
  /// **'Endgames'**
  String get coursesTabEndgames;

  /// No description provided for @noCoursesHereYet.
  ///
  /// In en, this message translates to:
  /// **'No courses here yet.'**
  String get noCoursesHereYet;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @playAsSide.
  ///
  /// In en, this message translates to:
  /// **'Play as {side}'**
  String playAsSide(String side);

  /// No description provided for @chapterCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chapterCountLabel(int count);

  /// No description provided for @variationCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} variations'**
  String variationCountLabel(int count);

  /// No description provided for @courseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Course Details'**
  String get courseDetailsTitle;

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTitle;

  /// No description provided for @ecoCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'ECO: {code}'**
  String ecoCodeLabel(String code);

  /// No description provided for @noChaptersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chapters available.'**
  String get noChaptersAvailable;

  /// No description provided for @chapterCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get chapterCompletedBadge;

  /// No description provided for @noVariationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No variations available'**
  String get noVariationsAvailable;

  /// No description provided for @noVariationsForChapterYet.
  ///
  /// In en, this message translates to:
  /// **'No variations available for this chapter yet.'**
  String get noVariationsForChapterYet;

  /// No description provided for @learnButton.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnButton;

  /// No description provided for @testButton.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testButton;

  /// No description provided for @pricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get pricingTitle;

  /// No description provided for @pricingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your full\nchess potential.'**
  String get pricingHeroTitle;

  /// No description provided for @pricingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get advanced analysis, unlimited puzzles, and AI-powered coaching.'**
  String get pricingHeroSubtitle;

  /// No description provided for @pricingFaqHeader.
  ///
  /// In en, this message translates to:
  /// **'FREQUENTLY ASKED'**
  String get pricingFaqHeader;

  /// No description provided for @pricingFaqCancelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel anytime?'**
  String get pricingFaqCancelQuestion;

  /// No description provided for @pricingFaqCancelAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can cancel your Pro subscription at any time. You\'ll keep access until the end of your billing period.'**
  String get pricingFaqCancelAnswer;

  /// No description provided for @pricingFaqTrialQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is there a free trial?'**
  String get pricingFaqTrialQuestion;

  /// No description provided for @pricingFaqTrialAnswer.
  ///
  /// In en, this message translates to:
  /// **'Pro comes with a 7-day free trial. No credit card required to start.'**
  String get pricingFaqTrialAnswer;

  /// No description provided for @pricingFaqPaymentQuestion.
  ///
  /// In en, this message translates to:
  /// **'What payment methods do you accept?'**
  String get pricingFaqPaymentQuestion;

  /// No description provided for @pricingFaqPaymentAnswer.
  ///
  /// In en, this message translates to:
  /// **'We accept all major credit cards, Apple Pay, and Google Pay.'**
  String get pricingFaqPaymentAnswer;

  /// No description provided for @pricingMostPopularBadge.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get pricingMostPopularBadge;

  /// No description provided for @pricingFreeBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get pricingFreeBadge;

  /// No description provided for @pricingProTierName.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pricingProTierName;

  /// No description provided for @pricingFreeTierName.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get pricingFreeTierName;

  /// No description provided for @pricingProPrice.
  ///
  /// In en, this message translates to:
  /// **'\$9.99/mo'**
  String get pricingProPrice;

  /// No description provided for @pricingFreePrice.
  ///
  /// In en, this message translates to:
  /// **'\$0'**
  String get pricingFreePrice;

  /// No description provided for @pricingFeatureUnlimitedAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Unlimited engine analysis'**
  String get pricingFeatureUnlimitedAnalysis;

  /// No description provided for @pricingFeatureDeepClassification.
  ///
  /// In en, this message translates to:
  /// **'Deep move classification'**
  String get pricingFeatureDeepClassification;

  /// No description provided for @pricingFeatureAiReview.
  ///
  /// In en, this message translates to:
  /// **'AI-powered game review'**
  String get pricingFeatureAiReview;

  /// No description provided for @pricingFeatureOpeningExplorer.
  ///
  /// In en, this message translates to:
  /// **'Advanced opening explorer'**
  String get pricingFeatureOpeningExplorer;

  /// No description provided for @pricingFeatureUnlimitedPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Unlimited puzzle sets'**
  String get pricingFeatureUnlimitedPuzzles;

  /// No description provided for @pricingFeatureTrainingPlans.
  ///
  /// In en, this message translates to:
  /// **'Personalized training plans'**
  String get pricingFeatureTrainingPlans;

  /// No description provided for @pricingFeaturePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get pricingFeaturePrioritySupport;

  /// No description provided for @pricingFeatureEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early access to new features'**
  String get pricingFeatureEarlyAccess;

  /// No description provided for @pricingFeatureBasicAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Basic engine analysis'**
  String get pricingFeatureBasicAnalysis;

  /// No description provided for @pricingFeatureStandardClassification.
  ///
  /// In en, this message translates to:
  /// **'Standard move classification'**
  String get pricingFeatureStandardClassification;

  /// No description provided for @pricingFeatureGameImport.
  ///
  /// In en, this message translates to:
  /// **'Game import from Lichess & Chess.com'**
  String get pricingFeatureGameImport;

  /// No description provided for @pricingFeatureLimitedPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Limited puzzle sets'**
  String get pricingFeatureLimitedPuzzles;

  /// No description provided for @pricingFeatureCommunityAccess.
  ///
  /// In en, this message translates to:
  /// **'Community access'**
  String get pricingFeatureCommunityAccess;

  /// No description provided for @pricingStartTrialButton.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get pricingStartTrialButton;

  /// No description provided for @pricingCurrentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get pricingCurrentPlanButton;

  /// No description provided for @startingEngineStatus.
  ///
  /// In en, this message translates to:
  /// **'Starting engine...'**
  String get startingEngineStatus;

  /// No description provided for @downloadPippoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Download Pippo (BaseModel.onnx) to play offline.'**
  String get downloadPippoPrompt;

  /// No description provided for @downloadProgressMbLabel.
  ///
  /// In en, this message translates to:
  /// **'{received} MB / {total} MB'**
  String downloadProgressMbLabel(String received, String total);

  /// No description provided for @downloadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloadingStatus;

  /// No description provided for @downloadEngineButton.
  ///
  /// In en, this message translates to:
  /// **'Download Engine'**
  String get downloadEngineButton;

  /// No description provided for @startChapterButton.
  ///
  /// In en, this message translates to:
  /// **'Start Chapter'**
  String get startChapterButton;

  /// No description provided for @finishChapterButton.
  ///
  /// In en, this message translates to:
  /// **'Finish Chapter'**
  String get finishChapterButton;

  /// No description provided for @takeTestButton.
  ///
  /// In en, this message translates to:
  /// **'Take Test'**
  String get takeTestButton;

  /// No description provided for @exploreBranchesButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Branches'**
  String get exploreBranchesButton;

  /// No description provided for @moveToNextVariationButton.
  ///
  /// In en, this message translates to:
  /// **'Move to Next Variation'**
  String get moveToNextVariationButton;

  /// No description provided for @variationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Variations'**
  String get variationsTitle;

  /// No description provided for @alternativeBranchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Alternative Branches'**
  String get alternativeBranchesTitle;

  /// No description provided for @noTheoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No theory available for this variation.'**
  String get noTheoryAvailable;

  /// No description provided for @editBranchExplanationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit branch explanation'**
  String get editBranchExplanationTooltip;

  /// No description provided for @editExplanationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit explanation'**
  String get editExplanationTooltip;

  /// No description provided for @editTheoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit theory'**
  String get editTheoryTooltip;

  /// No description provided for @branchEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch: {name}'**
  String branchEditTitle(String name);

  /// No description provided for @moveEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Move: {move}'**
  String moveEditTitle(String move);

  /// No description provided for @chapterEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter: {name}'**
  String chapterEditTitle(String name);

  /// No description provided for @theoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Theory: {name}'**
  String theoryEditTitle(String name);

  /// No description provided for @freeUsersUnlockOneChapterPerDay.
  ///
  /// In en, this message translates to:
  /// **'Free users can unlock one new chapter per day.'**
  String get freeUsersUnlockOneChapterPerDay;

  /// No description provided for @playMovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Play {move}'**
  String playMovePrompt(String move);

  /// No description provided for @opponentThinking.
  ///
  /// In en, this message translates to:
  /// **'I\'m thinking'**
  String get opponentThinking;

  /// No description provided for @opponentPlayedMove.
  ///
  /// In en, this message translates to:
  /// **'Opponent played {move}'**
  String opponentPlayedMove(String move);

  /// No description provided for @correctMoveWithName.
  ///
  /// In en, this message translates to:
  /// **'Correct! {move}'**
  String correctMoveWithName(String move);

  /// No description provided for @notRightMove.
  ///
  /// In en, this message translates to:
  /// **'That\'s not the right move'**
  String get notRightMove;

  /// No description provided for @variationCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Variation Completed!'**
  String get variationCompletedMessage;

  /// No description provided for @explanationUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Explanation updated for everyone studying this course.'**
  String get explanationUpdatedMessage;

  /// No description provided for @thinkAboutMovesHint.
  ///
  /// In en, this message translates to:
  /// **'Think about the {piece} moves...'**
  String thinkAboutMovesHint(String piece);

  /// No description provided for @writeHintPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write the hint...'**
  String get writeHintPlaceholder;

  /// No description provided for @hintUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Hint updated for everyone testing this chapter.'**
  String get hintUpdatedMessage;

  /// No description provided for @masteryTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Mastery Test'**
  String get masteryTestTitle;

  /// No description provided for @thinkItThrough.
  ///
  /// In en, this message translates to:
  /// **'Think it through...'**
  String get thinkItThrough;

  /// No description provided for @correctFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correctFeedback;

  /// No description provided for @notQuiteTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not quite — try again'**
  String get notQuiteTryAgain;

  /// No description provided for @opponentThinkingTest.
  ///
  /// In en, this message translates to:
  /// **'Opponent is thinking...'**
  String get opponentThinkingTest;

  /// No description provided for @yourMovePlayOpeningLine.
  ///
  /// In en, this message translates to:
  /// **'Your move — play the opening line'**
  String get yourMovePlayOpeningLine;

  /// No description provided for @editHintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit hint'**
  String get editHintTooltip;

  /// No description provided for @variationLabelUpper.
  ///
  /// In en, this message translates to:
  /// **'VARIATION'**
  String get variationLabelUpper;

  /// No description provided for @overallProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get overallProgressLabel;

  /// No description provided for @pliesProgressCounter.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} plies'**
  String pliesProgressCounter(int done, int total);

  /// No description provided for @abortButton.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get abortButton;

  /// No description provided for @getHintButton.
  ///
  /// In en, this message translates to:
  /// **'Get Hint'**
  String get getHintButton;

  /// No description provided for @chapterPassedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter Passed'**
  String get chapterPassedTitle;

  /// No description provided for @youInternalizedChapter.
  ///
  /// In en, this message translates to:
  /// **'You internalized {chapter}.'**
  String youInternalizedChapter(String chapter);

  /// No description provided for @variationsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} variations completed'**
  String variationsCompletedCount(int count);

  /// No description provided for @returnToCourseButton.
  ///
  /// In en, this message translates to:
  /// **'Return to Course'**
  String get returnToCourseButton;

  /// No description provided for @hintForMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Hint for {move}'**
  String hintForMoveTitle(String move);

  /// No description provided for @dailyPuzzleTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Puzzle'**
  String get dailyPuzzleTitle;

  /// No description provided for @downloadedPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Puzzles'**
  String get downloadedPuzzlesTitle;

  /// No description provided for @whiteToPlay.
  ///
  /// In en, this message translates to:
  /// **'White to play'**
  String get whiteToPlay;

  /// No description provided for @blackToPlay.
  ///
  /// In en, this message translates to:
  /// **'Black to play'**
  String get blackToPlay;

  /// No description provided for @hintLookAtPiece.
  ///
  /// In en, this message translates to:
  /// **'Look at your {piece} on {square}'**
  String hintLookAtPiece(String piece, String square);

  /// No description provided for @hintPieceIsKey.
  ///
  /// In en, this message translates to:
  /// **'Your {piece} on {square} is the key'**
  String hintPieceIsKey(String piece, String square);

  /// No description provided for @hintFocusOnPiece.
  ///
  /// In en, this message translates to:
  /// **'Focus on the {piece} sitting on {square}'**
  String hintFocusOnPiece(String piece, String square);

  /// No description provided for @themeHintAbout.
  ///
  /// In en, this message translates to:
  /// **'This puzzle is about {theme}'**
  String themeHintAbout(String theme);

  /// No description provided for @themeHintWayOut.
  ///
  /// In en, this message translates to:
  /// **'The {theme} is your way out here'**
  String themeHintWayOut(String theme);

  /// No description provided for @themeHintThinking.
  ///
  /// In en, this message translates to:
  /// **'Try thinking in terms of {theme}'**
  String themeHintThinking(String theme);

  /// No description provided for @piecePawn.
  ///
  /// In en, this message translates to:
  /// **'pawn'**
  String get piecePawn;

  /// No description provided for @pieceKnight.
  ///
  /// In en, this message translates to:
  /// **'knight'**
  String get pieceKnight;

  /// No description provided for @pieceBishop.
  ///
  /// In en, this message translates to:
  /// **'bishop'**
  String get pieceBishop;

  /// No description provided for @pieceRook.
  ///
  /// In en, this message translates to:
  /// **'rook'**
  String get pieceRook;

  /// No description provided for @pieceQueen.
  ///
  /// In en, this message translates to:
  /// **'queen'**
  String get pieceQueen;

  /// No description provided for @pieceKing.
  ///
  /// In en, this message translates to:
  /// **'king'**
  String get pieceKing;

  /// No description provided for @pieceGeneric.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get pieceGeneric;

  /// No description provided for @mixedTacticsLabel.
  ///
  /// In en, this message translates to:
  /// **'mixed tactics'**
  String get mixedTacticsLabel;

  /// No description provided for @allDownloadedSolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'All downloaded puzzles solved — download more next time you are online.'**
  String get allDownloadedSolvedMessage;

  /// No description provided for @loadingNextPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Loading next puzzles...'**
  String get loadingNextPuzzles;

  /// No description provided for @noPuzzlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available.'**
  String get noPuzzlesAvailable;

  /// No description provided for @yourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating:'**
  String get yourRatingLabel;

  /// No description provided for @hintButton.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintButton;

  /// No description provided for @showThemeButton.
  ///
  /// In en, this message translates to:
  /// **'Show Theme'**
  String get showThemeButton;

  /// No description provided for @hintUsedButton.
  ///
  /// In en, this message translates to:
  /// **'Hint Used'**
  String get hintUsedButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @myPuzzleIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'You played {move} in this position, which was {classification}. Try to look for a better move.'**
  String myPuzzleIntroMessage(String move, String classification);

  /// No description provided for @notBestMoveTryAgain.
  ///
  /// In en, this message translates to:
  /// **'That is not the best move here. Try again and look for a stronger continuation.'**
  String get notBestMoveTryAgain;

  /// No description provided for @greatJobFoundBestMove.
  ///
  /// In en, this message translates to:
  /// **'Great job! You found the best move.'**
  String get greatJobFoundBestMove;

  /// No description provided for @myPuzzleHintPieceToMove.
  ///
  /// In en, this message translates to:
  /// **'Look at your {piece} on {square}. That is the piece you need to move.'**
  String myPuzzleHintPieceToMove(String piece, String square);

  /// No description provided for @allMyPuzzlesSolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'All puzzles solved — nice work!'**
  String get allMyPuzzlesSolvedMessage;

  /// No description provided for @noMyPuzzlesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available yet.\n\nFinish a game against Pippo — your mistakes will automatically become puzzles.'**
  String get noMyPuzzlesEmptyState;

  /// No description provided for @puzzleCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle {current} of {total}'**
  String puzzleCounterTitle(int current, int total);

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// No description provided for @nextPuzzleButton.
  ///
  /// In en, this message translates to:
  /// **'Next Puzzle'**
  String get nextPuzzleButton;

  /// No description provided for @allThemesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Themes'**
  String get allThemesTitle;

  /// No description provided for @allThemesIntro.
  ///
  /// In en, this message translates to:
  /// **'Practice all kinds of chess puzzles in one place. Pick a theme, test your skills, and see how well you can do across different parts of the game.'**
  String get allThemesIntro;

  /// No description provided for @themesNeedInternetOffline.
  ///
  /// In en, this message translates to:
  /// **'Themes need an internet connection to load a fresh batch. Your internet is offline right now.'**
  String get themesNeedInternetOffline;

  /// No description provided for @needsInternetForBatch.
  ///
  /// In en, this message translates to:
  /// **'Needs internet to load a fresh batch'**
  String get needsInternetForBatch;

  /// No description provided for @themeGroupMates.
  ///
  /// In en, this message translates to:
  /// **'Mates'**
  String get themeGroupMates;

  /// No description provided for @themeGroupTactics.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get themeGroupTactics;

  /// No description provided for @themeGroupKingAttack.
  ///
  /// In en, this message translates to:
  /// **'King Attack'**
  String get themeGroupKingAttack;

  /// No description provided for @themeGroupEndgames.
  ///
  /// In en, this message translates to:
  /// **'Endgames'**
  String get themeGroupEndgames;

  /// No description provided for @themeGroupPawnsPromotion.
  ///
  /// In en, this message translates to:
  /// **'Pawns & Promotion'**
  String get themeGroupPawnsPromotion;

  /// No description provided for @themeGroupStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get themeGroupStrategy;

  /// No description provided for @themeMateIn1.
  ///
  /// In en, this message translates to:
  /// **'Mate In 1'**
  String get themeMateIn1;

  /// No description provided for @themeMateIn1Desc.
  ///
  /// In en, this message translates to:
  /// **'Find the checkmate in a single move.'**
  String get themeMateIn1Desc;

  /// No description provided for @themeMateIn2.
  ///
  /// In en, this message translates to:
  /// **'Mate In 2'**
  String get themeMateIn2;

  /// No description provided for @themeMateIn2Desc.
  ///
  /// In en, this message translates to:
  /// **'Set up the position and finish with checkmate on your next move.'**
  String get themeMateIn2Desc;

  /// No description provided for @themeMateIn3.
  ///
  /// In en, this message translates to:
  /// **'Mate In 3'**
  String get themeMateIn3;

  /// No description provided for @themeMateIn3Desc.
  ///
  /// In en, this message translates to:
  /// **'Find the winning sequence that leads to checkmate in three moves.'**
  String get themeMateIn3Desc;

  /// No description provided for @themeMateIn4.
  ///
  /// In en, this message translates to:
  /// **'Mate In 4'**
  String get themeMateIn4;

  /// No description provided for @themeMateIn4Desc.
  ///
  /// In en, this message translates to:
  /// **'Plan a few moves ahead to force checkmate.'**
  String get themeMateIn4Desc;

  /// No description provided for @themeMateIn5.
  ///
  /// In en, this message translates to:
  /// **'Mate In 5'**
  String get themeMateIn5;

  /// No description provided for @themeMateIn5Desc.
  ///
  /// In en, this message translates to:
  /// **'A longer mating sequence where every move matters.'**
  String get themeMateIn5Desc;

  /// No description provided for @themeOtherMates.
  ///
  /// In en, this message translates to:
  /// **'Other Mates'**
  String get themeOtherMates;

  /// No description provided for @themeOtherMatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Special mating patterns like Back Rank, Smothered, Anastasia, Arabian, Boden, Opera, and more.'**
  String get themeOtherMatesDesc;

  /// No description provided for @themeFork.
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get themeFork;

  /// No description provided for @themeForkDesc.
  ///
  /// In en, this message translates to:
  /// **'One piece attacks two or more targets at once.'**
  String get themeForkDesc;

  /// No description provided for @themePin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get themePin;

  /// No description provided for @themePinDesc.
  ///
  /// In en, this message translates to:
  /// **'A piece is stuck because moving it would expose something more valuable.'**
  String get themePinDesc;

  /// No description provided for @themeSkewer.
  ///
  /// In en, this message translates to:
  /// **'Skewer'**
  String get themeSkewer;

  /// No description provided for @themeSkewerDesc.
  ///
  /// In en, this message translates to:
  /// **'Attack a valuable piece and win what is hiding behind it.'**
  String get themeSkewerDesc;

  /// No description provided for @themeDiscoveredAttack.
  ///
  /// In en, this message translates to:
  /// **'Discovered Attack'**
  String get themeDiscoveredAttack;

  /// No description provided for @themeDiscoveredAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Move one piece to uncover an attack from another.'**
  String get themeDiscoveredAttackDesc;

  /// No description provided for @themeDiscoveredCheck.
  ///
  /// In en, this message translates to:
  /// **'Discovered Check'**
  String get themeDiscoveredCheck;

  /// No description provided for @themeDiscoveredCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Uncover a check by moving another piece out of the way.'**
  String get themeDiscoveredCheckDesc;

  /// No description provided for @themeDoubleCheck.
  ///
  /// In en, this message translates to:
  /// **'Double Check'**
  String get themeDoubleCheck;

  /// No description provided for @themeDoubleCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Give check from two pieces at the same time.'**
  String get themeDoubleCheckDesc;

  /// No description provided for @themeSacrifice.
  ///
  /// In en, this message translates to:
  /// **'Sacrifice'**
  String get themeSacrifice;

  /// No description provided for @themeSacrificeDesc.
  ///
  /// In en, this message translates to:
  /// **'Give up material to gain something stronger in return.'**
  String get themeSacrificeDesc;

  /// No description provided for @themeDeflection.
  ///
  /// In en, this message translates to:
  /// **'Deflection'**
  String get themeDeflection;

  /// No description provided for @themeDeflectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Force a piece away from where it needs to be.'**
  String get themeDeflectionDesc;

  /// No description provided for @themeClearance.
  ///
  /// In en, this message translates to:
  /// **'Clearance'**
  String get themeClearance;

  /// No description provided for @themeClearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Move a piece away to open the way for another piece.'**
  String get themeClearanceDesc;

  /// No description provided for @themeCapturingDefender.
  ///
  /// In en, this message translates to:
  /// **'Capturing Defender'**
  String get themeCapturingDefender;

  /// No description provided for @themeCapturingDefenderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove the piece protecting an important target.'**
  String get themeCapturingDefenderDesc;

  /// No description provided for @themeAdvancedTactics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Tactics'**
  String get themeAdvancedTactics;

  /// No description provided for @themeAdvancedTacticsDesc.
  ///
  /// In en, this message translates to:
  /// **'More difficult combinations involving several tactical ideas.'**
  String get themeAdvancedTacticsDesc;

  /// No description provided for @themeKingsideAttack.
  ///
  /// In en, this message translates to:
  /// **'Kingside Attack'**
  String get themeKingsideAttack;

  /// No description provided for @themeKingsideAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Build an attack against the king on the kingside.'**
  String get themeKingsideAttackDesc;

  /// No description provided for @themeQueensideAttack.
  ///
  /// In en, this message translates to:
  /// **'Queenside Attack'**
  String get themeQueensideAttack;

  /// No description provided for @themeQueensideAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Look for ways to break through around the enemy king on the queenside.'**
  String get themeQueensideAttackDesc;

  /// No description provided for @themeExposedKing.
  ///
  /// In en, this message translates to:
  /// **'Exposed King'**
  String get themeExposedKing;

  /// No description provided for @themeExposedKingDesc.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of a king that has lost its protection.'**
  String get themeExposedKingDesc;

  /// No description provided for @themeAttackingF2F7.
  ///
  /// In en, this message translates to:
  /// **'Attacking F2 F7'**
  String get themeAttackingF2F7;

  /// No description provided for @themeAttackingF2F7Desc.
  ///
  /// In en, this message translates to:
  /// **'Target the weak f2 or f7 square near the king.'**
  String get themeAttackingF2F7Desc;

  /// No description provided for @themeEndgame.
  ///
  /// In en, this message translates to:
  /// **'Endgame'**
  String get themeEndgame;

  /// No description provided for @themeEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the best way to play when only a few pieces remain.'**
  String get themeEndgameDesc;

  /// No description provided for @themeRookEndgame.
  ///
  /// In en, this message translates to:
  /// **'Rook Endgame'**
  String get themeRookEndgame;

  /// No description provided for @themeRookEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn to make the most of your rooks in the endgame.'**
  String get themeRookEndgameDesc;

  /// No description provided for @themeQueenEndgame.
  ///
  /// In en, this message translates to:
  /// **'Queen Endgame'**
  String get themeQueenEndgame;

  /// No description provided for @themeQueenEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the right moves in positions where queens remain on the board.'**
  String get themeQueenEndgameDesc;

  /// No description provided for @themeQueenRookEndgame.
  ///
  /// In en, this message translates to:
  /// **'Queen Rook Endgame'**
  String get themeQueenRookEndgame;

  /// No description provided for @themeQueenRookEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Handle endgames where queens and rooks are still in play.'**
  String get themeQueenRookEndgameDesc;

  /// No description provided for @themeBishopEndgame.
  ///
  /// In en, this message translates to:
  /// **'Bishop Endgame'**
  String get themeBishopEndgame;

  /// No description provided for @themeBishopEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your bishop and king to find the winning plan.'**
  String get themeBishopEndgameDesc;

  /// No description provided for @themeKnightEndgame.
  ///
  /// In en, this message translates to:
  /// **'Knight Endgame'**
  String get themeKnightEndgame;

  /// No description provided for @themeKnightEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the right moves in endgames where knights matter most.'**
  String get themeKnightEndgameDesc;

  /// No description provided for @themePawnEndgame.
  ///
  /// In en, this message translates to:
  /// **'Pawn Endgame'**
  String get themePawnEndgame;

  /// No description provided for @themePawnEndgameDesc.
  ///
  /// In en, this message translates to:
  /// **'Calculate pawn races and find the path to victory.'**
  String get themePawnEndgameDesc;

  /// No description provided for @themeZugzwang.
  ///
  /// In en, this message translates to:
  /// **'Zugzwang'**
  String get themeZugzwang;

  /// No description provided for @themeZugzwangDesc.
  ///
  /// In en, this message translates to:
  /// **'Put your opponent in a position where any move makes things worse.'**
  String get themeZugzwangDesc;

  /// No description provided for @themeAdvancedPawn.
  ///
  /// In en, this message translates to:
  /// **'Advanced Pawn'**
  String get themeAdvancedPawn;

  /// No description provided for @themeAdvancedPawnDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a dangerous pawn that has pushed deep into enemy territory.'**
  String get themeAdvancedPawnDesc;

  /// No description provided for @themePromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get themePromotion;

  /// No description provided for @themePromotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Push a pawn through to become a stronger piece.'**
  String get themePromotionDesc;

  /// No description provided for @themeUnderPromotion.
  ///
  /// In en, this message translates to:
  /// **'Under Promotion'**
  String get themeUnderPromotion;

  /// No description provided for @themeUnderPromotionDesc.
  ///
  /// In en, this message translates to:
  /// **'Promote to something other than a queen when that\'s the winning move.'**
  String get themeUnderPromotionDesc;

  /// No description provided for @themeEnPassant.
  ///
  /// In en, this message translates to:
  /// **'En Passant'**
  String get themeEnPassant;

  /// No description provided for @themeEnPassantDesc.
  ///
  /// In en, this message translates to:
  /// **'Spot the rare chance to capture a pawn using en passant.'**
  String get themeEnPassantDesc;

  /// No description provided for @themeQuietMove.
  ///
  /// In en, this message translates to:
  /// **'Quiet Move'**
  String get themeQuietMove;

  /// No description provided for @themeQuietMoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Find a calm move that creates a strong advantage without forcing tactics.'**
  String get themeQuietMoveDesc;

  /// No description provided for @themeDefensiveMove.
  ///
  /// In en, this message translates to:
  /// **'Defensive Move'**
  String get themeDefensiveMove;

  /// No description provided for @themeDefensiveMoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the move that stops your opponent\'s threat.'**
  String get themeDefensiveMoveDesc;

  /// No description provided for @themeAdvantage.
  ///
  /// In en, this message translates to:
  /// **'Advantage'**
  String get themeAdvantage;

  /// No description provided for @themeAdvantageDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the move that keeps or increases your advantage.'**
  String get themeAdvantageDesc;

  /// No description provided for @themeEquality.
  ///
  /// In en, this message translates to:
  /// **'Equality'**
  String get themeEquality;

  /// No description provided for @themeEqualityDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the move that keeps the position balanced.'**
  String get themeEqualityDesc;

  /// No description provided for @themeCrushing.
  ///
  /// In en, this message translates to:
  /// **'Crushing'**
  String get themeCrushing;

  /// No description provided for @themeCrushingDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the powerful move that turns a strong position into a winning one.'**
  String get themeCrushingDesc;

  /// No description provided for @pippoThinking2.
  ///
  /// In en, this message translates to:
  /// **'Let me look for the best move'**
  String get pippoThinking2;

  /// No description provided for @pippoThinking3.
  ///
  /// In en, this message translates to:
  /// **'One moment... I see a few ideas'**
  String get pippoThinking3;

  /// No description provided for @pippoThinking4.
  ///
  /// In en, this message translates to:
  /// **'Calculating my reply'**
  String get pippoThinking4;

  /// No description provided for @pippoThreatAsk1.
  ///
  /// In en, this message translates to:
  /// **'Can you spot what this move is threatening?'**
  String get pippoThreatAsk1;

  /// No description provided for @pippoThreatAsk2.
  ///
  /// In en, this message translates to:
  /// **'I have a little idea behind that move...'**
  String get pippoThreatAsk2;

  /// No description provided for @pippoThreatAsk3.
  ///
  /// In en, this message translates to:
  /// **'Watch out — that move puts something under pressure.'**
  String get pippoThreatAsk3;

  /// No description provided for @pippoThreatAsk4.
  ///
  /// In en, this message translates to:
  /// **'There may be more to that move than meets the eye.'**
  String get pippoThreatAsk4;

  /// No description provided for @pippoGreat1.
  ///
  /// In en, this message translates to:
  /// **'Great job finding the only move in this position!'**
  String get pippoGreat1;

  /// No description provided for @pippoGreat2.
  ///
  /// In en, this message translates to:
  /// **'That was a great move — very well spotted.'**
  String get pippoGreat2;

  /// No description provided for @pippoGreat3.
  ///
  /// In en, this message translates to:
  /// **'Excellent find. You handled that position beautifully.'**
  String get pippoGreat3;

  /// No description provided for @pippoBrilliant1.
  ///
  /// In en, this message translates to:
  /// **'Brilliant! That move was wonderfully precise.'**
  String get pippoBrilliant1;

  /// No description provided for @pippoBrilliant2.
  ///
  /// In en, this message translates to:
  /// **'What a brilliant idea — I did not expect that one.'**
  String get pippoBrilliant2;

  /// No description provided for @pippoBrilliant3.
  ///
  /// In en, this message translates to:
  /// **'That was brilliant. You found a seriously creative move.'**
  String get pippoBrilliant3;

  /// No description provided for @pippoFinished1.
  ///
  /// In en, this message translates to:
  /// **'That was a great game! Want to play again?'**
  String get pippoFinished1;

  /// No description provided for @pippoFinished2.
  ///
  /// In en, this message translates to:
  /// **'Well played! Fancy another game?'**
  String get pippoFinished2;

  /// No description provided for @pippoFinished3.
  ///
  /// In en, this message translates to:
  /// **'Good game — I enjoyed that one. Rematch?'**
  String get pippoFinished3;

  /// No description provided for @classificationBookComment.
  ///
  /// In en, this message translates to:
  /// **'A move from the opening book.'**
  String get classificationBookComment;

  /// No description provided for @resignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign Game?'**
  String get resignDialogTitle;

  /// No description provided for @resignDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resign? This will end the current game.'**
  String get resignDialogBody;

  /// No description provided for @resignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignConfirm;

  /// No description provided for @gameOverResignBlack.
  ///
  /// In en, this message translates to:
  /// **'Black wins by resignation'**
  String get gameOverResignBlack;

  /// No description provided for @gameOverResignWhite.
  ///
  /// In en, this message translates to:
  /// **'White wins by resignation'**
  String get gameOverResignWhite;

  /// No description provided for @gameOverDefault.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOverDefault;

  /// No description provided for @gameOverMateBlack.
  ///
  /// In en, this message translates to:
  /// **'Black wins by Checkmate'**
  String get gameOverMateBlack;

  /// No description provided for @gameOverMateWhite.
  ///
  /// In en, this message translates to:
  /// **'White wins by Checkmate'**
  String get gameOverMateWhite;

  /// No description provided for @gameOverStalemate.
  ///
  /// In en, this message translates to:
  /// **'Draw by Stalemate'**
  String get gameOverStalemate;

  /// No description provided for @gameOverRepetition.
  ///
  /// In en, this message translates to:
  /// **'Draw by Repetition'**
  String get gameOverRepetition;

  /// No description provided for @gameOverInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Draw by Insufficient Material'**
  String get gameOverInsufficient;

  /// No description provided for @gameOverDrawn.
  ///
  /// In en, this message translates to:
  /// **'Game Drawn'**
  String get gameOverDrawn;

  /// No description provided for @playStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Start a game first'**
  String get playStartFirst;

  /// No description provided for @takebackTrainingOnly.
  ///
  /// In en, this message translates to:
  /// **'Takebacks are only available in Training mode'**
  String get takebackTrainingOnly;

  /// No description provided for @takebackNoMoves.
  ///
  /// In en, this message translates to:
  /// **'No moves to take back'**
  String get takebackNoMoves;

  /// No description provided for @takebackDone.
  ///
  /// In en, this message translates to:
  /// **'Move taken back'**
  String get takebackDone;

  /// No description provided for @pippoMissBare.
  ///
  /// In en, this message translates to:
  /// **'You missed a better move in this position.'**
  String get pippoMissBare;

  /// No description provided for @pippoMissWithMove.
  ///
  /// In en, this message translates to:
  /// **'You missed a better move in this position, you should have gone {move}.'**
  String pippoMissWithMove(String move);

  /// No description provided for @pippoBlunderPause.
  ///
  /// In en, this message translates to:
  /// **'That move was a blunder. Take it back, or continue and I will play on.'**
  String get pippoBlunderPause;

  /// No description provided for @hintTrainingOnly.
  ///
  /// In en, this message translates to:
  /// **'Hints are only available in Training mode'**
  String get hintTrainingOnly;

  /// No description provided for @hintYourTurnOnly.
  ///
  /// In en, this message translates to:
  /// **'Hints are only available on your turn'**
  String get hintYourTurnOnly;

  /// No description provided for @hintStillAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Still analyzing... try again in a moment'**
  String get hintStillAnalyzing;

  /// No description provided for @hintLookForPiece.
  ///
  /// In en, this message translates to:
  /// **'Look for a good move with your {piece} on {square}.'**
  String hintLookForPiece(String piece, String square);

  /// No description provided for @playToolTakeback.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get playToolTakeback;

  /// No description provided for @playToolAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Pippo for a hint'**
  String get playToolAskHint;

  /// No description provided for @playToolClassifyHeader.
  ///
  /// In en, this message translates to:
  /// **'Classify'**
  String get playToolClassifyHeader;

  /// No description provided for @classifyYourMoves.
  ///
  /// In en, this message translates to:
  /// **'Your moves'**
  String get classifyYourMoves;

  /// No description provided for @classifyPippoMoves.
  ///
  /// In en, this message translates to:
  /// **'Pippo\'s moves'**
  String get classifyPippoMoves;

  /// No description provided for @playingPippoTitle.
  ///
  /// In en, this message translates to:
  /// **'Playing Pippo'**
  String get playingPippoTitle;

  /// No description provided for @resignButton.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignButton;

  /// No description provided for @playAsHeader.
  ///
  /// In en, this message translates to:
  /// **'PLAY AS'**
  String get playAsHeader;

  /// No description provided for @sideRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get sideRandom;

  /// No description provided for @strengthHeader.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get strengthHeader;

  /// No description provided for @optionsHeader.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get optionsHeader;

  /// No description provided for @modeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get modeLabel;

  /// No description provided for @modeChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get modeChallenge;

  /// No description provided for @modeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get modeTraining;

  /// No description provided for @startGameButton.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGameButton;

  /// No description provided for @perkFeedback.
  ///
  /// In en, this message translates to:
  /// **'Get feedback on your moves'**
  String get perkFeedback;

  /// No description provided for @perkSeeThreats.
  ///
  /// In en, this message translates to:
  /// **'See all threats'**
  String get perkSeeThreats;

  /// No description provided for @perkTakeback.
  ///
  /// In en, this message translates to:
  /// **'Takeback moves whenever you want'**
  String get perkTakeback;

  /// No description provided for @perkBlunderPause.
  ///
  /// In en, this message translates to:
  /// **'Pauses game when you make a blunder'**
  String get perkBlunderPause;

  /// No description provided for @perkHintsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Hints allowed'**
  String get perkHintsAllowed;

  /// No description provided for @perkNoFeedback.
  ///
  /// In en, this message translates to:
  /// **'No move feedback'**
  String get perkNoFeedback;

  /// No description provided for @perkHiddenThreats.
  ///
  /// In en, this message translates to:
  /// **'Threats stay hidden'**
  String get perkHiddenThreats;

  /// No description provided for @perkNoTakebacks.
  ///
  /// In en, this message translates to:
  /// **'No takebacks'**
  String get perkNoTakebacks;

  /// No description provided for @perkNoBlunderPause.
  ///
  /// In en, this message translates to:
  /// **'Game keeps going after blunders'**
  String get perkNoBlunderPause;

  /// No description provided for @perkNoHints.
  ///
  /// In en, this message translates to:
  /// **'No hints'**
  String get perkNoHints;

  /// No description provided for @pippoEloLabel.
  ///
  /// In en, this message translates to:
  /// **'{elo} ELO'**
  String pippoEloLabel(int elo);

  /// No description provided for @hideThreats.
  ///
  /// In en, this message translates to:
  /// **'Hide threats'**
  String get hideThreats;

  /// No description provided for @showThreat.
  ///
  /// In en, this message translates to:
  /// **'Show threat'**
  String get showThreat;

  /// No description provided for @blunderContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get blunderContinue;

  /// No description provided for @gameOverFallback.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOverFallback;

  /// No description provided for @resultHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get resultHome;

  /// No description provided for @resultNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get resultNewGame;

  /// No description provided for @resultAnalyzeGame.
  ///
  /// In en, this message translates to:
  /// **'Analyze game'**
  String get resultAnalyzeGame;

  /// No description provided for @gameToolsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Game tools'**
  String get gameToolsTooltip;

  /// No description provided for @movesHeader.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get movesHeader;

  /// No description provided for @moveCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String moveCountLabel(int count);

  /// No description provided for @movesEmptyPlay.
  ///
  /// In en, this message translates to:
  /// **'Your moves will appear here as the game unfolds.'**
  String get movesEmptyPlay;

  /// No description provided for @puzzleNotBest.
  ///
  /// In en, this message translates to:
  /// **'Not the best move. Try again!'**
  String get puzzleNotBest;

  /// No description provided for @puzzleSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Practice session complete!'**
  String get puzzleSessionComplete;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTitle;

  /// No description provided for @puzzleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available.'**
  String get puzzleEmpty;

  /// No description provided for @puzzleCounter.
  ///
  /// In en, this message translates to:
  /// **'Puzzle {current}/{total}'**
  String puzzleCounter(int current, int total);

  /// No description provided for @puzzleHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get puzzleHint;

  /// No description provided for @puzzleShowMove.
  ///
  /// In en, this message translates to:
  /// **'Show Move'**
  String get puzzleShowMove;

  /// No description provided for @puzzleUsedHint.
  ///
  /// In en, this message translates to:
  /// **'Used Hint'**
  String get puzzleUsedHint;

  /// No description provided for @puzzleNext.
  ///
  /// In en, this message translates to:
  /// **'Next Puzzle'**
  String get puzzleNext;

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysisTitle;

  /// No description provided for @addGameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add game or position'**
  String get addGameTooltip;

  /// No description provided for @closeGameButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeGameButton;

  /// No description provided for @positionLoadedOk.
  ///
  /// In en, this message translates to:
  /// **'Position loaded successfully'**
  String get positionLoadedOk;

  /// No description provided for @gameImportedOk.
  ///
  /// In en, this message translates to:
  /// **'Game imported successfully'**
  String get gameImportedOk;

  /// No description provided for @savedEventTitle.
  ///
  /// In en, this message translates to:
  /// **'AtlasChess vs {opponent}'**
  String savedEventTitle(String opponent);

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @explorerGameLoaded.
  ///
  /// In en, this message translates to:
  /// **'{white} vs {black} loaded'**
  String explorerGameLoaded(String white, String black);

  /// No description provided for @reviewNoGame.
  ///
  /// In en, this message translates to:
  /// **'No game to review'**
  String get reviewNoGame;

  /// No description provided for @reviewQuotaUsed.
  ///
  /// In en, this message translates to:
  /// **'You have used today\'s game reviews. Upgrade to Pro for more.'**
  String get reviewQuotaUsed;

  /// No description provided for @analysisNoMoves.
  ///
  /// In en, this message translates to:
  /// **'No moves to analyze'**
  String get analysisNoMoves;

  /// No description provided for @settingsEngineHeader.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get settingsEngineHeader;

  /// No description provided for @settingsEnableEngine.
  ///
  /// In en, this message translates to:
  /// **'Enable Engine'**
  String get settingsEnableEngine;

  /// No description provided for @settingsDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get settingsDepth;

  /// No description provided for @settingsClassificationHeader.
  ///
  /// In en, this message translates to:
  /// **'Move Classification'**
  String get settingsClassificationHeader;

  /// No description provided for @settingsEnableClassification.
  ///
  /// In en, this message translates to:
  /// **'Enable Classification'**
  String get settingsEnableClassification;

  /// No description provided for @settingsThreatHeader.
  ///
  /// In en, this message translates to:
  /// **'Threat Detector'**
  String get settingsThreatHeader;

  /// No description provided for @settingsThreatToggle.
  ///
  /// In en, this message translates to:
  /// **'Threat detector'**
  String get settingsThreatToggle;

  /// No description provided for @settingsLinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Lines (PV)'**
  String get settingsLinesLabel;

  /// No description provided for @filterBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get filterBook;

  /// No description provided for @filterBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get filterBrilliant;

  /// No description provided for @filterBlunder.
  ///
  /// In en, this message translates to:
  /// **'Blunder'**
  String get filterBlunder;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @analyzingBanner.
  ///
  /// In en, this message translates to:
  /// **'Your game is being analyzed, you can leave this screen'**
  String get analyzingBanner;

  /// No description provided for @fullViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Full view'**
  String get fullViewTooltip;

  /// No description provided for @compactViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get compactViewTooltip;

  /// No description provided for @classifyingMove.
  ///
  /// In en, this message translates to:
  /// **'Classifying move...'**
  String get classifyingMove;

  /// No description provided for @phraseBest.
  ///
  /// In en, this message translates to:
  /// **'the best move'**
  String get phraseBest;

  /// No description provided for @phraseBrilliant.
  ///
  /// In en, this message translates to:
  /// **'a brilliant move'**
  String get phraseBrilliant;

  /// No description provided for @phraseGreat.
  ///
  /// In en, this message translates to:
  /// **'a great move'**
  String get phraseGreat;

  /// No description provided for @phraseExcellent.
  ///
  /// In en, this message translates to:
  /// **'an excellent move'**
  String get phraseExcellent;

  /// No description provided for @phraseGood.
  ///
  /// In en, this message translates to:
  /// **'a good move'**
  String get phraseGood;

  /// No description provided for @phraseInaccuracy.
  ///
  /// In en, this message translates to:
  /// **'an inaccuracy'**
  String get phraseInaccuracy;

  /// No description provided for @phraseMistake.
  ///
  /// In en, this message translates to:
  /// **'a mistake'**
  String get phraseMistake;

  /// No description provided for @phraseBlunder.
  ///
  /// In en, this message translates to:
  /// **'a blunder'**
  String get phraseBlunder;

  /// No description provided for @phraseMiss.
  ///
  /// In en, this message translates to:
  /// **'a miss'**
  String get phraseMiss;

  /// No description provided for @phraseBook.
  ///
  /// In en, this message translates to:
  /// **'a book move'**
  String get phraseBook;

  /// No description provided for @phraseForced.
  ///
  /// In en, this message translates to:
  /// **'a forced move'**
  String get phraseForced;

  /// No description provided for @sentenceBestSuffix.
  ///
  /// In en, this message translates to:
  /// **', {move} was the best move'**
  String sentenceBestSuffix(String move);

  /// No description provided for @retryReview.
  ///
  /// In en, this message translates to:
  /// **'Retry review'**
  String get retryReview;

  /// No description provided for @reviewWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your game is being reviewed'**
  String get reviewWaiting;

  /// No description provided for @pgnEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moves yet'**
  String get pgnEmpty;

  /// No description provided for @pgnResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pgnResume;

  /// No description provided for @showBestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show best move'**
  String get showBestTooltip;

  /// No description provided for @tabMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get tabMoves;

  /// No description provided for @tabExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get tabExplorer;

  /// No description provided for @moveTreeHeader.
  ///
  /// In en, this message translates to:
  /// **'Move tree'**
  String get moveTreeHeader;

  /// No description provided for @moveTreeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your moves and variations will appear here.'**
  String get moveTreeEmpty;

  /// No description provided for @gameReportButton.
  ///
  /// In en, this message translates to:
  /// **'Game report'**
  String get gameReportButton;

  /// No description provided for @gameAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Analysis'**
  String get gameAnalysisTitle;

  /// No description provided for @analyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeButton;

  /// No description provided for @viewReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get viewReportTooltip;

  /// No description provided for @noReportYet.
  ///
  /// In en, this message translates to:
  /// **'No Report Generated yet'**
  String get noReportYet;

  /// No description provided for @addToAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to analysis'**
  String get addToAnalysisTitle;

  /// No description provided for @addToAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start from a game, a position, or a custom board.'**
  String get addToAnalysisSubtitle;

  /// No description provided for @importSegment.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importSegment;

  /// No description provided for @fenSegment.
  ///
  /// In en, this message translates to:
  /// **'FEN'**
  String get fenSegment;

  /// No description provided for @setupButton.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupButton;

  /// No description provided for @gameReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Report'**
  String get gameReportTitle;

  /// No description provided for @accuraciesHeader.
  ///
  /// In en, this message translates to:
  /// **'Accuracies'**
  String get accuraciesHeader;

  /// No description provided for @accuracyRerunHint.
  ///
  /// In en, this message translates to:
  /// **'Re-run full-game analysis to compute accuracies.'**
  String get accuracyRerunHint;

  /// No description provided for @pastePgnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste PGN'**
  String get pastePgnTooltip;

  /// No description provided for @pastePgnButton.
  ///
  /// In en, this message translates to:
  /// **'Paste copied PGN'**
  String get pastePgnButton;

  /// No description provided for @searchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingLabel;

  /// No description provided for @importingLabel.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importingLabel;

  /// No description provided for @searchGamesButton.
  ///
  /// In en, this message translates to:
  /// **'Search Games'**
  String get searchGamesButton;

  /// No description provided for @startAnalysisButton.
  ///
  /// In en, this message translates to:
  /// **'Start Analysis'**
  String get startAnalysisButton;

  /// No description provided for @fenFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Board Position (FEN)'**
  String get fenFieldLabel;

  /// No description provided for @pasteFenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste FEN'**
  String get pasteFenTooltip;

  /// No description provided for @pasteFenButton.
  ///
  /// In en, this message translates to:
  /// **'Paste copied FEN'**
  String get pasteFenButton;

  /// No description provided for @loadPositionButton.
  ///
  /// In en, this message translates to:
  /// **'Load Position'**
  String get loadPositionButton;

  /// No description provided for @inputPgnText.
  ///
  /// In en, this message translates to:
  /// **'PGN Text'**
  String get inputPgnText;

  /// No description provided for @inputUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get inputUsername;

  /// No description provided for @inputGameUrl.
  ///
  /// In en, this message translates to:
  /// **'Game URL'**
  String get inputGameUrl;

  /// No description provided for @hintPastePgn.
  ///
  /// In en, this message translates to:
  /// **'Paste PGN here...'**
  String get hintPastePgn;

  /// No description provided for @hintEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username...'**
  String get hintEnterUsername;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @lichessSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Lichess sign-in cancelled'**
  String get lichessSignInCancelled;

  /// No description provided for @boardSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Board Setup'**
  String get boardSetupTitle;

  /// No description provided for @flipBoardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Flip board'**
  String get flipBoardTooltip;

  /// No description provided for @clearBoardButton.
  ///
  /// In en, this message translates to:
  /// **'Clear board'**
  String get clearBoardButton;

  /// No description provided for @startPositionButton.
  ///
  /// In en, this message translates to:
  /// **'Start position'**
  String get startPositionButton;

  /// No description provided for @whoMovesHeader.
  ///
  /// In en, this message translates to:
  /// **'WHO MOVES FIRST'**
  String get whoMovesHeader;

  /// No description provided for @piecesHeader.
  ///
  /// In en, this message translates to:
  /// **'PIECES'**
  String get piecesHeader;

  /// No description provided for @setupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap a piece to select it, then tap the board to place it. Drag a piece onto the board to add it, or drag it off the board to remove it.'**
  String get setupInstructions;

  /// No description provided for @fenHeader.
  ///
  /// In en, this message translates to:
  /// **'FEN'**
  String get fenHeader;

  /// No description provided for @setupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get setupFinish;

  /// No description provided for @engineDepthLabel.
  ///
  /// In en, this message translates to:
  /// **'Depth {depth}'**
  String engineDepthLabel(int depth);

  /// No description provided for @analyzeGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze Game'**
  String get analyzeGameTitle;

  /// No description provided for @reviewsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited game reviews available today'**
  String get reviewsUnlimited;

  /// No description provided for @reviewsLeftToday.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} game reviews available today'**
  String reviewsLeftToday(int done, int total);

  /// No description provided for @analyzeTypeHeader.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get analyzeTypeHeader;

  /// No description provided for @analyzeModeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analyzeModeAnalysis;

  /// No description provided for @analyzeModeAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Classifies all moves of your game using Stockfish'**
  String get analyzeModeAnalysisDesc;

  /// No description provided for @analyzeModeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get analyzeModeReview;

  /// No description provided for @upgradeToProTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToProTitle;

  /// No description provided for @reviewModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Move-by-move explanations of your game'**
  String get reviewModeDesc;

  /// No description provided for @reviewLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock more game reviews every day'**
  String get reviewLockedDesc;

  /// No description provided for @engineDepthHeader.
  ///
  /// In en, this message translates to:
  /// **'Engine Depth'**
  String get engineDepthHeader;

  /// No description provided for @depthValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Depth {depth}'**
  String depthValueLabel(int depth);

  /// No description provided for @depthHint.
  ///
  /// In en, this message translates to:
  /// **'Higher depth can take more time to analyze'**
  String get depthHint;

  /// No description provided for @selectGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Game'**
  String get selectGameTitle;

  /// No description provided for @versusShort.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get versusShort;

  /// No description provided for @speedBullet.
  ///
  /// In en, this message translates to:
  /// **'Bullet'**
  String get speedBullet;

  /// No description provided for @speedBlitz.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get speedBlitz;

  /// No description provided for @speedRapid.
  ///
  /// In en, this message translates to:
  /// **'Rapid'**
  String get speedRapid;

  /// No description provided for @speedClassical.
  ///
  /// In en, this message translates to:
  /// **'Classical'**
  String get speedClassical;

  /// No description provided for @openingExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening Explorer'**
  String get openingExplorerTitle;

  /// No description provided for @dbMasters.
  ///
  /// In en, this message translates to:
  /// **'Masters'**
  String get dbMasters;

  /// No description provided for @filtersHeader.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersHeader;

  /// No description provided for @theoreticalMoves.
  ///
  /// In en, this message translates to:
  /// **'Theoretical Moves'**
  String get theoreticalMoves;

  /// No description provided for @topMasterGames.
  ///
  /// In en, this message translates to:
  /// **'Top Master Games'**
  String get topMasterGames;

  /// No description provided for @recentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent Games'**
  String get recentGames;

  /// No description provided for @explorerSignInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Lichess to explore millions of games, top master games and opening statistics.'**
  String get explorerSignInDesc;

  /// No description provided for @signInWithLichess.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Lichess'**
  String get signInWithLichess;

  /// No description provided for @noOpeningData.
  ///
  /// In en, this message translates to:
  /// **'No opening data available'**
  String get noOpeningData;

  /// No description provided for @gamesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} games'**
  String gamesCountLabel(int count);

  /// No description provided for @unknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownPlayer;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @indicatorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get indicatorGreen;

  /// No description provided for @indicatorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get indicatorAmber;

  /// No description provided for @indicatorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get indicatorRed;

  /// No description provided for @clsBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get clsBest;

  /// No description provided for @clsBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get clsBrilliant;

  /// No description provided for @clsGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get clsGreat;

  /// No description provided for @clsExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get clsExcellent;

  /// No description provided for @clsGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get clsGood;

  /// No description provided for @clsInaccuracy.
  ///
  /// In en, this message translates to:
  /// **'Inaccuracy'**
  String get clsInaccuracy;

  /// No description provided for @clsMistake.
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get clsMistake;

  /// No description provided for @clsBlunder.
  ///
  /// In en, this message translates to:
  /// **'Blunder'**
  String get clsBlunder;

  /// No description provided for @clsBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get clsBook;

  /// No description provided for @clsForced.
  ///
  /// In en, this message translates to:
  /// **'Forced'**
  String get clsForced;

  /// No description provided for @clsMiss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get clsMiss;

  /// No description provided for @averageRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg. {rating}'**
  String averageRatingLabel(int rating);

  /// No description provided for @classificationSentence.
  ///
  /// In en, this message translates to:
  /// **'{move} is {label}'**
  String classificationSentence(String move, String label);

  /// No description provided for @reviewBestHint.
  ///
  /// In en, this message translates to:
  /// **'{explanation} {move} was the best move.'**
  String reviewBestHint(String explanation, String move);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'hi',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
