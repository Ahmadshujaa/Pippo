// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'Jugador';

  @override
  String get notSignedIn => 'Sesión no iniciada';

  @override
  String get planAdmin => 'ADMIN';

  @override
  String get planPro => 'MIEMBRO PRO';

  @override
  String get planFree => 'MIEMBRO FREE';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appSettingsSection => 'Ajustes de la aplicación';

  @override
  String get supportSection => 'Soporte';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceSubtitle => 'Tema claro, oscuro o del sistema';

  @override
  String get subscriptionTitle => 'Suscripción';

  @override
  String get subscriptionSubtitle => 'Gestiona tu plan Atlas Pro';

  @override
  String get languageTitle => 'Idioma';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'Ayuda y soporte';

  @override
  String get helpSubtitle => 'Preguntas frecuentes y atención al cliente';

  @override
  String get contactSupportTitle => 'Contactar con soporte';

  @override
  String get contactSupportSubtitle => 'Contacta con el equipo de soporte';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get chooseTheme => 'Elegir tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get editDisplayName => 'Editar nombre visible';

  @override
  String displayNameRule(int maxLength) {
    return 'Elige un nombre de hasta $maxLength caracteres.';
  }

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get save => 'Guardar';

  @override
  String get languageSheetTitle => 'Elegir idioma';

  @override
  String get systemLanguage => 'Predeterminado del sistema';

  @override
  String get supportTypeLabel => 'Tipo de problema';

  @override
  String get supportTypeHint =>
      'Elige la opción que mejor describa tu problema.';

  @override
  String get supportTypeUi => 'Interfaz';

  @override
  String get supportTypeError => 'Error';

  @override
  String get supportTypeOther => 'Otro';

  @override
  String get supportSubjectLabel => 'Asunto';

  @override
  String get supportSubjectHint => 'Breve descripción de tu problema';

  @override
  String get supportMessageLabel => 'Mensaje';

  @override
  String get supportMessageHint => 'Describe tu problema en detalle...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max caracteres';
  }

  @override
  String get supportSubmitButton => 'Enviar ticket';

  @override
  String get supportSuccessTitle => '¡Ticket enviado!';

  @override
  String get supportSuccessBody => 'Responderemos a tu correo en 24-48 horas.';

  @override
  String get supportSuccessDone => 'Listo';

  @override
  String get supportSignInTitle => 'Inicia sesión para contactar con soporte';

  @override
  String get supportSignInBody =>
      'Los tickets se vinculan a tu cuenta para poder responderte. Inicia sesión e inténtalo de nuevo.';

  @override
  String get supportOfflineNotice =>
      'Estás sin conexión. Vuelve a conectarte para enviar tu ticket.';

  @override
  String get supportErrTypeRequired => 'Elige el tipo de problema.';

  @override
  String get supportErrSubjectRequired => 'Introduce un asunto.';

  @override
  String get supportErrMessageRequired => 'Introduce un mensaje.';

  @override
  String get supportErrSubjectTooLong => 'Tu asunto es demasiado largo.';

  @override
  String get supportErrMessageTooLong => 'Tu mensaje es demasiado largo.';

  @override
  String get supportErrGeneric =>
      'No se pudo enviar tu ticket. Inténtalo de nuevo.';

  @override
  String get offlineBannerTitle => 'Sin conexión a Internet';

  @override
  String get retry => 'Reintentar';

  @override
  String get boardSettingsTitle => 'Ajustes del tablero';

  @override
  String get pieceSetLabel => 'Juego de piezas';

  @override
  String get boardThemeLabel => 'Tema del tablero';

  @override
  String get moveIndicatorLabel => 'Indicador de jugadas';

  @override
  String get showCoordinatesLabel => 'Mostrar coordenadas';

  @override
  String get dragAndDropLabel => 'Arrastrar y soltar';

  @override
  String get soundLabel => 'Sonido';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get editExplanationTitle => 'Editar explicación';

  @override
  String get writeExplanationHint => 'Escribe la explicación...';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get boardThemeEmerald => 'Esmeralda';

  @override
  String get boardThemeMidnight => 'Medianoche';

  @override
  String get boardThemePurple => 'Morado';

  @override
  String get boardThemeSand => 'Arena';

  @override
  String get boardThemeBlue => 'Azul';

  @override
  String get boardThemeBrown => 'Marrón';

  @override
  String get quotaUpgradeCta => 'Pásate a Pro para resolver puzles ilimitados';

  @override
  String get downloadButton => 'Descargar';

  @override
  String get upgradeNow => 'Mejorar ahora';

  @override
  String get offlineDownloadsProNotice =>
      'Las descargas de puzles sin conexión están disponibles con Pro. Mejora tu plan para guardar puzles en este dispositivo.';

  @override
  String get savedForOffline =>
      'Guardado en este dispositivo para resolver sin conexión';

  @override
  String get downloadPuzzlesTitle => 'Descargar puzles';

  @override
  String get puzzleDecksTitle => 'Barajas de puzles';

  @override
  String get deckRecentMistakes => 'Errores recientes';

  @override
  String get deckRecentMistakesSubtitle => 'Tácticas de tus partidas perdidas';

  @override
  String get deckMatingPatterns => 'Patrones de mate';

  @override
  String get deckMatingPatternsSubtitle => 'Domina los mates de final';

  @override
  String get deckOpeningTraps => 'Trampas de apertura';

  @override
  String get deckOpeningTrapsSubtitle => 'Trucos comunes en tu repertorio';

  @override
  String get deckDailyChallenges => 'Retos diarios';

  @override
  String get deckDailyChallengesSubtitle => 'Puzles nuevos cada día';

  @override
  String selectedPuzzleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzles',
      one: '1 puzle',
    );
    return '$_temp0';
  }

  @override
  String get getStartedTitle => 'Comenzar';

  @override
  String get welcomeTagline =>
      'Mejora tu ajedrez rápido con Pippo, tu entrenador personal para aprender, mejorar y ganar más partidas.';

  @override
  String get signInOrSignUpSubtitle =>
      'Inicia sesión o regístrate para guardar tu progreso.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get errGoogleSignIn =>
      'No se pudo completar el inicio de sesión con Google.';

  @override
  String get signInTab => 'Iniciar sesión';

  @override
  String get signUpTab => 'Registrarse';

  @override
  String get createAccountTitle => 'Crear cuenta';

  @override
  String get orLabel => 'O';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get welcomeBackTitle => 'Bienvenido de nuevo';

  @override
  String get signInSubtitle =>
      'Inicia sesión en tu cuenta y sigue subiendo de nivel.';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'Escribe tu correo';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signUpSubtitle => 'Únete a miles de jugadores y mejora tu juego.';

  @override
  String get firstNameLabel => 'Nombre';

  @override
  String get firstNameHint => 'Juan';

  @override
  String get lastNameLabel => 'Apellido';

  @override
  String get lastNameHint => 'Pérez';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordUpdated => 'Contraseña actualizada.';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get enterResetCodeTitle => 'Introduce el código';

  @override
  String get resetIntro =>
      'Escribe el correo de tu cuenta y te enviaremos un código de recuperación.';

  @override
  String resetCodeSentIntro(String email) {
    return 'Enviamos un código de recuperación a $email. Escríbelo abajo junto con tu nueva contraseña.';
  }

  @override
  String get recoveryCodeLabel => 'Código de recuperación';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get confirmNewPasswordLabel => 'Confirmar nueva contraseña';

  @override
  String get updatePassword => 'Actualizar contraseña';

  @override
  String get sendRecoveryCode => 'Enviar código';

  @override
  String get errEnterValidEmail => 'Escribe un correo electrónico válido.';

  @override
  String get errEnterCodeFromEmail =>
      'Escribe el código que recibiste por correo.';

  @override
  String get errPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get namePromptTitle => '¿Cómo te llamamos?';

  @override
  String get namePromptSubtitle =>
      'Elige un nombre para tu perfil y personalizaremos tu experiencia.';

  @override
  String get yourNameHint => 'Tu nombre';

  @override
  String get verifyEmailTitle => 'Verificar correo';

  @override
  String get enterVerificationCodeTitle =>
      'Introduce el código de verificación';

  @override
  String get otpSentPrefix => 'Enviamos un código de 8 dígitos a\n';

  @override
  String get otpSentSuffix =>
      '. Revisa tu bandeja de entrada o la carpeta de spam.';

  @override
  String get verifyCodeButton => 'Verificar código';

  @override
  String get didntReceiveCode => '¿No recibiste el código?';

  @override
  String get resend => 'Reenviar';

  @override
  String resendInSeconds(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get verificationCodeResent => 'Código de verificación reenviado';

  @override
  String helloGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeSubtitle => '¿Listo para aprender algo nuevo hoy?';

  @override
  String get coursesSection => 'Cursos';

  @override
  String get dailyPracticeSection => 'Práctica diaria';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get todayLabel => 'HOY';

  @override
  String get gamesVsPippo => 'partidas vs Pippo';

  @override
  String get puzzleRatingLabel => 'Puntuación de puzles';

  @override
  String get dailyStreakLabel => 'Racha diaria';

  @override
  String get chaptersDoneLabel => 'Capítulos completados';

  @override
  String get tacticsTrainingTitle => 'Entrenamiento táctico';

  @override
  String get tacticsTrainingSubtitle => 'Resuelve puzles y afina tu juego';

  @override
  String get dailyPuzzleLabel => 'Puzle diario';

  @override
  String get playNow => 'Jugar ahora';

  @override
  String get navHome => 'Inicio';

  @override
  String get navCourses => 'Cursos';

  @override
  String get navPuzzles => 'Puzles';

  @override
  String get navAnalysis => 'Análisis';

  @override
  String get navMenu => 'Menú';

  @override
  String get planBadgeAdmin => 'ADMIN';

  @override
  String get planBadgeFree => 'GRATIS';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return 'PLAN $tier';
  }

  @override
  String get coursesComingSoon => 'Cursos próximamente';

  @override
  String get continueLearning => 'Seguir aprendiendo';

  @override
  String get continueLearningButton => 'Seguir aprendiendo';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total variantes hechas',
      one: '$completed/$total variante hecha',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'Blancas';

  @override
  String get sideBlack => 'Negras';

  @override
  String get sideWhiteInitial => 'B';

  @override
  String get sideBlackInitial => 'N';

  @override
  String courseMetaChip(String side, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $count capítulos',
      one: '$side · 1 capítulo',
    );
    return '$_temp0';
  }

  @override
  String get puzzlesTitle => 'Puzles';

  @override
  String get puzzlesIntroTitle => 'Afina tu táctica';

  @override
  String get puzzlesIntroSubtitle =>
      'Entrena los temas que más importan y corrige los errores de tus partidas.';

  @override
  String get puzzlesFromYourGamesTitle => 'Puzles de tus partidas';

  @override
  String get solveNowButton => 'Resolver ahora';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count puzles pendientes';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'Aún no hay puzles — termina una partida contra Pippo y tus errores se convertirán en puzles.';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return '$count puzles descargados — disponibles aunque no tengas internet.';
  }

  @override
  String get mixedPuzzlesTitle => 'Puzles mixtos';

  @override
  String get mixedPuzzlesSubtitle => 'Juega puzles de temas variados';

  @override
  String get mixedPuzzlesRequiresInternet => 'Necesita conexión a internet';

  @override
  String get downloadingPuzzlesStatus => 'Descargando puzles...';

  @override
  String get downloadPuzzlesSubtitle =>
      'Guarda de 10 a 100 puzles para resolver sin internet';

  @override
  String get playDownloadedPuzzlesTitle => 'Jugar puzles descargados';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count puzles guardados — disponibles sin conexión';
  }

  @override
  String get practiceThemesSection => 'Practica por temas';

  @override
  String get browseAllThemesButton => 'Ver todos los temas';

  @override
  String get themesRequireInternet => 'Los temas necesitan internet';

  @override
  String get coursesTitle => 'Cursos';

  @override
  String get coursesTabOpenings => 'Aperturas';

  @override
  String get coursesTabMiddlegames => 'Medio juego';

  @override
  String get coursesTabEndgames => 'Finales';

  @override
  String get noCoursesHereYet => 'Aún no hay cursos aquí.';

  @override
  String get tryAgainButton => 'Intentar de nuevo';

  @override
  String playAsSide(String side) {
    return 'Juega con $side';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count capítulos';
  }

  @override
  String variationCountLabel(int count) {
    return '$count variantes';
  }

  @override
  String get courseDetailsTitle => 'Detalle del curso';

  @override
  String get chaptersTitle => 'Capítulos';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO: $code';
  }

  @override
  String get noChaptersAvailable => 'No hay capítulos disponibles.';

  @override
  String get chapterCompletedBadge => 'Completado';

  @override
  String get noVariationsAvailable => 'Sin variantes disponibles';

  @override
  String get noVariationsForChapterYet =>
      'Aún no hay variantes para este capítulo.';

  @override
  String get learnButton => 'Aprender';

  @override
  String get testButton => 'Examen';

  @override
  String get pricingTitle => 'Hazte Pro';

  @override
  String get pricingHeroTitle => 'Desbloquea todo\ntu potencial en ajedrez.';

  @override
  String get pricingHeroSubtitle =>
      'Análisis avanzado, puzles ilimitados y coaching con IA.';

  @override
  String get pricingFaqHeader => 'PREGUNTAS FRECUENTES';

  @override
  String get pricingFaqCancelQuestion => '¿Puedo cancelar cuando quiera?';

  @override
  String get pricingFaqCancelAnswer =>
      'Sí, puedes cancelar tu suscripción Pro cuando quieras. Mantendrás el acceso hasta el final de tu periodo de pago.';

  @override
  String get pricingFaqTrialQuestion => '¿Hay prueba gratis?';

  @override
  String get pricingFaqTrialAnswer =>
      'Pro incluye 7 días de prueba gratis. No necesitas tarjeta para empezar.';

  @override
  String get pricingFaqPaymentQuestion => '¿Qué métodos de pago aceptan?';

  @override
  String get pricingFaqPaymentAnswer =>
      'Aceptamos las principales tarjetas de crédito, Apple Pay y Google Pay.';

  @override
  String get pricingMostPopularBadge => 'MÁS POPULAR';

  @override
  String get pricingFreeBadge => 'GRATIS';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'Gratis';

  @override
  String get pricingProPrice => '\$9.99/mes';

  @override
  String get pricingFreePrice => '\$0';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'Análisis con motor ilimitado';

  @override
  String get pricingFeatureDeepClassification =>
      'Clasificación profunda de jugadas';

  @override
  String get pricingFeatureAiReview => 'Revisión de partidas con IA';

  @override
  String get pricingFeatureOpeningExplorer =>
      'Explorador de aperturas avanzado';

  @override
  String get pricingFeatureUnlimitedPuzzles => 'Sets de puzles ilimitados';

  @override
  String get pricingFeatureTrainingPlans =>
      'Planes de entrenamiento a tu medida';

  @override
  String get pricingFeaturePrioritySupport => 'Soporte prioritario';

  @override
  String get pricingFeatureEarlyAccess => 'Acceso anticipado a novedades';

  @override
  String get pricingFeatureBasicAnalysis => 'Análisis básico con motor';

  @override
  String get pricingFeatureStandardClassification =>
      'Clasificación estándar de jugadas';

  @override
  String get pricingFeatureGameImport =>
      'Importa partidas de Lichess y Chess.com';

  @override
  String get pricingFeatureLimitedPuzzles => 'Sets de puzles limitados';

  @override
  String get pricingFeatureCommunityAccess => 'Acceso a la comunidad';

  @override
  String get pricingStartTrialButton => 'Empezar prueba gratis';

  @override
  String get pricingCurrentPlanButton => 'Plan actual';

  @override
  String get startingEngineStatus => 'Iniciando el motor...';

  @override
  String get downloadPippoPrompt =>
      'Descarga Pippo (BaseModel.onnx) para jugar sin conexión.';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received MB / $total MB';
  }

  @override
  String get downloadingStatus => 'Descargando...';

  @override
  String get downloadEngineButton => 'Descargar motor';

  @override
  String get startChapterButton => 'Empezar capítulo';

  @override
  String get finishChapterButton => 'Terminar capítulo';

  @override
  String get takeTestButton => 'Hacer el examen';

  @override
  String get exploreBranchesButton => 'Explorar variantes';

  @override
  String get moveToNextVariationButton => 'Pasar a la siguiente variante';

  @override
  String get variationsTitle => 'Variantes';

  @override
  String get alternativeBranchesTitle => 'Ramas alternativas';

  @override
  String get noTheoryAvailable => 'No hay teoría para esta variante.';

  @override
  String get editBranchExplanationTooltip => 'Editar explicación de la rama';

  @override
  String get editExplanationTooltip => 'Editar explicación';

  @override
  String get editTheoryTooltip => 'Editar teoría';

  @override
  String branchEditTitle(String name) {
    return 'Rama: $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'Jugada: $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'Capítulo: $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'Teoría: $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'Los usuarios gratis pueden desbloquear un capítulo nuevo al día.';

  @override
  String playMovePrompt(String move) {
    return 'Juega $move';
  }

  @override
  String get opponentThinking => 'Estoy pensando';

  @override
  String opponentPlayedMove(String move) {
    return 'El rival jugó $move';
  }

  @override
  String correctMoveWithName(String move) {
    return '¡Correcto! $move';
  }

  @override
  String get notRightMove => 'Esa no es la jugada correcta';

  @override
  String get variationCompletedMessage => '¡Variante completada!';

  @override
  String get explanationUpdatedMessage =>
      'Explicación actualizada para todos los que estudian este curso.';

  @override
  String thinkAboutMovesHint(String piece) {
    return 'Piensa en las jugadas de $piece...';
  }

  @override
  String get writeHintPlaceholder => 'Escribe la pista...';

  @override
  String get hintUpdatedMessage =>
      'Pista actualizada para todos los que hacen este examen.';

  @override
  String get masteryTestTitle => 'Examen final';

  @override
  String get thinkItThrough => 'Piénsalo con calma...';

  @override
  String get correctFeedback => '¡Correcto!';

  @override
  String get notQuiteTryAgain => 'Casi — inténtalo de nuevo';

  @override
  String get opponentThinkingTest => 'El rival está pensando...';

  @override
  String get yourMovePlayOpeningLine => 'Te toca — juega la línea de apertura';

  @override
  String get editHintTooltip => 'Editar pista';

  @override
  String get variationLabelUpper => 'VARIANTE';

  @override
  String get overallProgressLabel => 'Progreso total';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total jugadas';
  }

  @override
  String get abortButton => 'Abandonar';

  @override
  String get getHintButton => 'Pedir pista';

  @override
  String get chapterPassedTitle => 'Capítulo superado';

  @override
  String youInternalizedChapter(String chapter) {
    return 'Ya dominas $chapter.';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count variantes completadas';
  }

  @override
  String get returnToCourseButton => 'Volver al curso';

  @override
  String hintForMoveTitle(String move) {
    return 'Pista para $move';
  }

  @override
  String get dailyPuzzleTitle => 'Puzle diario';

  @override
  String get downloadedPuzzlesTitle => 'Puzles descargados';

  @override
  String get whiteToPlay => 'Juegan blancas';

  @override
  String get blackToPlay => 'Juegan negras';

  @override
  String hintLookAtPiece(String piece, String square) {
    return 'Mira tu $piece en $square';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return 'Tu $piece en $square es la clave';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return 'Fíjate en el $piece que está en $square';
  }

  @override
  String themeHintAbout(String theme) {
    return 'Este puzle trata de $theme';
  }

  @override
  String themeHintWayOut(String theme) {
    return '$theme es tu salida aquí';
  }

  @override
  String themeHintThinking(String theme) {
    return 'Piensa en términos de $theme';
  }

  @override
  String get piecePawn => 'peón';

  @override
  String get pieceKnight => 'caballo';

  @override
  String get pieceBishop => 'alfil';

  @override
  String get pieceRook => 'torre';

  @override
  String get pieceQueen => 'dama';

  @override
  String get pieceKing => 'rey';

  @override
  String get pieceGeneric => 'pieza';

  @override
  String get mixedTacticsLabel => 'táctica mixta';

  @override
  String get allDownloadedSolvedMessage =>
      'Resolviste todos los puzles descargados — descarga más la próxima vez que tengas internet.';

  @override
  String get loadingNextPuzzles => 'Cargando más puzles...';

  @override
  String get noPuzzlesAvailable => 'No hay puzles disponibles.';

  @override
  String get yourRatingLabel => 'Tu puntuación:';

  @override
  String get hintButton => 'Pista';

  @override
  String get showThemeButton => 'Ver tema';

  @override
  String get hintUsedButton => 'Pista usada';

  @override
  String get doneButton => 'Listo';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get retryButton => 'Reintentar';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'Jugaste $move en esta posición, y fue $classification. Busca una jugada mejor.';
  }

  @override
  String get notBestMoveTryAgain =>
      'Esa no es la mejor jugada aquí. Inténtalo de nuevo y busca algo más fuerte.';

  @override
  String get greatJobFoundBestMove => '¡Muy bien! Encontraste la mejor jugada.';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return 'Mira tu $piece en $square. Esa es la pieza que debes mover.';
  }

  @override
  String get allMyPuzzlesSolvedMessage =>
      '¡Resolviste todos los puzles — buen trabajo!';

  @override
  String get noMyPuzzlesEmptyState =>
      'Aún no hay puzles disponibles.\n\nTermina una partida contra Pippo — tus errores se convertirán en puzles solos.';

  @override
  String puzzleCounterTitle(int current, int total) {
    return 'Puzle $current de $total';
  }

  @override
  String get finishButton => 'Terminar';

  @override
  String get nextPuzzleButton => 'Siguiente puzle';

  @override
  String get allThemesTitle => 'Todos los temas';

  @override
  String get allThemesIntro =>
      'Practica todo tipo de puzles en un solo lugar. Elige un tema, pon a prueba tu nivel y mira cómo te va en cada parte del juego.';

  @override
  String get themesNeedInternetOffline =>
      'Los temas necesitan internet para cargar puzles nuevos. Ahora mismo no tienes conexión.';

  @override
  String get needsInternetForBatch =>
      'Necesita internet para cargar puzles nuevos';

  @override
  String get themeGroupMates => 'Mates';

  @override
  String get themeGroupTactics => 'Táctica';

  @override
  String get themeGroupKingAttack => 'Ataque al rey';

  @override
  String get themeGroupEndgames => 'Finales';

  @override
  String get themeGroupPawnsPromotion => 'Peones y promoción';

  @override
  String get themeGroupStrategy => 'Estrategia';

  @override
  String get themeMateIn1 => 'Mate en 1';

  @override
  String get themeMateIn1Desc => 'Encuentra el mate en una sola jugada.';

  @override
  String get themeMateIn2 => 'Mate en 2';

  @override
  String get themeMateIn2Desc =>
      'Prepara la posición y termina con mate en tu próxima jugada.';

  @override
  String get themeMateIn3 => 'Mate en 3';

  @override
  String get themeMateIn3Desc =>
      'Encuentra la secuencia ganadora que da mate en tres jugadas.';

  @override
  String get themeMateIn4 => 'Mate en 4';

  @override
  String get themeMateIn4Desc =>
      'Calcula unas jugadas por delante para forzar el mate.';

  @override
  String get themeMateIn5 => 'Mate en 5';

  @override
  String get themeMateIn5Desc =>
      'Una secuencia de mate larga donde cada jugada cuenta.';

  @override
  String get themeOtherMates => 'Otros mates';

  @override
  String get themeOtherMatesDesc =>
      'Patrones especiales como pasillo, ahogado, Anastasia, árabe, Boden, Opera y más.';

  @override
  String get themeFork => 'Horquilla';

  @override
  String get themeForkDesc => 'Una pieza ataca dos o más objetivos a la vez.';

  @override
  String get themePin => 'Clavada';

  @override
  String get themePinDesc =>
      'Una pieza no se puede mover porque dejaría algo más valioso al descubierto.';

  @override
  String get themeSkewer => 'Ataque a la descubierta lineal';

  @override
  String get themeSkewerDesc =>
      'Ataca una pieza valiosa y captura lo que se esconde detrás.';

  @override
  String get themeDiscoveredAttack => 'Ataque a la descubierta';

  @override
  String get themeDiscoveredAttackDesc =>
      'Mueve una pieza para liberar el ataque de otra.';

  @override
  String get themeDiscoveredCheck => 'Jaque a la descubierta';

  @override
  String get themeDiscoveredCheckDesc =>
      'Da jaque al mover otra pieza del camino.';

  @override
  String get themeDoubleCheck => 'Jaque doble';

  @override
  String get themeDoubleCheckDesc => 'Da jaque con dos piezas a la vez.';

  @override
  String get themeSacrifice => 'Sacrificio';

  @override
  String get themeSacrificeDesc =>
      'Entrega material para conseguir algo más fuerte a cambio.';

  @override
  String get themeDeflection => 'Desviación';

  @override
  String get themeDeflectionDesc =>
      'Obliga a una pieza a irse de donde debe estar.';

  @override
  String get themeClearance => 'Despeje';

  @override
  String get themeClearanceDesc =>
      'Quita una pieza del camino para abrir paso a otra.';

  @override
  String get themeCapturingDefender => 'Capturar al defensor';

  @override
  String get themeCapturingDefenderDesc =>
      'Elimina la pieza que protege un objetivo importante.';

  @override
  String get themeAdvancedTactics => 'Táctica avanzada';

  @override
  String get themeAdvancedTacticsDesc =>
      'Combinaciones más difíciles con varias ideas tácticas.';

  @override
  String get themeKingsideAttack => 'Ataque al flanco de rey';

  @override
  String get themeKingsideAttackDesc =>
      'Lanza un ataque contra el rey en el flanco de rey.';

  @override
  String get themeQueensideAttack => 'Ataque al flanco de dama';

  @override
  String get themeQueensideAttackDesc =>
      'Busca cómo romper alrededor del rey rival en el flanco de dama.';

  @override
  String get themeExposedKing => 'Rey expuesto';

  @override
  String get themeExposedKingDesc =>
      'Aprovecha un rey que perdió su protección.';

  @override
  String get themeAttackingF2F7 => 'Ataque a F2 F7';

  @override
  String get themeAttackingF2F7Desc =>
      'Ataca la casilla débil f2 o f7 junto al rey.';

  @override
  String get themeEndgame => 'Final';

  @override
  String get themeEndgameDesc =>
      'Encuentra la mejor forma de jugar cuando quedan pocas piezas.';

  @override
  String get themeRookEndgame => 'Final de torres';

  @override
  String get themeRookEndgameDesc =>
      'Aprende a sacarle el máximo a tus torres en el final.';

  @override
  String get themeQueenEndgame => 'Final de damas';

  @override
  String get themeQueenEndgameDesc =>
      'Encuentra las jugadas buenas en posiciones con damas en el tablero.';

  @override
  String get themeQueenRookEndgame => 'Final de dama y torre';

  @override
  String get themeQueenRookEndgameDesc =>
      'Juega finales donde aún quedan damas y torres.';

  @override
  String get themeBishopEndgame => 'Final de alfiles';

  @override
  String get themeBishopEndgameDesc =>
      'Usa tu alfil y tu rey para encontrar el plan ganador.';

  @override
  String get themeKnightEndgame => 'Final de caballos';

  @override
  String get themeKnightEndgameDesc =>
      'Encuentra las jugadas buenas en finales donde mandan los caballos.';

  @override
  String get themePawnEndgame => 'Final de peones';

  @override
  String get themePawnEndgameDesc =>
      'Calcula carreras de peones y encuentra el camino a la victoria.';

  @override
  String get themeZugzwang => 'Zugzwang';

  @override
  String get themeZugzwangDesc =>
      'Deja al rival en una posición donde cualquier jugada empeora todo.';

  @override
  String get themeAdvancedPawn => 'Peón avanzado';

  @override
  String get themeAdvancedPawnDesc =>
      'Usa un peón peligroso que entró hondo en campo rival.';

  @override
  String get themePromotion => 'Promoción';

  @override
  String get themePromotionDesc =>
      'Lleva un peón al final para cambiarlo por una pieza más fuerte.';

  @override
  String get themeUnderPromotion => 'Subpromoción';

  @override
  String get themeUnderPromotionDesc =>
      'Cambia por algo que no sea dama cuando eso es lo que gana.';

  @override
  String get themeEnPassant => 'Captura al paso';

  @override
  String get themeEnPassantDesc =>
      'Detecta la rara ocasión de capturar al paso.';

  @override
  String get themeQuietMove => 'Jugada tranquila';

  @override
  String get themeQuietMoveDesc =>
      'Encuentra una jugada calmada que da ventaja sin forzar táctica.';

  @override
  String get themeDefensiveMove => 'Jugada defensiva';

  @override
  String get themeDefensiveMoveDesc =>
      'Encuentra la jugada que frena la amenaza del rival.';

  @override
  String get themeAdvantage => 'Ventaja';

  @override
  String get themeAdvantageDesc =>
      'Encuentra la jugada que mantiene o agranda tu ventaja.';

  @override
  String get themeEquality => 'Igualdad';

  @override
  String get themeEqualityDesc =>
      'Encuentra la jugada que mantiene la posición igualada.';

  @override
  String get themeCrushing => 'Jugada demoledora';

  @override
  String get themeCrushingDesc =>
      'Encuentra la jugada fuerte que convierte una buena posición en ganada.';

  @override
  String get pippoThinking2 => 'Déjame buscar la mejor jugada';

  @override
  String get pippoThinking3 => 'Un momento... veo algunas ideas';

  @override
  String get pippoThinking4 => 'Calculando mi respuesta';

  @override
  String get pippoThreatAsk1 => '¿Ves lo que amenaza esta jugada?';

  @override
  String get pippoThreatAsk2 =>
      'Tengo una pequeña idea detrás de esa jugada...';

  @override
  String get pippoThreatAsk3 => 'Cuidado — esa jugada pone algo bajo presión.';

  @override
  String get pippoThreatAsk4 =>
      'Puede que esa jugada esconda más de lo que parece.';

  @override
  String get pippoGreat1 =>
      '¡Muy bien por encontrar la única jugada de la posición!';

  @override
  String get pippoGreat2 => 'Fue una gran jugada — muy bien vista.';

  @override
  String get pippoGreat3 =>
      'Hallazgo excelente. Jugaste esa posición de maravilla.';

  @override
  String get pippoBrilliant1 =>
      '¡Brillante! Esa jugada fue de una precisión hermosa.';

  @override
  String get pippoBrilliant2 => 'Qué idea tan brillante — no me la esperaba.';

  @override
  String get pippoBrilliant3 =>
      'Fue brillante. Encontraste una jugada muy creativa.';

  @override
  String get pippoFinished1 => '¡Qué buena partida! ¿Jugamos otra?';

  @override
  String get pippoFinished2 => '¡Bien jugado! ¿Te apetece otra?';

  @override
  String get pippoFinished3 => 'Buena partida — la disfruté. ¿Revancha?';

  @override
  String get classificationBookComment => 'Una jugada del libro de aperturas.';

  @override
  String get resignDialogTitle => '¿Abandonar la partida?';

  @override
  String get resignDialogBody =>
      '¿Seguro que quieres abandonar? Esto terminará la partida actual.';

  @override
  String get resignConfirm => 'Abandonar';

  @override
  String get gameOverResignBlack => 'Las negras ganan por abandono';

  @override
  String get gameOverResignWhite => 'Las blancas ganan por abandono';

  @override
  String get gameOverDefault => 'Partida terminada';

  @override
  String get gameOverMateBlack => 'Las negras ganan por mate';

  @override
  String get gameOverMateWhite => 'Las blancas ganan por mate';

  @override
  String get gameOverStalemate => 'Tablas por ahogado';

  @override
  String get gameOverRepetition => 'Tablas por repetición';

  @override
  String get gameOverInsufficient => 'Tablas por material insuficiente';

  @override
  String get gameOverDrawn => 'Partida en tablas';

  @override
  String get playStartFirst => 'Empieza una partida primero';

  @override
  String get takebackTrainingOnly =>
      'Retroceder solo está disponible en modo Entrenamiento';

  @override
  String get takebackNoMoves => 'No hay jugadas para retroceder';

  @override
  String get takebackDone => 'Jugada retrocedida';

  @override
  String get pippoMissBare => 'Se te escapó una jugada mejor en esta posición.';

  @override
  String pippoMissWithMove(String move) {
    return 'Se te escapó una jugada mejor en esta posición, debiste jugar $move.';
  }

  @override
  String get pippoBlunderPause =>
      'Esa jugada fue un error grave. Retrocede, o sigue y yo continúo jugando.';

  @override
  String get hintTrainingOnly =>
      'Las pistas solo están disponibles en modo Entrenamiento';

  @override
  String get hintYourTurnOnly =>
      'Las pistas solo están disponibles en tu turno';

  @override
  String get hintStillAnalyzing => 'Sigo analizando... inténtalo en un momento';

  @override
  String hintLookForPiece(String piece, String square) {
    return 'Busca una buena jugada con tu $piece en $square.';
  }

  @override
  String get playToolTakeback => 'Retroceder';

  @override
  String get playToolAskHint => 'Pedir pista a Pippo';

  @override
  String get playToolClassifyHeader => 'Clasificar';

  @override
  String get classifyYourMoves => 'Tus jugadas';

  @override
  String get classifyPippoMoves => 'Jugadas de Pippo';

  @override
  String get playingPippoTitle => 'Jugando contra Pippo';

  @override
  String get resignButton => 'Abandonar';

  @override
  String get playAsHeader => 'JUEGA COMO';

  @override
  String get sideRandom => 'Al azar';

  @override
  String get strengthHeader => 'FUERZA';

  @override
  String get optionsHeader => 'OPCIONES';

  @override
  String get modeLabel => 'Modo';

  @override
  String get modeChallenge => 'Reto';

  @override
  String get modeTraining => 'Entrenamiento';

  @override
  String get startGameButton => 'Empezar partida';

  @override
  String get perkFeedback => 'Recibe comentarios sobre tus jugadas';

  @override
  String get perkSeeThreats => 'Ve todas las amenazas';

  @override
  String get perkTakeback => 'Retrocede jugadas cuando quieras';

  @override
  String get perkBlunderPause => 'Pausa la partida si cometes un error grave';

  @override
  String get perkHintsAllowed => 'Pistas permitidas';

  @override
  String get perkNoFeedback => 'Sin comentarios sobre jugadas';

  @override
  String get perkHiddenThreats => 'Amenazas ocultas';

  @override
  String get perkNoTakebacks => 'Sin retrocesos';

  @override
  String get perkNoBlunderPause => 'La partida sigue tras errores graves';

  @override
  String get perkNoHints => 'Sin pistas';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'Ocultar amenazas';

  @override
  String get showThreat => 'Mostrar amenaza';

  @override
  String get blunderContinue => 'Seguir';

  @override
  String get gameOverFallback => 'Partida terminada';

  @override
  String get resultHome => 'Inicio';

  @override
  String get resultNewGame => 'Nueva partida';

  @override
  String get resultAnalyzeGame => 'Analizar partida';

  @override
  String get gameToolsTooltip => 'Herramientas de juego';

  @override
  String get movesHeader => 'Jugadas';

  @override
  String moveCountLabel(int count) {
    return '$count jugadas';
  }

  @override
  String get movesEmptyPlay => 'Tus jugadas aparecerán aquí mientras juegas.';

  @override
  String get puzzleNotBest => 'No es la mejor jugada. ¡Inténtalo de nuevo!';

  @override
  String get puzzleSessionComplete => '¡Sesión de práctica completa!';

  @override
  String get practiceTitle => 'Práctica';

  @override
  String get puzzleEmpty => 'No hay puzles disponibles.';

  @override
  String puzzleCounter(int current, int total) {
    return 'Puzle $current/$total';
  }

  @override
  String get puzzleHint => 'Pista';

  @override
  String get puzzleShowMove => 'Ver jugada';

  @override
  String get puzzleUsedHint => 'Pista usada';

  @override
  String get puzzleNext => 'Siguiente puzle';

  @override
  String get analysisTitle => 'Análisis';

  @override
  String get addGameTooltip => 'Añadir partida o posición';

  @override
  String get closeGameButton => 'Cerrar';

  @override
  String get positionLoadedOk => 'Posición cargada';

  @override
  String get gameImportedOk => 'Partida importada';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess vs $opponent';
  }

  @override
  String get youLabel => 'Tú';

  @override
  String explorerGameLoaded(String white, String black) {
    return '$white vs $black cargada';
  }

  @override
  String get reviewNoGame => 'No hay partida para revisar';

  @override
  String get reviewQuotaUsed =>
      'Ya usaste las revisiones de hoy. Pásate a Pro para más.';

  @override
  String get analysisNoMoves => 'No hay jugadas para analizar';

  @override
  String get settingsEngineHeader => 'Motor';

  @override
  String get settingsEnableEngine => 'Activar motor';

  @override
  String get settingsDepth => 'Profundidad';

  @override
  String get settingsClassificationHeader => 'Clasificación de jugadas';

  @override
  String get settingsEnableClassification => 'Activar clasificación';

  @override
  String get settingsThreatHeader => 'Detector de amenazas';

  @override
  String get settingsThreatToggle => 'Detector de amenazas';

  @override
  String get settingsLinesLabel => 'Número de líneas';

  @override
  String get filterBook => 'Libro';

  @override
  String get filterBrilliant => 'Brillante';

  @override
  String get filterBlunder => 'Error grave';

  @override
  String get showLess => 'Ver menos';

  @override
  String get showAll => 'Ver todo';

  @override
  String get analyzingBanner =>
      'Tu partida se está analizando, puedes salir de esta pantalla';

  @override
  String get fullViewTooltip => 'Vista completa';

  @override
  String get compactViewTooltip => 'Vista compacta';

  @override
  String get classifyingMove => 'Clasificando jugada...';

  @override
  String get phraseBest => 'la mejor jugada';

  @override
  String get phraseBrilliant => 'una jugada brillante';

  @override
  String get phraseGreat => 'una gran jugada';

  @override
  String get phraseExcellent => 'una jugada excelente';

  @override
  String get phraseGood => 'una jugada buena';

  @override
  String get phraseInaccuracy => 'una imprecisión';

  @override
  String get phraseMistake => 'un error';

  @override
  String get phraseBlunder => 'un error grave';

  @override
  String get phraseMiss => 'una ocasión perdida';

  @override
  String get phraseBook => 'una jugada de libro';

  @override
  String get phraseForced => 'una jugada forzada';

  @override
  String sentenceBestSuffix(String move) {
    return ', $move era la mejor jugada';
  }

  @override
  String get retryReview => 'Reintentar revisión';

  @override
  String get reviewWaiting => 'Tu partida se está revisando';

  @override
  String get pgnEmpty => 'Aún no hay jugadas';

  @override
  String get pgnResume => 'Volver';

  @override
  String get showBestTooltip => 'Mostrar mejor jugada';

  @override
  String get tabMoves => 'Jugadas';

  @override
  String get tabExplorer => 'Explorador';

  @override
  String get moveTreeHeader => 'Árbol de jugadas';

  @override
  String get moveTreeEmpty => 'Tus jugadas y variantes aparecerán aquí.';

  @override
  String get gameReportButton => 'Informe de partida';

  @override
  String get gameAnalysisTitle => 'Análisis de partida';

  @override
  String get analyzeButton => 'Analizar';

  @override
  String get viewReportTooltip => 'Ver informe';

  @override
  String get noReportYet => 'Aún no hay informe';

  @override
  String get addToAnalysisTitle => 'Añadir al análisis';

  @override
  String get addToAnalysisSubtitle =>
      'Empieza desde una partida, una posición o un tablero libre.';

  @override
  String get importSegment => 'Importar';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'Colocar';

  @override
  String get gameReportTitle => 'Informe de partida';

  @override
  String get accuraciesHeader => 'Precisión';

  @override
  String get accuracyRerunHint =>
      'Repite el análisis completo para calcular la precisión.';

  @override
  String get pastePgnTooltip => 'Pegar PGN';

  @override
  String get pastePgnButton => 'Pegar el PGN copiado';

  @override
  String get searchingLabel => 'Buscando...';

  @override
  String get importingLabel => 'Importando...';

  @override
  String get searchGamesButton => 'Buscar partidas';

  @override
  String get startAnalysisButton => 'Empezar análisis';

  @override
  String get fenFieldLabel => 'Posición (FEN)';

  @override
  String get pasteFenTooltip => 'Pegar FEN';

  @override
  String get pasteFenButton => 'Pegar el FEN copiado';

  @override
  String get loadPositionButton => 'Cargar posición';

  @override
  String get inputPgnText => 'Texto PGN';

  @override
  String get inputUsername => 'Nombre de usuario';

  @override
  String get inputGameUrl => 'Enlace de partida';

  @override
  String get hintPastePgn => 'Pega el PGN aquí...';

  @override
  String get hintEnterUsername => 'Escribe el usuario...';

  @override
  String get dialogOk => 'Vale';

  @override
  String get lichessSignInCancelled => 'Inicio con Lichess cancelado';

  @override
  String get boardSetupTitle => 'Colocar posición';

  @override
  String get flipBoardTooltip => 'Girar tablero';

  @override
  String get clearBoardButton => 'Vaciar tablero';

  @override
  String get startPositionButton => 'Posición inicial';

  @override
  String get whoMovesHeader => 'QUIÉN MUEVE PRIMERO';

  @override
  String get piecesHeader => 'PIEZAS';

  @override
  String get setupInstructions =>
      'Toca una pieza para elegirla y luego toca el tablero para colocarla. Arrastra una pieza al tablero para añadirla, o fuera del tablero para quitarla.';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'Terminar';

  @override
  String engineDepthLabel(int depth) {
    return 'Profundidad $depth';
  }

  @override
  String get analyzeGameTitle => 'Analizar partida';

  @override
  String get reviewsUnlimited => 'Revisiones ilimitadas hoy';

  @override
  String reviewsLeftToday(int done, int total) {
    return '$done/$total revisiones disponibles hoy';
  }

  @override
  String get analyzeTypeHeader => 'Tipo';

  @override
  String get analyzeModeAnalysis => 'Análisis';

  @override
  String get analyzeModeAnalysisDesc =>
      'Clasifica todas las jugadas de tu partida con Stockfish';

  @override
  String get analyzeModeReview => 'Revisión';

  @override
  String get upgradeToProTitle => 'Pásate a Pro';

  @override
  String get reviewModeDesc => 'Explicaciones jugada a jugada de tu partida';

  @override
  String get reviewLockedDesc => 'Desbloquea más revisiones cada día';

  @override
  String get engineDepthHeader => 'Profundidad del motor';

  @override
  String depthValueLabel(int depth) {
    return 'Profundidad $depth';
  }

  @override
  String get depthHint => 'Más profundidad puede tardar más en analizar';

  @override
  String get selectGameTitle => 'Elige una partida';

  @override
  String get versusShort => 'vs';

  @override
  String get speedBullet => 'Bullet';

  @override
  String get speedBlitz => 'Blitz';

  @override
  String get speedRapid => 'Rápidas';

  @override
  String get speedClassical => 'Clásicas';

  @override
  String get openingExplorerTitle => 'Explorador de aperturas';

  @override
  String get dbMasters => 'Maestros';

  @override
  String get filtersHeader => 'Filtros';

  @override
  String get theoreticalMoves => 'Jugadas teóricas';

  @override
  String get topMasterGames => 'Mejores partidas de maestros';

  @override
  String get recentGames => 'Partidas recientes';

  @override
  String get explorerSignInDesc =>
      'Inicia sesión con Lichess para explorar millones de partidas, partidas de maestros y estadísticas de aperturas.';

  @override
  String get signInWithLichess => 'Iniciar sesión con Lichess';

  @override
  String get noOpeningData => 'No hay datos de apertura';

  @override
  String gamesCountLabel(int count) {
    return '$count partidas';
  }

  @override
  String get unknownPlayer => 'Desconocido';

  @override
  String get monthJanuary => 'enero';

  @override
  String get monthFebruary => 'febrero';

  @override
  String get monthMarch => 'marzo';

  @override
  String get monthApril => 'abril';

  @override
  String get monthMay => 'mayo';

  @override
  String get monthJune => 'junio';

  @override
  String get monthJuly => 'julio';

  @override
  String get monthAugust => 'agosto';

  @override
  String get monthSeptember => 'septiembre';

  @override
  String get monthOctober => 'octubre';

  @override
  String get monthNovember => 'noviembre';

  @override
  String get monthDecember => 'diciembre';

  @override
  String get indicatorGreen => 'Verde';

  @override
  String get indicatorAmber => 'Ámbar';

  @override
  String get indicatorRed => 'Rojo';

  @override
  String get clsBest => 'La mejor';

  @override
  String get clsBrilliant => 'Brillante';

  @override
  String get clsGreat => 'Genial';

  @override
  String get clsExcellent => 'Excelente';

  @override
  String get clsGood => 'Buena';

  @override
  String get clsInaccuracy => 'Imprecisión';

  @override
  String get clsMistake => 'Error';

  @override
  String get clsBlunder => 'Error grave';

  @override
  String get clsBook => 'Libro';

  @override
  String get clsForced => 'Forzada';

  @override
  String get clsMiss => 'Ocasión perdida';

  @override
  String averageRatingLabel(int rating) {
    return 'Media $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move es $label';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move era la mejor jugada.';
  }
}
