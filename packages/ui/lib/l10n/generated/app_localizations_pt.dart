// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Pippo';

  @override
  String get defaultPlayerName => 'Jogador';

  @override
  String get notSignedIn => 'Não conectado';

  @override
  String get planAdmin => 'ADMIN';

  @override
  String get planPro => 'MEMBRO PRO';

  @override
  String get planFree => 'MEMBRO GRÁTIS';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get appSettingsSection => 'Configurações do app';

  @override
  String get supportSection => 'Suporte';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceSubtitle => 'Tema claro, escuro ou do sistema';

  @override
  String get subscriptionTitle => 'Assinatura';

  @override
  String get subscriptionSubtitle => 'Gerencie seu plano Atlas Pro';

  @override
  String get languageTitle => 'Idioma';

  @override
  String languageSubtitle(String language) {
    return '$language';
  }

  @override
  String get helpTitle => 'Ajuda e suporte';

  @override
  String get helpSubtitle => 'Perguntas frequentes e atendimento';

  @override
  String get contactSupportTitle => 'Falar com o suporte';

  @override
  String get contactSupportSubtitle => 'Fale com a equipe de suporte';

  @override
  String get logout => 'Sair';

  @override
  String get chooseTheme => 'Escolher tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get editDisplayName => 'Editar nome de exibição';

  @override
  String displayNameRule(int maxLength) {
    return 'Escolha um nome de até $maxLength caracteres.';
  }

  @override
  String get displayNameLabel => 'Nome de exibição';

  @override
  String get save => 'Salvar';

  @override
  String get languageSheetTitle => 'Escolher idioma';

  @override
  String get systemLanguage => 'Padrão do sistema';

  @override
  String get supportTypeLabel => 'Tipo de problema';

  @override
  String get supportTypeHint =>
      'Escolha a opção que melhor descreve o seu problema.';

  @override
  String get supportTypeUi => 'Interface';

  @override
  String get supportTypeError => 'Erro';

  @override
  String get supportTypeOther => 'Outro';

  @override
  String get supportSubjectLabel => 'Assunto';

  @override
  String get supportSubjectHint => 'Breve descrição do seu problema';

  @override
  String get supportMessageLabel => 'Mensagem';

  @override
  String get supportMessageHint => 'Descreva o seu problema em detalhe...';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count/$max caracteres';
  }

  @override
  String get supportSubmitButton => 'Enviar ticket';

  @override
  String get supportSuccessTitle => 'Ticket enviado!';

  @override
  String get supportSuccessBody =>
      'Vamos responder ao seu e-mail em 24-48 horas.';

  @override
  String get supportSuccessDone => 'Concluído';

  @override
  String get supportSignInTitle => 'Inicie sessão para falar com o suporte';

  @override
  String get supportSignInBody =>
      'Os tickets ficam ligados à sua conta para que possamos responder. Inicie sessão e tente novamente.';

  @override
  String get supportOfflineNotice =>
      'Está offline. Volte a ligar-se para enviar o seu ticket.';

  @override
  String get supportErrTypeRequired => 'Escolha o tipo de problema.';

  @override
  String get supportErrSubjectRequired => 'Introduza um assunto.';

  @override
  String get supportErrMessageRequired => 'Introduza uma mensagem.';

  @override
  String get supportErrSubjectTooLong => 'O seu assunto é demasiado longo.';

  @override
  String get supportErrMessageTooLong => 'A sua mensagem é demasiado longa.';

  @override
  String get supportErrGeneric =>
      'Não foi possível enviar o seu ticket. Tente novamente.';

  @override
  String get offlineBannerTitle => 'Sem conexão com a internet';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get boardSettingsTitle => 'Ajustes do tabuleiro';

  @override
  String get pieceSetLabel => 'Conjunto de peças';

  @override
  String get boardThemeLabel => 'Tema do tabuleiro';

  @override
  String get moveIndicatorLabel => 'Indicador de lances';

  @override
  String get showCoordinatesLabel => 'Mostrar coordenadas';

  @override
  String get dragAndDropLabel => 'Arrastar e soltar';

  @override
  String get soundLabel => 'Som';

  @override
  String get closeButton => 'Fechar';

  @override
  String get editExplanationTitle => 'Editar explicação';

  @override
  String get writeExplanationHint => 'Escreva a explicação...';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get boardThemeEmerald => 'Esmeralda';

  @override
  String get boardThemeMidnight => 'Meia-noite';

  @override
  String get boardThemePurple => 'Roxo';

  @override
  String get boardThemeSand => 'Areia';

  @override
  String get boardThemeBlue => 'Azul';

  @override
  String get boardThemeBrown => 'Marrom';

  @override
  String get quotaUpgradeCta =>
      'Assine o Pro para resolver quebra-cabeças ilimitados';

  @override
  String get downloadButton => 'Baixar';

  @override
  String get upgradeNow => 'Assinar agora';

  @override
  String get offlineDownloadsProNotice =>
      'O download de quebra-cabeças offline está disponível no Pro. Assine para salvar quebra-cabeças neste dispositivo.';

  @override
  String get savedForOffline => 'Salvo neste dispositivo para resolver offline';

  @override
  String get downloadPuzzlesTitle => 'Baixar quebra-cabeças';

  @override
  String get puzzleDecksTitle => 'Baralhos de quebra-cabeças';

  @override
  String get deckRecentMistakes => 'Erros recentes';

  @override
  String get deckRecentMistakesSubtitle => 'Táticas das suas partidas perdidas';

  @override
  String get deckMatingPatterns => 'Padrões de mate';

  @override
  String get deckMatingPatternsSubtitle => 'Domine os mates de final';

  @override
  String get deckOpeningTraps => 'Armadilhas de abertura';

  @override
  String get deckOpeningTrapsSubtitle => 'Truques comuns do seu repertório';

  @override
  String get deckDailyChallenges => 'Desafios diários';

  @override
  String get deckDailyChallengesSubtitle =>
      'Quebra-cabeças novos todos os dias';

  @override
  String selectedPuzzleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quebra-cabeças',
      one: '1 quebra-cabeça',
    );
    return '$_temp0';
  }

  @override
  String get getStartedTitle => 'Começar';

  @override
  String get welcomeTagline =>
      'Melhore rápido no xadrez com o Pippo, seu treinador pessoal para aprender, evoluir e ganhar mais partidas.';

  @override
  String get signInOrSignUpSubtitle =>
      'Entre ou crie uma conta para salvar seu progresso.';

  @override
  String get continueWithGoogle => 'Continuar com o Google';

  @override
  String get continueAsGuest => 'Continuar como visitante';

  @override
  String get errGoogleSignIn =>
      'Não foi possível concluir o login com o Google.';

  @override
  String get signInTab => 'Entrar';

  @override
  String get signUpTab => 'Criar conta';

  @override
  String get createAccountTitle => 'Criar conta';

  @override
  String get orLabel => 'OU';

  @override
  String get registerButton => 'Cadastrar';

  @override
  String get welcomeBackTitle => 'Bem-vindo de volta';

  @override
  String get signInSubtitle =>
      'Entre na sua conta e continue subindo de nível.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'Digite seu e-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get signUpSubtitle =>
      'Junte-se a milhares de jogadores e melhore seu jogo.';

  @override
  String get firstNameLabel => 'Nome';

  @override
  String get firstNameHint => 'João';

  @override
  String get lastNameLabel => 'Sobrenome';

  @override
  String get lastNameHint => 'Silva';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get passwordUpdated => 'Senha atualizada.';

  @override
  String get resetPasswordTitle => 'Redefinir senha';

  @override
  String get enterResetCodeTitle => 'Digite o código';

  @override
  String get resetIntro =>
      'Digite o e-mail da sua conta e enviaremos um código de recuperação.';

  @override
  String resetCodeSentIntro(String email) {
    return 'Enviamos um código de recuperação para $email. Digite-o abaixo junto com sua nova senha.';
  }

  @override
  String get recoveryCodeLabel => 'Código de recuperação';

  @override
  String get newPasswordLabel => 'Nova senha';

  @override
  String get confirmNewPasswordLabel => 'Confirmar nova senha';

  @override
  String get updatePassword => 'Atualizar senha';

  @override
  String get sendRecoveryCode => 'Enviar código';

  @override
  String get errEnterValidEmail => 'Digite um e-mail válido.';

  @override
  String get errEnterCodeFromEmail =>
      'Digite o código que você recebeu por e-mail.';

  @override
  String get errPasswordsDoNotMatch => 'As senhas não coincidem.';

  @override
  String get namePromptTitle => 'Como podemos te chamar?';

  @override
  String get namePromptSubtitle =>
      'Escolha um nome para o seu perfil e personalizaremos sua experiência.';

  @override
  String get yourNameHint => 'Seu nome';

  @override
  String get verifyEmailTitle => 'Verificar e-mail';

  @override
  String get enterVerificationCodeTitle => 'Digite o código de verificação';

  @override
  String get otpSentPrefix => 'Enviamos um código de 8 dígitos para\n';

  @override
  String get otpSentSuffix =>
      '. Verifique sua caixa de entrada ou a pasta de spam.';

  @override
  String get verifyCodeButton => 'Verificar código';

  @override
  String get didntReceiveCode => 'Não recebeu o código?';

  @override
  String get resend => 'Reenviar';

  @override
  String resendInSeconds(int seconds) {
    return 'Reenviar em ${seconds}s';
  }

  @override
  String get verificationCodeResent => 'Código de verificação reenviado';

  @override
  String helloGreeting(String name) {
    return 'Olá, $name';
  }

  @override
  String get homeSubtitle => 'Pronto para aprender algo novo hoje?';

  @override
  String get coursesSection => 'Cursos';

  @override
  String get dailyPracticeSection => 'Prática diária';

  @override
  String get seeAll => 'Ver tudo';

  @override
  String get todayLabel => 'HOJE';

  @override
  String get gamesVsPippo => 'partidas vs Pippo';

  @override
  String get puzzleRatingLabel => 'Nota de quebra-cabeças';

  @override
  String get dailyStreakLabel => 'Sequência diária';

  @override
  String get chaptersDoneLabel => 'Capítulos concluídos';

  @override
  String get tacticsTrainingTitle => 'Treino tático';

  @override
  String get tacticsTrainingSubtitle =>
      'Resolva quebra-cabeças e afine seu jogo';

  @override
  String get dailyPuzzleLabel => 'Quebra-cabeça do dia';

  @override
  String get playNow => 'Jogar agora';

  @override
  String get navHome => 'Início';

  @override
  String get navCourses => 'Cursos';

  @override
  String get navPuzzles => 'Puzzles';

  @override
  String get navAnalysis => 'Análise';

  @override
  String get navMenu => 'Menu';

  @override
  String get planBadgeAdmin => 'ADMIN';

  @override
  String get planBadgeFree => 'GRÁTIS';

  @override
  String get planBadgePro => 'PRO';

  @override
  String planChipLabel(String tier) {
    return 'PLANO $tier';
  }

  @override
  String get coursesComingSoon => 'Cursos em breve';

  @override
  String get continueLearning => 'Continuar aprendendo';

  @override
  String get continueLearningButton => 'Continuar aprendendo';

  @override
  String variationsDone(int completed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$completed/$total variações concluídas',
      one: '$completed/$total variação concluída',
    );
    return '$_temp0';
  }

  @override
  String get sideWhite => 'Brancas';

  @override
  String get sideBlack => 'Pretas';

  @override
  String get sideWhiteInitial => 'B';

  @override
  String get sideBlackInitial => 'P';

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
  String get puzzlesTitle => 'Quebra-cabeças';

  @override
  String get puzzlesIntroTitle => 'Afine sua tática';

  @override
  String get puzzlesIntroSubtitle =>
      'Treine os temas que mais importam e corrija os erros das suas partidas.';

  @override
  String get puzzlesFromYourGamesTitle => 'Quebra-cabeças das suas partidas';

  @override
  String get solveNowButton => 'Resolver agora';

  @override
  String puzzlesRemainingCount(int count) {
    return '$count quebra-cabeças restantes';
  }

  @override
  String get noPuzzlesFromGamesMessage =>
      'Ainda não há quebra-cabeças — termine uma partida contra o Pippo e seus erros vão virar quebra-cabeças.';

  @override
  String puzzlesDownloadedSuccess(int count) {
    return '$count quebra-cabeças baixados — disponíveis mesmo sem internet.';
  }

  @override
  String get mixedPuzzlesTitle => 'Quebra-cabeças mistos';

  @override
  String get mixedPuzzlesSubtitle => 'Jogue quebra-cabeças de temas variados';

  @override
  String get mixedPuzzlesRequiresInternet =>
      'Precisa de conexão com a internet';

  @override
  String get downloadingPuzzlesStatus => 'Baixando quebra-cabeças...';

  @override
  String get downloadPuzzlesSubtitle =>
      'Salve de 10 a 100 quebra-cabeças para resolver sem internet';

  @override
  String get playDownloadedPuzzlesTitle => 'Jogar quebra-cabeças baixados';

  @override
  String downloadedPuzzlesSavedOffline(int count) {
    return '$count quebra-cabeças salvos — disponíveis offline';
  }

  @override
  String get practiceThemesSection => 'Treine por temas';

  @override
  String get browseAllThemesButton => 'Ver todos os temas';

  @override
  String get themesRequireInternet => 'Os temas precisam de internet';

  @override
  String get coursesTitle => 'Cursos';

  @override
  String get coursesTabOpenings => 'Aberturas';

  @override
  String get coursesTabMiddlegames => 'Meio-jogo';

  @override
  String get coursesTabEndgames => 'Finais';

  @override
  String get noCoursesHereYet => 'Ainda não há cursos aqui.';

  @override
  String get tryAgainButton => 'Tentar de novo';

  @override
  String playAsSide(String side) {
    return 'Jogue de $side';
  }

  @override
  String chapterCountLabel(int count) {
    return '$count capítulos';
  }

  @override
  String variationCountLabel(int count) {
    return '$count variações';
  }

  @override
  String get courseDetailsTitle => 'Detalhes do curso';

  @override
  String get chaptersTitle => 'Capítulos';

  @override
  String ecoCodeLabel(String code) {
    return 'ECO: $code';
  }

  @override
  String get noChaptersAvailable => 'Nenhum capítulo disponível.';

  @override
  String get chapterCompletedBadge => 'Concluído';

  @override
  String get noVariationsAvailable => 'Sem variações disponíveis';

  @override
  String get noVariationsForChapterYet =>
      'Ainda não há variações para este capítulo.';

  @override
  String get learnButton => 'Aprender';

  @override
  String get testButton => 'Teste';

  @override
  String get pricingTitle => 'Seja Pro';

  @override
  String get pricingHeroTitle => 'Desbloqueie todo\nseu potencial no xadrez.';

  @override
  String get pricingHeroSubtitle =>
      'Análise avançada, quebra-cabeças ilimitados e treino com IA.';

  @override
  String get pricingFaqHeader => 'PERGUNTAS FREQUENTES';

  @override
  String get pricingFaqCancelQuestion => 'Posso cancelar quando quiser?';

  @override
  String get pricingFaqCancelAnswer =>
      'Sim, você pode cancelar sua assinatura Pro quando quiser. Você mantém o acesso até o fim do período pago.';

  @override
  String get pricingFaqTrialQuestion => 'Existe teste grátis?';

  @override
  String get pricingFaqTrialAnswer =>
      'O Pro vem com 7 dias de teste grátis. Sem cartão de crédito para começar.';

  @override
  String get pricingFaqPaymentQuestion =>
      'Quais formas de pagamento vocês aceitam?';

  @override
  String get pricingFaqPaymentAnswer =>
      'Aceitamos os principais cartões de crédito, Apple Pay e Google Pay.';

  @override
  String get pricingMostPopularBadge => 'MAIS POPULAR';

  @override
  String get pricingFreeBadge => 'GRÁTIS';

  @override
  String get pricingProTierName => 'Pro';

  @override
  String get pricingFreeTierName => 'Grátis';

  @override
  String get pricingProPrice => '\$9,99/mês';

  @override
  String get pricingFreePrice => '\$0';

  @override
  String get pricingFeatureUnlimitedAnalysis => 'Análise com motor ilimitada';

  @override
  String get pricingFeatureDeepClassification =>
      'Classificação profunda de lances';

  @override
  String get pricingFeatureAiReview => 'Revisão de partidas com IA';

  @override
  String get pricingFeatureOpeningExplorer =>
      'Explorador de aberturas avançado';

  @override
  String get pricingFeatureUnlimitedPuzzles =>
      'Pacotes de quebra-cabeças ilimitados';

  @override
  String get pricingFeatureTrainingPlans => 'Planos de treino para você';

  @override
  String get pricingFeaturePrioritySupport => 'Suporte prioritário';

  @override
  String get pricingFeatureEarlyAccess => 'Acesso antecipado a novidades';

  @override
  String get pricingFeatureBasicAnalysis => 'Análise básica com motor';

  @override
  String get pricingFeatureStandardClassification =>
      'Classificação padrão de lances';

  @override
  String get pricingFeatureGameImport =>
      'Importe partidas do Lichess e Chess.com';

  @override
  String get pricingFeatureLimitedPuzzles =>
      'Pacotes limitados de quebra-cabeças';

  @override
  String get pricingFeatureCommunityAccess => 'Acesso à comunidade';

  @override
  String get pricingStartTrialButton => 'Começar teste grátis';

  @override
  String get pricingCurrentPlanButton => 'Plano atual';

  @override
  String get startingEngineStatus => 'Iniciando o motor...';

  @override
  String get downloadPippoPrompt =>
      'Baixe o Pippo (BaseModel.onnx) para jogar offline.';

  @override
  String downloadProgressMbLabel(String received, String total) {
    return '$received MB / $total MB';
  }

  @override
  String get downloadingStatus => 'Baixando...';

  @override
  String get downloadEngineButton => 'Baixar motor';

  @override
  String get startChapterButton => 'Começar capítulo';

  @override
  String get finishChapterButton => 'Terminar capítulo';

  @override
  String get takeTestButton => 'Fazer o teste';

  @override
  String get exploreBranchesButton => 'Explorar variações';

  @override
  String get moveToNextVariationButton => 'Ir para a próxima variação';

  @override
  String get variationsTitle => 'Variações';

  @override
  String get alternativeBranchesTitle => 'Ramos alternativos';

  @override
  String get noTheoryAvailable => 'Sem teoria para esta variação.';

  @override
  String get editBranchExplanationTooltip => 'Editar explicação do ramo';

  @override
  String get editExplanationTooltip => 'Editar explicação';

  @override
  String get editTheoryTooltip => 'Editar teoria';

  @override
  String branchEditTitle(String name) {
    return 'Ramo: $name';
  }

  @override
  String moveEditTitle(String move) {
    return 'Lance: $move';
  }

  @override
  String chapterEditTitle(String name) {
    return 'Capítulo: $name';
  }

  @override
  String theoryEditTitle(String name) {
    return 'Teoria: $name';
  }

  @override
  String get freeUsersUnlockOneChapterPerDay =>
      'Usuários grátis podem desbloquear um capítulo novo por dia.';

  @override
  String playMovePrompt(String move) {
    return 'Jogue $move';
  }

  @override
  String get opponentThinking => 'Estou pensando';

  @override
  String opponentPlayedMove(String move) {
    return 'O adversário jogou $move';
  }

  @override
  String correctMoveWithName(String move) {
    return 'Correto! $move';
  }

  @override
  String get notRightMove => 'Esse não é o lance certo';

  @override
  String get variationCompletedMessage => 'Variação concluída!';

  @override
  String get explanationUpdatedMessage =>
      'Explicação atualizada para todos que estudam este curso.';

  @override
  String thinkAboutMovesHint(String piece) {
    return 'Pense nos lances de $piece...';
  }

  @override
  String get writeHintPlaceholder => 'Escreva a dica...';

  @override
  String get hintUpdatedMessage =>
      'Dica atualizada para todos que fazem este teste.';

  @override
  String get masteryTestTitle => 'Teste final';

  @override
  String get thinkItThrough => 'Pense com calma...';

  @override
  String get correctFeedback => 'Correto!';

  @override
  String get notQuiteTryAgain => 'Quase — tente de novo';

  @override
  String get opponentThinkingTest => 'O adversário está pensando...';

  @override
  String get yourMovePlayOpeningLine => 'Sua vez — jogue a linha de abertura';

  @override
  String get editHintTooltip => 'Editar dica';

  @override
  String get variationLabelUpper => 'VARIAÇÃO';

  @override
  String get overallProgressLabel => 'Progresso total';

  @override
  String pliesProgressCounter(int done, int total) {
    return '$done / $total lances';
  }

  @override
  String get abortButton => 'Desistir';

  @override
  String get getHintButton => 'Pedir dica';

  @override
  String get chapterPassedTitle => 'Capítulo concluído';

  @override
  String youInternalizedChapter(String chapter) {
    return 'Você já domina $chapter.';
  }

  @override
  String variationsCompletedCount(int count) {
    return '$count variações concluídas';
  }

  @override
  String get returnToCourseButton => 'Voltar ao curso';

  @override
  String hintForMoveTitle(String move) {
    return 'Dica para $move';
  }

  @override
  String get dailyPuzzleTitle => 'Quebra-cabeça do dia';

  @override
  String get downloadedPuzzlesTitle => 'Quebra-cabeças baixados';

  @override
  String get whiteToPlay => 'Brancas a jogar';

  @override
  String get blackToPlay => 'Pretas a jogar';

  @override
  String hintLookAtPiece(String piece, String square) {
    return 'Olhe sua $piece em $square';
  }

  @override
  String hintPieceIsKey(String piece, String square) {
    return 'Sua $piece em $square é a chave';
  }

  @override
  String hintFocusOnPiece(String piece, String square) {
    return 'Preste atenção na $piece que está em $square';
  }

  @override
  String themeHintAbout(String theme) {
    return 'Este quebra-cabeça é sobre $theme';
  }

  @override
  String themeHintWayOut(String theme) {
    return '$theme é sua saída aqui';
  }

  @override
  String themeHintThinking(String theme) {
    return 'Tente pensar em termos de $theme';
  }

  @override
  String get piecePawn => 'peão';

  @override
  String get pieceKnight => 'cavalo';

  @override
  String get pieceBishop => 'bispo';

  @override
  String get pieceRook => 'torre';

  @override
  String get pieceQueen => 'dama';

  @override
  String get pieceKing => 'rei';

  @override
  String get pieceGeneric => 'peça';

  @override
  String get mixedTacticsLabel => 'tática mista';

  @override
  String get allDownloadedSolvedMessage =>
      'Você resolveu todos os quebra-cabeças baixados — baixe mais na próxima vez que tiver internet.';

  @override
  String get loadingNextPuzzles => 'Carregando mais quebra-cabeças...';

  @override
  String get noPuzzlesAvailable => 'Nenhum quebra-cabeça disponível.';

  @override
  String get yourRatingLabel => 'Sua nota:';

  @override
  String get hintButton => 'Dica';

  @override
  String get showThemeButton => 'Ver tema';

  @override
  String get hintUsedButton => 'Dica usada';

  @override
  String get doneButton => 'Pronto';

  @override
  String get nextButton => 'Próximo';

  @override
  String get retryButton => 'Tentar de novo';

  @override
  String myPuzzleIntroMessage(String move, String classification) {
    return 'Você jogou $move nesta posição, e foi $classification. Tente achar um lance melhor.';
  }

  @override
  String get notBestMoveTryAgain =>
      'Esse não é o melhor lance aqui. Tente de novo e busque algo mais forte.';

  @override
  String get greatJobFoundBestMove => 'Muito bem! Você achou o melhor lance.';

  @override
  String myPuzzleHintPieceToMove(String piece, String square) {
    return 'Olhe sua $piece em $square. Essa é a peça que você deve mover.';
  }

  @override
  String get allMyPuzzlesSolvedMessage =>
      'Você resolveu todos os quebra-cabeças — bom trabalho!';

  @override
  String get noMyPuzzlesEmptyState =>
      'Ainda não há quebra-cabeças.\n\nTermine uma partida contra o Pippo — seus erros vão virar quebra-cabeças sozinhos.';

  @override
  String puzzleCounterTitle(int current, int total) {
    return 'Quebra-cabeça $current de $total';
  }

  @override
  String get finishButton => 'Terminar';

  @override
  String get nextPuzzleButton => 'Próximo quebra-cabeça';

  @override
  String get allThemesTitle => 'Todos os temas';

  @override
  String get allThemesIntro =>
      'Treine todo tipo de quebra-cabeça em um só lugar. Escolha um tema, teste seu nível e veja como você se sai em cada parte do jogo.';

  @override
  String get themesNeedInternetOffline =>
      'Os temas precisam de internet para carregar quebra-cabeças novos. Você está offline agora.';

  @override
  String get needsInternetForBatch => 'Precisa de internet para carregar novos';

  @override
  String get themeGroupMates => 'Mates';

  @override
  String get themeGroupTactics => 'Tática';

  @override
  String get themeGroupKingAttack => 'Ataque ao rei';

  @override
  String get themeGroupEndgames => 'Finais';

  @override
  String get themeGroupPawnsPromotion => 'Peões e promoção';

  @override
  String get themeGroupStrategy => 'Estratégia';

  @override
  String get themeMateIn1 => 'Mate em 1';

  @override
  String get themeMateIn1Desc => 'Ache o mate em um só lance.';

  @override
  String get themeMateIn2 => 'Mate em 2';

  @override
  String get themeMateIn2Desc =>
      'Prepare a posição e termine com mate no seu próximo lance.';

  @override
  String get themeMateIn3 => 'Mate em 3';

  @override
  String get themeMateIn3Desc =>
      'Ache a sequência vencedora que dá mate em três lances.';

  @override
  String get themeMateIn4 => 'Mate em 4';

  @override
  String get themeMateIn4Desc =>
      'Calcule alguns lances à frente para forçar o mate.';

  @override
  String get themeMateIn5 => 'Mate em 5';

  @override
  String get themeMateIn5Desc =>
      'Uma sequência de mate longa onde cada lance conta.';

  @override
  String get themeOtherMates => 'Outros mates';

  @override
  String get themeOtherMatesDesc =>
      'Padrões especiais como corredor, afogado, Anastasia, árabe, Boden, Opera e mais.';

  @override
  String get themeFork => 'Garfo';

  @override
  String get themeForkDesc =>
      'Uma peça ataca dois ou mais alvos ao mesmo tempo.';

  @override
  String get themePin => 'Cravada';

  @override
  String get themePinDesc =>
      'Uma peça fica presa porque sair dali expõe algo mais valioso.';

  @override
  String get themeSkewer => 'Espeto';

  @override
  String get themeSkewerDesc =>
      'Ataque uma peça valiosa e capture o que está escondido atrás.';

  @override
  String get themeDiscoveredAttack => 'Ataque descoberto';

  @override
  String get themeDiscoveredAttackDesc =>
      'Mova uma peça para liberar o ataque de outra.';

  @override
  String get themeDiscoveredCheck => 'Xeque descoberto';

  @override
  String get themeDiscoveredCheckDesc =>
      'Dê xeque ao tirar outra peça do caminho.';

  @override
  String get themeDoubleCheck => 'Xeque duplo';

  @override
  String get themeDoubleCheckDesc => 'Dê xeque com duas peças ao mesmo tempo.';

  @override
  String get themeSacrifice => 'Sacrifício';

  @override
  String get themeSacrificeDesc =>
      'Entregue material para ganhar algo mais forte em troca.';

  @override
  String get themeDeflection => 'Desvio';

  @override
  String get themeDeflectionDesc =>
      'Force uma peça a sair de onde ela precisa estar.';

  @override
  String get themeClearance => 'Limpeza';

  @override
  String get themeClearanceDesc =>
      'Tire uma peça do caminho para abrir passagem para outra.';

  @override
  String get themeCapturingDefender => 'Capturar o defensor';

  @override
  String get themeCapturingDefenderDesc =>
      'Elimine a peça que protege um alvo importante.';

  @override
  String get themeAdvancedTactics => 'Tática avançada';

  @override
  String get themeAdvancedTacticsDesc =>
      'Combinações mais difíceis com várias ideias táticas.';

  @override
  String get themeKingsideAttack => 'Ataque na ala do rei';

  @override
  String get themeKingsideAttackDesc =>
      'Lance um ataque contra o rei na ala do rei.';

  @override
  String get themeQueensideAttack => 'Ataque na ala da dama';

  @override
  String get themeQueensideAttackDesc =>
      'Busque como romper em volta do rei rival na ala da dama.';

  @override
  String get themeExposedKing => 'Rei exposto';

  @override
  String get themeExposedKingDesc =>
      'Aproveite um rei que perdeu sua proteção.';

  @override
  String get themeAttackingF2F7 => 'Ataque a F2 F7';

  @override
  String get themeAttackingF2F7Desc =>
      'Ataque a casa fraca f2 ou f7 junto ao rei.';

  @override
  String get themeEndgame => 'Final';

  @override
  String get themeEndgameDesc =>
      'Ache a melhor forma de jogar quando restam poucas peças.';

  @override
  String get themeRookEndgame => 'Final de torres';

  @override
  String get themeRookEndgameDesc =>
      'Aprenda a tirar o máximo das suas torres no final.';

  @override
  String get themeQueenEndgame => 'Final de damas';

  @override
  String get themeQueenEndgameDesc =>
      'Ache os lances bons em posições com damas no tabuleiro.';

  @override
  String get themeQueenRookEndgame => 'Final de dama e torre';

  @override
  String get themeQueenRookEndgameDesc =>
      'Jogue finais onde ainda há damas e torres.';

  @override
  String get themeBishopEndgame => 'Final de bispos';

  @override
  String get themeBishopEndgameDesc =>
      'Use seu bispo e seu rei para achar o plano vencedor.';

  @override
  String get themeKnightEndgame => 'Final de cavalos';

  @override
  String get themeKnightEndgameDesc =>
      'Ache os lances bons em finais onde os cavalos mandam.';

  @override
  String get themePawnEndgame => 'Final de peões';

  @override
  String get themePawnEndgameDesc =>
      'Calcule corridas de peões e ache o caminho da vitória.';

  @override
  String get themeZugzwang => 'Zugzwang';

  @override
  String get themeZugzwangDesc =>
      'Deixe o rival numa posição onde qualquer lance piora tudo.';

  @override
  String get themeAdvancedPawn => 'Peão avançado';

  @override
  String get themeAdvancedPawnDesc =>
      'Use um peão perigoso que entrou fundo no campo rival.';

  @override
  String get themePromotion => 'Promoção';

  @override
  String get themePromotionDesc =>
      'Leve um peão até o fim para trocar por uma peça mais forte.';

  @override
  String get themeUnderPromotion => 'Subpromoção';

  @override
  String get themeUnderPromotionDesc =>
      'Troque por algo que não seja dama quando isso é o que vence.';

  @override
  String get themeEnPassant => 'En passant';

  @override
  String get themeEnPassantDesc =>
      'Perceba a rara chance de capturar en passant.';

  @override
  String get themeQuietMove => 'Lance calmo';

  @override
  String get themeQuietMoveDesc =>
      'Ache um lance calmo que dá vantagem sem forçar tática.';

  @override
  String get themeDefensiveMove => 'Lance defensivo';

  @override
  String get themeDefensiveMoveDesc =>
      'Ache o lance que freia a ameaça do rival.';

  @override
  String get themeAdvantage => 'Vantagem';

  @override
  String get themeAdvantageDesc =>
      'Ache o lance que mantém ou aumenta sua vantagem.';

  @override
  String get themeEquality => 'Igualdade';

  @override
  String get themeEqualityDesc => 'Ache o lance que mantém a posição igual.';

  @override
  String get themeCrushing => 'Lance demolidor';

  @override
  String get themeCrushingDesc =>
      'Ache o lance forte que transforma uma boa posição em vencida.';

  @override
  String get pippoThinking2 => 'Deixe-me buscar o melhor lance';

  @override
  String get pippoThinking3 => 'Um momento... vejo algumas ideias';

  @override
  String get pippoThinking4 => 'Calculando minha resposta';

  @override
  String get pippoThreatAsk1 => 'Você vê o que este lance ameaça?';

  @override
  String get pippoThreatAsk2 =>
      'Tenho uma pequena ideia por trás desse lance...';

  @override
  String get pippoThreatAsk3 => 'Cuidado — esse lance põe algo sob pressão.';

  @override
  String get pippoThreatAsk4 =>
      'Pode ser que esse lance esconda mais do que parece.';

  @override
  String get pippoGreat1 => 'Muito bem por achar o único lance da posição!';

  @override
  String get pippoGreat2 => 'Foi um grande lance — muito bem visto.';

  @override
  String get pippoGreat3 =>
      'Achado excelente. Você jogou essa posição muito bem.';

  @override
  String get pippoBrilliant1 =>
      'Brilhante! Esse lance foi de uma precisão linda.';

  @override
  String get pippoBrilliant2 => 'Que ideia brilhante — não esperava por essa.';

  @override
  String get pippoBrilliant3 =>
      'Foi brilhante. Você achou um lance muito criativo.';

  @override
  String get pippoFinished1 => 'Que boa partida! Vamos jogar outra?';

  @override
  String get pippoFinished2 => 'Bem jogado! Quer outra?';

  @override
  String get pippoFinished3 => 'Boa partida — gostei. Revanche?';

  @override
  String get classificationBookComment => 'Um lance do livro de aberturas.';

  @override
  String get resignDialogTitle => 'Desistir da partida?';

  @override
  String get resignDialogBody =>
      'Tem certeza que quer desistir? Isso vai terminar a partida atual.';

  @override
  String get resignConfirm => 'Desistir';

  @override
  String get gameOverResignBlack => 'Pretas vencem por desistência';

  @override
  String get gameOverResignWhite => 'Brancas vencem por desistência';

  @override
  String get gameOverDefault => 'Fim de jogo';

  @override
  String get gameOverMateBlack => 'Pretas vencem por mate';

  @override
  String get gameOverMateWhite => 'Brancas vencem por mate';

  @override
  String get gameOverStalemate => 'Empate por afogado';

  @override
  String get gameOverRepetition => 'Empate por repetição';

  @override
  String get gameOverInsufficient => 'Empate por material insuficiente';

  @override
  String get gameOverDrawn => 'Partida empatada';

  @override
  String get playStartFirst => 'Comece uma partida primeiro';

  @override
  String get takebackTrainingOnly => 'Voltar lances só existe no modo Treino';

  @override
  String get takebackNoMoves => 'Sem lances para voltar';

  @override
  String get takebackDone => 'Lance desfeito';

  @override
  String get pippoMissBare => 'Você perdeu um lance melhor nesta posição.';

  @override
  String pippoMissWithMove(String move) {
    return 'Você perdeu um lance melhor nesta posição, devia ter jogado $move.';
  }

  @override
  String get pippoBlunderPause =>
      'Esse lance foi um erro grave. Desfaça, ou siga e eu continuo jogando.';

  @override
  String get hintTrainingOnly => 'Dicas só existem no modo Treino';

  @override
  String get hintYourTurnOnly => 'Dicas só existem na sua vez';

  @override
  String get hintStillAnalyzing => 'Ainda analisando... tente em um momento';

  @override
  String hintLookForPiece(String piece, String square) {
    return 'Busque um bom lance com sua $piece em $square.';
  }

  @override
  String get playToolTakeback => 'Voltar lance';

  @override
  String get playToolAskHint => 'Pedir dica ao Pippo';

  @override
  String get playToolClassifyHeader => 'Classificar';

  @override
  String get classifyYourMoves => 'Seus lances';

  @override
  String get classifyPippoMoves => 'Lances do Pippo';

  @override
  String get playingPippoTitle => 'Jogando contra o Pippo';

  @override
  String get resignButton => 'Desistir';

  @override
  String get playAsHeader => 'JOGUE DE';

  @override
  String get sideRandom => 'Aleatório';

  @override
  String get strengthHeader => 'FORÇA';

  @override
  String get optionsHeader => 'OPÇÕES';

  @override
  String get modeLabel => 'Modo';

  @override
  String get modeChallenge => 'Desafio';

  @override
  String get modeTraining => 'Treino';

  @override
  String get startGameButton => 'Começar partida';

  @override
  String get perkFeedback => 'Receba comentários sobre seus lances';

  @override
  String get perkSeeThreats => 'Veja todas as ameaças';

  @override
  String get perkTakeback => 'Volte lances quando quiser';

  @override
  String get perkBlunderPause => 'Pausa a partida se você errar feio';

  @override
  String get perkHintsAllowed => 'Dicas permitidas';

  @override
  String get perkNoFeedback => 'Sem comentários sobre lances';

  @override
  String get perkHiddenThreats => 'Ameaças escondidas';

  @override
  String get perkNoTakebacks => 'Sem voltar lances';

  @override
  String get perkNoBlunderPause => 'A partida segue após erros graves';

  @override
  String get perkNoHints => 'Sem dicas';

  @override
  String pippoEloLabel(int elo) {
    return '$elo ELO';
  }

  @override
  String get hideThreats => 'Esconder ameaças';

  @override
  String get showThreat => 'Mostrar ameaça';

  @override
  String get blunderContinue => 'Seguir';

  @override
  String get gameOverFallback => 'Fim de jogo';

  @override
  String get resultHome => 'Início';

  @override
  String get resultNewGame => 'Nova partida';

  @override
  String get resultAnalyzeGame => 'Analisar partida';

  @override
  String get gameToolsTooltip => 'Ferramentas de jogo';

  @override
  String get movesHeader => 'Lances';

  @override
  String moveCountLabel(int count) {
    return '$count lances';
  }

  @override
  String get movesEmptyPlay =>
      'Seus lances vão aparecer aqui enquanto você joga.';

  @override
  String get puzzleNotBest => 'Não é o melhor lance. Tente de novo!';

  @override
  String get puzzleSessionComplete => 'Sessão de treino completa!';

  @override
  String get practiceTitle => 'Treino';

  @override
  String get puzzleEmpty => 'Nenhum quebra-cabeça disponível.';

  @override
  String puzzleCounter(int current, int total) {
    return 'Quebra-cabeça $current/$total';
  }

  @override
  String get puzzleHint => 'Dica';

  @override
  String get puzzleShowMove => 'Ver lance';

  @override
  String get puzzleUsedHint => 'Dica usada';

  @override
  String get puzzleNext => 'Próximo quebra-cabeça';

  @override
  String get analysisTitle => 'Análise';

  @override
  String get addGameTooltip => 'Adicionar partida ou posição';

  @override
  String get closeGameButton => 'Fechar';

  @override
  String get positionLoadedOk => 'Posição carregada';

  @override
  String get gameImportedOk => 'Partida importada';

  @override
  String savedEventTitle(String opponent) {
    return 'AtlasChess vs $opponent';
  }

  @override
  String get youLabel => 'Você';

  @override
  String explorerGameLoaded(String white, String black) {
    return '$white vs $black carregada';
  }

  @override
  String get reviewNoGame => 'Sem partida para revisar';

  @override
  String get reviewQuotaUsed =>
      'Você já usou as revisões de hoje. Seja Pro para mais.';

  @override
  String get analysisNoMoves => 'Sem lances para analisar';

  @override
  String get settingsEngineHeader => 'Motor';

  @override
  String get settingsEnableEngine => 'Ativar motor';

  @override
  String get settingsDepth => 'Profundidade';

  @override
  String get settingsClassificationHeader => 'Classificação de lances';

  @override
  String get settingsEnableClassification => 'Ativar classificação';

  @override
  String get settingsThreatHeader => 'Detector de ameaças';

  @override
  String get settingsThreatToggle => 'Detector de ameaças';

  @override
  String get settingsLinesLabel => 'Número de linhas';

  @override
  String get filterBook => 'Livro';

  @override
  String get filterBrilliant => 'Brilhante';

  @override
  String get filterBlunder => 'Erro grave';

  @override
  String get showLess => 'Ver menos';

  @override
  String get showAll => 'Ver tudo';

  @override
  String get analyzingBanner =>
      'Sua partida está sendo analisada, você pode sair desta tela';

  @override
  String get fullViewTooltip => 'Visão completa';

  @override
  String get compactViewTooltip => 'Visão compacta';

  @override
  String get classifyingMove => 'Classificando lance...';

  @override
  String get phraseBest => 'o melhor lance';

  @override
  String get phraseBrilliant => 'um lance brilhante';

  @override
  String get phraseGreat => 'um grande lance';

  @override
  String get phraseExcellent => 'um lance excelente';

  @override
  String get phraseGood => 'um bom lance';

  @override
  String get phraseInaccuracy => 'uma imprecisão';

  @override
  String get phraseMistake => 'um erro';

  @override
  String get phraseBlunder => 'um erro grave';

  @override
  String get phraseMiss => 'uma chance perdida';

  @override
  String get phraseBook => 'um lance de livro';

  @override
  String get phraseForced => 'um lance forçado';

  @override
  String sentenceBestSuffix(String move) {
    return ', $move era o melhor lance';
  }

  @override
  String get retryReview => 'Tentar revisão de novo';

  @override
  String get reviewWaiting => 'Sua partida está sendo revisada';

  @override
  String get pgnEmpty => 'Ainda sem lances';

  @override
  String get pgnResume => 'Voltar';

  @override
  String get showBestTooltip => 'Mostrar melhor lance';

  @override
  String get tabMoves => 'Lances';

  @override
  String get tabExplorer => 'Explorador';

  @override
  String get moveTreeHeader => 'Árvore de lances';

  @override
  String get moveTreeEmpty => 'Seus lances e variações vão aparecer aqui.';

  @override
  String get gameReportButton => 'Relatório da partida';

  @override
  String get gameAnalysisTitle => 'Análise da partida';

  @override
  String get analyzeButton => 'Analisar';

  @override
  String get viewReportTooltip => 'Ver relatório';

  @override
  String get noReportYet => 'Ainda sem relatório';

  @override
  String get addToAnalysisTitle => 'Adicionar à análise';

  @override
  String get addToAnalysisSubtitle =>
      'Comece de uma partida, uma posição ou um tabuleiro livre.';

  @override
  String get importSegment => 'Importar';

  @override
  String get fenSegment => 'FEN';

  @override
  String get setupButton => 'Montar';

  @override
  String get gameReportTitle => 'Relatório da partida';

  @override
  String get accuraciesHeader => 'Precisão';

  @override
  String get accuracyRerunHint =>
      'Refaça a análise completa para calcular a precisão.';

  @override
  String get pastePgnTooltip => 'Colar PGN';

  @override
  String get pastePgnButton => 'Colar o PGN copiado';

  @override
  String get searchingLabel => 'Buscando...';

  @override
  String get importingLabel => 'Importando...';

  @override
  String get searchGamesButton => 'Buscar partidas';

  @override
  String get startAnalysisButton => 'Começar análise';

  @override
  String get fenFieldLabel => 'Posição (FEN)';

  @override
  String get pasteFenTooltip => 'Colar FEN';

  @override
  String get pasteFenButton => 'Colar o FEN copiado';

  @override
  String get loadPositionButton => 'Carregar posição';

  @override
  String get inputPgnText => 'Texto PGN';

  @override
  String get inputUsername => 'Nome de usuário';

  @override
  String get inputGameUrl => 'Link da partida';

  @override
  String get hintPastePgn => 'Cole o PGN aqui...';

  @override
  String get hintEnterUsername => 'Digite o usuário...';

  @override
  String get dialogOk => 'OK';

  @override
  String get lichessSignInCancelled => 'Login com Lichess cancelado';

  @override
  String get boardSetupTitle => 'Montar posição';

  @override
  String get flipBoardTooltip => 'Virar tabuleiro';

  @override
  String get clearBoardButton => 'Limpar tabuleiro';

  @override
  String get startPositionButton => 'Posição inicial';

  @override
  String get whoMovesHeader => 'QUEM JOGA PRIMEIRO';

  @override
  String get piecesHeader => 'PEÇAS';

  @override
  String get setupInstructions =>
      'Toque numa peça para escolher e depois toque no tabuleiro para colocar. Arraste uma peça para o tabuleiro para adicionar, ou para fora para tirar.';

  @override
  String get fenHeader => 'FEN';

  @override
  String get setupFinish => 'Terminar';

  @override
  String engineDepthLabel(int depth) {
    return 'Profundidade $depth';
  }

  @override
  String get analyzeGameTitle => 'Analisar partida';

  @override
  String get reviewsUnlimited => 'Revisões ilimitadas hoje';

  @override
  String reviewsLeftToday(int done, int total) {
    return '$done/$total revisões disponíveis hoje';
  }

  @override
  String get analyzeTypeHeader => 'Tipo';

  @override
  String get analyzeModeAnalysis => 'Análise';

  @override
  String get analyzeModeAnalysisDesc =>
      'Classifica todos os lances da sua partida com Stockfish';

  @override
  String get analyzeModeReview => 'Revisão';

  @override
  String get upgradeToProTitle => 'Seja Pro';

  @override
  String get reviewModeDesc => 'Explicações lance a lance da sua partida';

  @override
  String get reviewLockedDesc => 'Desbloqueie mais revisões todo dia';

  @override
  String get engineDepthHeader => 'Profundidade do motor';

  @override
  String depthValueLabel(int depth) {
    return 'Profundidade $depth';
  }

  @override
  String get depthHint => 'Mais profundidade pode demorar mais para analisar';

  @override
  String get selectGameTitle => 'Escolha uma partida';

  @override
  String get versusShort => 'vs';

  @override
  String get speedBullet => 'Bullet';

  @override
  String get speedBlitz => 'Blitz';

  @override
  String get speedRapid => 'Rápidas';

  @override
  String get speedClassical => 'Clássicas';

  @override
  String get openingExplorerTitle => 'Explorador de aberturas';

  @override
  String get dbMasters => 'Mestres';

  @override
  String get filtersHeader => 'Filtros';

  @override
  String get theoreticalMoves => 'Lances teóricos';

  @override
  String get topMasterGames => 'Melhores partidas de mestres';

  @override
  String get recentGames => 'Partidas recentes';

  @override
  String get explorerSignInDesc =>
      'Entre com Lichess para explorar milhões de partidas, partidas de mestres e estatísticas de aberturas.';

  @override
  String get signInWithLichess => 'Entrar com Lichess';

  @override
  String get noOpeningData => 'Sem dados de abertura';

  @override
  String gamesCountLabel(int count) {
    return '$count partidas';
  }

  @override
  String get unknownPlayer => 'Desconhecido';

  @override
  String get monthJanuary => 'janeiro';

  @override
  String get monthFebruary => 'fevereiro';

  @override
  String get monthMarch => 'março';

  @override
  String get monthApril => 'abril';

  @override
  String get monthMay => 'maio';

  @override
  String get monthJune => 'junho';

  @override
  String get monthJuly => 'julho';

  @override
  String get monthAugust => 'agosto';

  @override
  String get monthSeptember => 'setembro';

  @override
  String get monthOctober => 'outubro';

  @override
  String get monthNovember => 'novembro';

  @override
  String get monthDecember => 'dezembro';

  @override
  String get indicatorGreen => 'Verde';

  @override
  String get indicatorAmber => 'Âmbar';

  @override
  String get indicatorRed => 'Vermelho';

  @override
  String get clsBest => 'A melhor';

  @override
  String get clsBrilliant => 'Brilhante';

  @override
  String get clsGreat => 'Genial';

  @override
  String get clsExcellent => 'Excelente';

  @override
  String get clsGood => 'Boa';

  @override
  String get clsInaccuracy => 'Imprecisão';

  @override
  String get clsMistake => 'Erro';

  @override
  String get clsBlunder => 'Erro grave';

  @override
  String get clsBook => 'Livro';

  @override
  String get clsForced => 'Forçada';

  @override
  String get clsMiss => 'Chance perdida';

  @override
  String averageRatingLabel(int rating) {
    return 'Média $rating';
  }

  @override
  String classificationSentence(String move, String label) {
    return '$move é $label';
  }

  @override
  String reviewBestHint(String explanation, String move) {
    return '$explanation $move era o melhor lance.';
  }
}
