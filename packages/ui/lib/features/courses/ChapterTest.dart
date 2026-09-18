import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:chess/chess.dart' as chess;
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';

import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/ExplanationEditDialog.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';

enum TestFeedback { idle, correct, wrong, hint }

class ChapterTest extends StatefulWidget {
  final CourseModel course;
  final int chapterIndex;

  const ChapterTest({
    super.key,
    required this.course,
    required this.chapterIndex,
  });

  @override
  State<ChapterTest> createState() => _ChapterTestState();
}

class _ChapterTestState extends State<ChapterTest> {
  late final CourseChapterModel _chapter =
      widget.course.chapters[widget.chapterIndex];
  late final ChessboardController _controller = ChessboardController();
  late final ChessboardSettings _boardSettings = ChessboardSettings(
    orientation: widget.course.side.toLowerCase() == 'black'
        ? BoardOrientation.black
        : BoardOrientation.white,
  );

  bool _isResultsStage = false;
  int _testIdx = 0;
  int _currentPlyIdx = 0;
  TestFeedback _feedback = TestFeedback.idle;
  String? _hintMessage;
  // Editable MongoDB-backed hint currently shown in the Pippo bubble, or null
  // while the bubble is hidden. Non-null also makes the pencil icon appear.
  CourseMoveModel? _hintEditTarget;
  bool _isAutoPlaying = false;
  bool _isInitializing = true;
  bool _isLocked = false;

  /// Whether the signed-in account is a verified admin.
  ///
  /// The hint text is shared by every student of the chapter, so the hint editor
  /// is an admin-only feature. The pencil icon stays hidden until
  /// [CourseApiService.isVerifiedAdmin] confirms the account, and the service
  /// refuses the write anyway — this only keeps the UI honest.
  bool _isAdmin = false;
  List<CourseVariationModel> _shuffledVariations = [];

  /// The side the human is playing (the bottom of the board).
  bool get _isUserWhite => widget.course.side.toLowerCase() == 'white';

  CourseVariationModel? get _variation =>
      _shuffledVariations.isNotEmpty && _testIdx < _shuffledVariations.length
          ? _shuffledVariations[_testIdx]
          : null;

  /// Total plies across every variation in the whole test.
  int get _totalPlies {
    var total = 0;
    for (final v in _shuffledVariations) {
      total += v.plies.length;
    }
    return total;
  }

  /// Plies completed so far (all earlier variations + the current index).
  int get _completedPlies {
    var completed = 0;
    for (var i = 0; i < _testIdx && i < _shuffledVariations.length; i++) {
      completed += _shuffledVariations[i].plies.length;
    }
    return completed + _currentPlyIdx;
  }

  /// A ply belongs to the human whenever its colour matches the human's side.
  bool _isUserTurn(CourseMoveModel move) {
    final isWhiteMove = move.ply % 2 != 0;
    return (isWhiteMove && _isUserWhite) || (!isWhiteMove && !_isUserWhite);
  }

  @override
  void initState() {
    super.initState();
    _shuffledVariations = List.from(_chapter.variations)..shuffle();
    _resolveAdmin();
    // Wait for the first frame so the board has had a chance to lay out.
    // For a "black" (black-side) opening this immediately schedules the
    // opponent's first move.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeTest();
    });
  }

  /// Enables the hint editor only for a verified admin.
  ///
  /// Never fails open: anything other than a positively confirmed admin (signed
  /// out, guest, non-admin, offline read) leaves the pencil icon hidden.
  Future<void> _resolveAdmin() async {
    final isAdmin = await CourseApiService.isVerifiedAdmin();
    if (!mounted || !isAdmin) return;
    setState(() => _isAdmin = true);
  }

  Future<void> _initializeTest() async {
    final allowed = await UserCourseProgressService.startChapter(
      courseSlug: widget.course.slug,
      courseName: widget.course.openingName,
      chapterIndex: widget.chapterIndex,
      chapterName: _chapter.name,
    );
    if (!mounted) return;
    setState(() {
      _isInitializing = false;
      _isLocked = !allowed;
    });
    if (allowed) _loadCurrentVariation();
  }

  // =========================================================================
  // TEST DRIVE
  // =========================================================================

  void _loadCurrentVariation() {
    if (_isResultsStage) return;
    setState(() {
      _currentPlyIdx = 0;
      _feedback = TestFeedback.idle;
      _hintMessage = null;
      _hintEditTarget = null;
      _isAutoPlaying = false;
      _controller.reset();
    });
    _processNext();
  }

  void _processNext() {
    if (_isResultsStage || _isAutoPlaying) return;

    final variation = _variation;
    if (variation == null || _currentPlyIdx >= variation.plies.length) {
      if (_testIdx + 1 >= _shuffledVariations.length) {
        _completeTest();
      } else {
        setState(() {
          _testIdx++;
          _currentPlyIdx = 0;
          _feedback = TestFeedback.idle;
          _hintMessage = null;
          _hintEditTarget = null;
          _isAutoPlaying = false;
          _controller.reset();
        });
        _processNext();
      }
      return;
    }

    final move = variation.plies[_currentPlyIdx];
    if (!_isUserTurn(move)) {
      _playOpponentMove(move);
    }
  }

  /// Smoothly plays the opponent's reply after a short "thinking" delay.
  Future<void> _playOpponentMove(CourseMoveModel move) async {
    setState(() {
      _isAutoPlaying = true;
      _feedback = TestFeedback.idle;
      _hintMessage = null;
      _hintEditTarget = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || _isResultsStage) return;

    if (!_applyMoveToController(move) && move.fen.isNotEmpty) {
      _controller.loadFen(move.fen);
    }

    setState(() {
      _isAutoPlaying = false;
      _currentPlyIdx++;
      _feedback = TestFeedback.idle;
    });

    _processNext();
  }

  bool _applyMoveToController(CourseMoveModel move) {
    if (move.move.isNotEmpty && _controller.makeMoveFromSan(move.move)) {
      return true;
    }
    if (move.move.length >= 4) {
      return _controller.makeMove(
        move.move.substring(0, 2),
        move.move.substring(2, 4),
        promotion: move.move.length > 4 ? move.move.substring(4, 5) : 'q',
      );
    }
    return false;
  }

  // =========================================================================
  // USER INPUT
  // =========================================================================

  Future<void> _handleUserMove(String from, String to) async {
    if (_isResultsStage || _isAutoPlaying) return;
    if (_feedback == TestFeedback.correct || _feedback == TestFeedback.wrong) {
      return;
    }

    final variation = _variation;
    if (variation == null || _currentPlyIdx >= variation.plies.length) return;

    final expectedPly = variation.plies[_currentPlyIdx];
    if (!_isUserTurn(expectedPly)) return;

    final tempGame = chess.Chess.fromFEN(_controller.game.generate_fen());
    final moveResult =
        tempGame.move({'from': from, 'to': to, 'promotion': 'q'});

    if (moveResult == true) {
      final moveInfo = tempGame.undo();
      final san = moveInfo!['san'];
      if (_movesMatch(san, expectedPly.move)) {
        setState(() {
          _feedback = TestFeedback.correct;
          _hintMessage = null;
          _hintEditTarget = null;
        });
        _controller.makeMove(from, to);

        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;

        setState(() {
          _feedback = TestFeedback.idle;
          _currentPlyIdx++;
        });
        _processNext();
        return;
      }
    }

    await _showWrongMove(from);
  }

  Future<void> _showWrongMove(String from) async {
    setState(() {
      _feedback = TestFeedback.wrong;
      _hintMessage = null;
      _hintEditTarget = null;
    });

    final movingPiece = _controller.game.get(from);
    if (movingPiece != null) {
      _controller.setVisualOverride({'from': null, 'to': movingPiece});
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _feedback = TestFeedback.idle;
      _controller.setVisualOverride(null);
    });
  }

  void _showHint() {
    final variation = _variation;
    if (variation == null || _currentPlyIdx >= variation.plies.length) return;
    final expectedPly = variation.plies[_currentPlyIdx];
    if (!_isUserTurn(expectedPly)) return;

    setState(() {
      _hintMessage = expectedPly.hint.isNotEmpty
          ? expectedPly.hint
          : AppLocalizations.of(context)
              .thinkAboutMovesHint(expectedPly.move[0].toUpperCase());
      // Only MongoDB-backed hints can be edited through the pencil icon; the
      // generic fallback text has nothing stored to update.
      _hintEditTarget = expectedPly.hint.isNotEmpty ? expectedPly : null;
      _feedback = TestFeedback.hint;
    });
  }

  /// Opens the edit dialog for the currently shown MongoDB-backed hint and
  /// persists the change, so every future student testing this chapter gets
  /// the updated hint. Mirrors [_editExplanation] in ChapterStudy.
  Future<void> _editHint() async {
    // Second gate behind the hidden pencil: only a verified admin may rewrite
    // the hint, and CourseApiService refuses the write even if this is bypassed.
    if (!_isAdmin) return;
    final target = _hintEditTarget;
    if (target == null) return;
    // _shuffledVariations reorders the chapter's variations for the test, so
    // _testIdx is NOT the variation's index in MongoDB. Map the variation
    // object back to its original position (the list copies references).
    final variation = _variation;
    if (variation == null) return;
    final variationIndex = _chapter.variations.indexOf(variation);
    if (variationIndex < 0) return;
    final plyIndex = _currentPlyIdx;
    final currentHint = target.hint;

    final result = await ExplanationEditDialog.show(
      context,
      title: AppLocalizations.of(context).hintForMoveTitle(target.move),
      initialText: currentHint,
      hintText: AppLocalizations.of(context).writeHintPlaceholder,
    );
    if (!mounted || result == null) return; // Cancel/dismiss: keep old hint.

    final newHint = result.trim();
    if (newHint.isEmpty || newHint == currentHint.trim()) return;

    final ok = await CourseApiService.updateMoveHint(
      courseSlug: widget.course.slug,
      chapterIndex: widget.chapterIndex,
      variationIndex: variationIndex,
      plyIndex: plyIndex,
      hint: newHint,
    );
    if (!mounted) return;

    if (ok) {
      target.hint = newHint;
      // Live-update the bubble if this exact ply is still being shown.
      if (_hintEditTarget == target && _currentPlyIdx == plyIndex) {
        _hintMessage = newHint;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).hintUpdatedMessage),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the hint. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completeTest() {
    unawaited(UserCourseProgressService.markChapterTestCompleted(
      courseSlug: widget.course.slug,
      chapterIndex: widget.chapterIndex,
    ));
    setState(() {
      _isResultsStage = true;
      _isAutoPlaying = false;
    });
  }

  String _normalizeSan(String san) {
    return san
        .replaceAll(RegExp(r'[+#!?]'), '')
        .replaceAll('0-0-0', 'O-O-O')
        .replaceAll('0-0', 'O-O');
  }

  bool _movesMatch(String a, String b) {
    return _normalizeSan(a) == _normalizeSan(b);
  }
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isLocked) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).masteryTestTitle),
          backgroundColor: AppColors.backgroundOf(context),
          foregroundColor: AppColors.textPrimaryOf(context),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context).freeUsersUnlockOneChapterPerDay,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (_isResultsStage) return _buildResultsView(context);

    final variation = _variation;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).masteryTestTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.textSecondaryOf(context),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 48,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildPippoChatSection(context),
          const SizedBox(height: 12),
          Expanded(child: _buildBoard(context)),
          _buildInfoPanel(context, variation),
        ],
      ),
    );
  }

  // =========================================================================
  // PIPPO CHAT BUBBLE (above the chessboard)
  //
  // All game status text lives here — hint, "Correct!", "Not quite",
  // "Opponent is thinking…", "Your move…" — styled exactly like the Pippo
  // chat bubble in ChapterStudy: Pippo logo + rounded speech bubble. The
  // pencil icon appears only while a MongoDB-backed hint is shown.
  // =========================================================================

  /// Resolves the status text currently shown by the Pippo bubble.
  String get _pippoMessage {
    final l10n = AppLocalizations.of(context);
    switch (_feedback) {
      case TestFeedback.hint:
        return _hintMessage ?? l10n.thinkItThrough;
      case TestFeedback.correct:
        return l10n.correctFeedback;
      case TestFeedback.wrong:
        return l10n.notQuiteTryAgain;
      default:
        return _isAutoPlaying
            ? l10n.opponentThinkingTest
            : l10n.yourMovePlayOpeningLine;
    }
  }

  Widget _buildPippoChatSection(BuildContext context) {
    // The pencil icon only makes sense while an editable hint is displayed.
    final showPencil = _isAdmin &&
        _feedback == TestFeedback.hint &&
        _hintEditTarget != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PippoAvatar(size: 44, cornerRadius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: AppColors.borderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 28),
                    child: Text(
                      _pippoMessage,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  if (showPencil)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                          maxWidth: 32,
                          maxHeight: 32,
                        ),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textTertiaryOf(context),
                        ),
                        tooltip: AppLocalizations.of(context).editHintTooltip,
                        onPressed: _editHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final bool isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Largest square that fits, minus the settings row reserved by
          // ChessBoard.
          final double maxBoardSize =
              (constraints.maxWidth < constraints.maxHeight - 48)
                  ? constraints.maxWidth
                  : constraints.maxHeight - 48;

          return Center(
            child: Container(
              width: maxBoardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getBoardBorderColor(context),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.28 : 0.08,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ChessBoard(
                controller: _controller,
                settings: _boardSettings,
                onMove: _handleUserMove,
                enableFreeMove: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBoardBorderColor(BuildContext context) {
    switch (_feedback) {
      case TestFeedback.correct:
        return AppColors.success;
      case TestFeedback.wrong:
        return AppColors.error;
      default:
        return AppColors.borderOf(context);
    }
  }
Widget _buildInfoPanel(
    BuildContext context,
    CourseVariationModel? variation,
  ) {
    final double progress = _totalPlies == 0
        ? 0.0
        : (_completedPlies / _totalPlies).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).variationLabelUpper,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTertiaryOf(context),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      variation?.name ?? '—',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCounterChip(context),
            ],
          ),
          const SizedBox(height: 14),
          _buildProgressBar(context, progress),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).overallProgressLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              Text(
                AppLocalizations.of(context)
                    .pliesProgressCounter(_completedPlies, _totalPlies),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFooterButtons(context),
        ],
      ),
    );
  }

  Widget _buildCounterChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_testIdx + 1} / ${_shuffledVariations.length}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtleOf(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
        ),
      ),
    );
  }
Widget _buildFooterButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildGhostButton(
            context,
            label: AppLocalizations.of(context).abortButton,
            icon: Icons.close_rounded,
            color: AppColors.error,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGhostButton(
            context,
            label: AppLocalizations.of(context).getHintButton,
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            onPressed: _showHint,
          ),
        ),
      ],
    );
  }

  Widget _buildGhostButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.10),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(58),
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.success,
                    size: 62,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.chapterPassedTitle,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.youInternalizedChapter(_chapter.name),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.variationsCompletedCount(_shuffledVariations.length),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              AtlasButton(
                label: l10n.returnToCourseButton,
                useGradient: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
