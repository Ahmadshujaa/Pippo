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

enum StudyState { initial, playing, variationCompleted, chapterCompleted }

class ChapterStudy extends StatefulWidget {
  final CourseModel course;
  final int chapterIndex;

  const ChapterStudy({
    super.key,
    required this.course,
    required this.chapterIndex,
  });

  @override
  State<ChapterStudy> createState() => _ChapterStudyState();
}

class _ChapterStudyState extends State<ChapterStudy> {
  late final CourseChapterModel _chapter =
      widget.course.chapters[widget.chapterIndex];
  late final ChessboardController _controller = ChessboardController();

  // Lazy initializer (not initState) so it survives hot reloads, which don't
  // re-run initState on existing State objects.
  late BoardOrientation _boardOrientation =
      widget.course.side.toLowerCase() == 'black'
          ? BoardOrientation.black
          : BoardOrientation.white;

  int _selectedVariationIndex = 0;
  int _frontierIndex = -1; // The next move to be played
  int _viewIndex = -1; // The move currently shown on board (-1 is start)
  StudyState _state = StudyState.initial;
  bool _isOpponentThinking = false;
  bool _isProcessingMove = false;
  String _commentary = '';

  /// Whether an explanation edit is currently being persisted to MongoDB.
  bool _isSavingEdit = false;

  /// Whether the signed-in account is a verified admin.
  ///
  /// Course content is shared by every account, so the pencil editors are an
  /// admin-only feature. They stay hidden until
  /// [CourseApiService.isVerifiedAdmin] confirms the account, and the service
  /// refuses the write anyway — this only keeps the UI honest.
  bool _isAdmin = false;

  List<CourseMoveModel> _activeLine = [];
  CourseBranchModel? _activeBranch;
  int? _activeBranchIndex;
  bool _mainLineCompleted = false;
  final Set<int> _completedBranchIndices = <int>{};
  final Set<int> _completedVariationIndices = <int>{};
  bool get _isUserWhite => widget.course.side.toLowerCase() == 'white';

  /// The chapter has been started: variations are unlocked and the board
  /// controls are visible.
  bool get _chapterStarted => _state != StudyState.initial;

  /// Variations / branches may be tapped to study them directly. They are
  /// always locked before the chapter is started and after it is finished.
  bool get _canTapVariations =>
      _state == StudyState.playing ||
      _state == StudyState.variationCompleted;

  @override
  void initState() {
    super.initState();
    _commentary = _chapter.description;
    _hydrateProgress();
    _resolveAdmin();
  }

  /// Enables the pencil editors only for a verified admin.
  ///
  /// Never fails open: anything other than a positively confirmed admin (signed
  /// out, guest, non-admin, offline read) leaves the icons hidden.
  Future<void> _resolveAdmin() async {
    final isAdmin = await CourseApiService.isVerifiedAdmin();
    if (!mounted || !isAdmin) return;
    setState(() => _isAdmin = true);
  }

  Future<void> _hydrateProgress() async {
    final progress = await UserCourseProgressService.getProgress();
    final course = progress.forCourse(widget.course.slug);
    UserChapterProgress? chapter;
    if (course != null) {
      for (final candidate in course.chapters) {
        if (candidate.index == widget.chapterIndex) {
          chapter = candidate;
          break;
        }
      }
    }
    final savedChapter = chapter;
    if (!mounted || savedChapter == null) return;
    setState(() {
      _completedVariationIndices
        ..clear()
        ..addAll(savedChapter.variations.map((variation) => variation.index));
    });
  }

  /// Unlocks the chapter and immediately starts studying the first variation.
  Future<void> _startChapter() async {
    final allowed = await UserCourseProgressService.startChapter(
      courseSlug: widget.course.slug,
      courseName: widget.course.openingName,
      chapterIndex: widget.chapterIndex,
      chapterName: _chapter.name,
    );
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).freeUsersUnlockOneChapterPerDay)),
      );
      return;
    }
    _loadVariation(0);
  }

  void _loadVariation(int index) {
    if (_chapter.variations.isEmpty) {
      setState(() {
        _selectedVariationIndex = 0;
        _frontierIndex = -1;
        _viewIndex = -1;
        _state = StudyState.initial;
        _isOpponentThinking = false;
        _commentary = AppLocalizations.of(context).noVariationsForChapterYet;
        _activeLine = [];
        _activeBranch = null;
        _controller.reset();
      });
      return;
    }
    final variation = _chapter.variations[index];
    setState(() {
      _selectedVariationIndex = index;
      _activeBranch = null;
      _activeBranchIndex = null;
      _mainLineCompleted = false;
      _completedBranchIndices.clear();
      _activeLine = _buildActiveLine(variation.plies);
      _frontierIndex = 0;
      _viewIndex = -1;
      _state = StudyState.playing;
      _isOpponentThinking = false;
      _isProcessingMove = false;
      // Prompt the first move (e.g. "Play e4"): the first move usually has no
      // explanation yet, so just like Start Chapter, ignore everything else.
      final String firstMove = _activeLine.isNotEmpty ? _activeLine.first.move : '';
      _commentary = firstMove.isNotEmpty
          ? AppLocalizations.of(context).playMovePrompt(firstMove)
          : (variation.description.isNotEmpty
              ? variation.description
              : _chapter.description);
      _controller.reset();
    });

    unawaited(UserCourseProgressService.startVariation(
      courseSlug: widget.course.slug,
      chapterIndex: widget.chapterIndex,
      variationIndex: index,
      variationName: variation.name,
    ));

    _processNextMove();
  }

  void _loadBranch(CourseBranchModel branch) {
    if (_chapter.variations.isEmpty) return;
    final variation = _chapter.variations[_selectedVariationIndex];
    _activeBranchIndex = variation.branches.indexOf(branch);
    setState(() {
      _activeBranch = branch;
      _activeLine = _buildActiveLine(variation.plies, branch.plies);
      // The study starts at the first move that belongs to the branch.
      int branchStart =
          _activeLine.indexWhere((p) => identical(p, branch.plies.first));
      if (branchStart == -1) {
        branchStart =
            _activeLine.indexWhere((p) => p.ply == branch.plies.first.ply);
      }
      if (branchStart == -1) branchStart = 0;
      _frontierIndex = branchStart;
      _viewIndex = _frontierIndex - 1;
      _state = StudyState.playing;
      _isOpponentThinking = false;
      _isProcessingMove = false;
      _commentary = _commentaryForLineStart(branch.explanation);
      _controller.reset();
    });

    // Replay the moves played before the branch so the board shows the
    // position where the branch diverges.
    for (var i = 0; i < _frontierIndex; i++) {
      if (!_applyMoveToController(_activeLine[i])) {
        // Fall back to loading the FEN directly if a prefix move can't be
        // applied (e.g. data is stored in an unexpected format).
        if (_activeLine[i].fen.isNotEmpty) {
          _controller.loadFen(_activeLine[i].fen);
        }
        break;
      }
    }

    _processNextMove();
  }

  /// Appends a "Play X" prompt to [base] when the next move belongs to the
  /// user, so they always know it is their turn and what is expected.
  String _commentaryForLineStart(String base) {
    if (_frontierIndex < 0 || _frontierIndex >= _activeLine.length) {
      return base;
    }
    final nextMove = _activeLine[_frontierIndex];
    final isWhiteMove = (nextMove.ply % 2 != 0);
    final isUserTurn = (isWhiteMove && _isUserWhite) ||
        (!isWhiteMove && !_isUserWhite);
    if (!isUserTurn) return base;
    final prompt = AppLocalizations.of(context).playMovePrompt(nextMove.move);
    if (base.isEmpty) return prompt;
    return '$base\n\n$prompt';
  }

  List<CourseMoveModel> _buildActiveLine(
    List<CourseMoveModel> basePlies, [
    List<CourseMoveModel>? branchPlies,
  ]) {
    List<CourseMoveModel> fullLine;
    if (branchPlies == null || branchPlies.isEmpty) {
      fullLine = List.from(basePlies);
    } else {
      final firstBranchPly = branchPlies.first.ply;
      final prefix = basePlies.where((p) => p.ply < firstBranchPly).toList();
      fullLine = [...prefix, ...branchPlies];
    }
    _calculateFens(fullLine);
    return fullLine;
  }

  void _calculateFens(List<CourseMoveModel> plies) {
    final tempGame = chess.Chess();
    for (var i = 0; i < plies.length; i++) {
      final success = tempGame.move(plies[i].move);
      if (success) {
        plies[i].fen = tempGame.generate_fen();
      } else {
        debugPrint(
          "ChapterStudy: Failed to calculate FEN for move ${plies[i].move} at ply ${plies[i].ply}",
        );
      }
    }
  }

  /// Applies a course move (SAN first, UCI fallback) to the controller so the
  /// board's move tree stays navigable with the board controls.
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

  void _processNextMove() {
    if (_state != StudyState.playing) return;

    if (_frontierIndex >= _activeLine.length) {
      _completeVariation();
      return;
    }

    final move = _activeLine[_frontierIndex];

    final isWhiteMove = (move.ply % 2 != 0);
    final isUserTurn = (isWhiteMove && _isUserWhite) ||
        (!isWhiteMove && !_isUserWhite);

    if (!isUserTurn) {
      _playOpponentMove(move);
    }
  }

  Future<void> _playOpponentMove(CourseMoveModel move) async {
    setState(() {
      _isOpponentThinking = true;
      _commentary = AppLocalizations.of(context).opponentThinking;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // The chapter may have been restarted / abandoned while we were thinking.
    if (_state != StudyState.playing) return;

    if (!_applyMoveToController(move) && move.fen.isNotEmpty) {
      _controller.loadFen(move.fen);
    }

    setState(() {
      _isOpponentThinking = false;
      _viewIndex = _frontierIndex;
      _frontierIndex++;
      _commentary = move.explanation.isNotEmpty
          ? move.explanation
          : AppLocalizations.of(context).opponentPlayedMove(move.move);
    });

    _processNextMove();
  }

  Future<void> _handleUserMove(String from, String to) async {
    if (_state != StudyState.playing ||
        _isOpponentThinking ||
        _isProcessingMove) {
      return;
    }
    // Only allow moves at the frontier.
    if (_viewIndex != _frontierIndex - 1) {
      return;
    }
    if (_frontierIndex >= _activeLine.length) {
      return;
    }

    _isProcessingMove = true;

    final expectedMove = _activeLine[_frontierIndex];

    final tempGame = chess.Chess.fromFEN(_controller.game.generate_fen());
    bool isLegal = tempGame.move({'from': from, 'to': to, 'promotion': 'q'});

    if (isLegal) {
      final userFen = tempGame.generate_fen();
      if (userFen == expectedMove.fen) {
        _controller.makeMove(from, to);
        setState(() {
          _viewIndex = _frontierIndex;
          _frontierIndex++;
          _commentary = expectedMove.explanation.isNotEmpty
              ? expectedMove.explanation
              : AppLocalizations.of(context).correctMoveWithName(expectedMove.move);
        });
        _isProcessingMove = false;
        _processNextMove();
        return;
      }
    }

    // Wrong or Illegal move: Revert and show the previous explanation.
    setState(() {
      _commentary = AppLocalizations.of(context).notRightMove;
    });

    // Create a visual override to keep the piece at the wrong square.
    final movingPiece = _controller.game.get(from);
    if (movingPiece != null) {
      _controller.setVisualOverride({
        from: null, // Empty the source square
        to: movingPiece, // Place the piece on the wrong square
      });
    }

    // Wait 1 second with the piece at the wrong square.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Clear the visual override: the controller was never changed by the
    // wrong move, so the board snaps straight back to the correct position.
    setState(() {
      _controller.setVisualOverride(null);
    });

    // Restore the explanation after a short delay (once the piece snaps back).
    final int currentViewIndex = _viewIndex;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      // Only restore if the user hasn't already moved to a new position.
      if (_viewIndex == currentViewIndex &&
          _commentary == AppLocalizations.of(context).notRightMove) {
        setState(() {
          _commentary = _viewIndex >= 0
              ? _activeLine[_viewIndex].explanation
              : _chapter.description;
        });
      }
    });

    _isProcessingMove = false;
  }

  void _completeVariation() {
    final variation = _chapter.variations[_selectedVariationIndex];
    if (_activeBranch == null) {
      _mainLineCompleted = true;
      unawaited(UserCourseProgressService.markVariationMainLineCompleted(
        courseSlug: widget.course.slug,
        chapterIndex: widget.chapterIndex,
        variationIndex: _selectedVariationIndex,
      ));
    } else if (_activeBranchIndex != null) {
      _completedBranchIndices.add(_activeBranchIndex!);
      unawaited(UserCourseProgressService.markVariationBranchCompleted(
        courseSlug: widget.course.slug,
        chapterIndex: widget.chapterIndex,
        variationIndex: _selectedVariationIndex,
        branchIndex: _activeBranchIndex!,
      ));
    }
    final isComplete = _mainLineCompleted &&
        _completedBranchIndices.length >= variation.branches.length;
    if (isComplete) {
      _completedVariationIndices.add(_selectedVariationIndex);
      unawaited(UserCourseProgressService.completeVariation(
        courseSlug: widget.course.slug,
        chapterIndex: widget.chapterIndex,
        variationIndex: _selectedVariationIndex,
        branchCount: variation.branches.length,
      ));
    }
    setState(() {
      _state = StudyState.variationCompleted;
      _commentary = AppLocalizations.of(context).variationCompletedMessage;
    });
  }

  // =========================================================================
  // EXPLANATION EDITING
  //
  // Every text shown in the Pippo bubble that comes from MongoDB (chapter
  // description, variation theory, branch explanation, move explanation) can
  // be edited through a pencil icon. Saving writes the new text to the exact
  // nested field of the interactive_courses document, so every future student
  // of the course sees the updated explanation. Cancel discards the change.
  // =========================================================================

  Future<void> _editExplanation({
    required String title,
    required String currentText,
    required Future<bool> Function(String newText) onSave,
  }) async {
    // Second gate behind the hidden icon: only a verified admin opens the
    // editor, and CourseApiService refuses the write even if this is bypassed.
    if (!_isAdmin) return;
    if (_isSavingEdit) return;
    if (!mounted) return;

    // The TextField's controller is owned by the shared dialog's State (see
    // ExplanationEditDialog) so it is disposed only once the dialog route is
    // fully torn down, after its exit animation finishes. Disposing it here
    // — while the animating-out TextField still listens to it — crashes with
    // "A TextEditingController was used after being disposed".
    final result = await ExplanationEditDialog.show(
      context,
      title: title,
      initialText: currentText,
    );

    if (result == null) {
      return; // Cancel (or dismissed): keep the current text untouched.
    }

    final newText = result.trim();
    if (newText == currentText.trim()) return; // Nothing changed.

    setState(() => _isSavingEdit = true);
    bool saved = false;
    try {
      saved = await onSave(newText);
    } catch (e) {
      debugPrint('ChapterStudy: explanation edit failed: $e');
    }
    if (!mounted) return;
    setState(() => _isSavingEdit = false);

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).explanationUpdatedMessage),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the explanation. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showBranchesDialog() {
    final variation = _chapter.variations[_selectedVariationIndex];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).alternativeBranchesTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            ...variation.branches.map((b) => ListTile(
                  leading: const Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(b.name),
                  subtitle: Text(b.explanation),
                  trailing: _pencilButton(
                    tooltip: AppLocalizations.of(context).editBranchExplanationTooltip,
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet first.
                      _editExplanation(
                        title: AppLocalizations.of(context).branchEditTitle(b.name),
                        currentText: b.explanation,
                        onSave: (newText) async {
                          final ok = await CourseApiService.updateBranchExplanation(
                            courseSlug: widget.course.slug,
                            chapterIndex: widget.chapterIndex,
                            variationIndex: _selectedVariationIndex,
                            branchIndex: variation.branches.indexOf(b),
                            explanation: newText,
                          );
                          if (ok) {
                            b.explanation = newText;
                            if (mounted) setState(() {});
                          }
                          return ok;
                        },
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _loadBranch(b);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _nextVariation() {
    if (_selectedVariationIndex < _chapter.variations.length - 1) {
      _loadVariation(_selectedVariationIndex + 1);
    } else {
      setState(() {
        _state = StudyState.chapterCompleted;
      });
    }
  }

  // =========================================================================
  // BOARD CONTROLS (exact same controls as Play Against Pippo)
  // =========================================================================

  void _goToStart() {
    if (_isOpponentThinking || _isProcessingMove) return;
    _controller.goToStart();
    setState(() {
      _viewIndex = -1;
      _commentary = _chapter.description;
    });
  }

  void _goBack() {
    if (_isOpponentThinking || _isProcessingMove) return;
    if (!_controller.canUndo) return;
    _controller.undo();
    setState(() {
      _viewIndex = _controller.currentIndex - 1;
      _commentary = _viewIndex >= 0
          ? _activeLine[_viewIndex].explanation
          : _chapter.description;
    });
  }

  void _goForward() {
    if (_isOpponentThinking || _isProcessingMove) return;
    if (!_controller.canRedo) return;
    _controller.redo();
    setState(() {
      _viewIndex = _controller.currentIndex - 1;
      _commentary = _viewIndex >= 0
          ? _activeLine[_viewIndex].explanation
          : _chapter.description;
    });
  }

  void _goToEnd() {
    if (_isOpponentThinking || _isProcessingMove) return;
    _controller.goToEnd();
    setState(() {
      _viewIndex = _controller.currentIndex - 1;
      _commentary = _viewIndex >= 0
          ? _activeLine[_viewIndex].explanation
          : _chapter.description;
    });
  }

  void _flipBoard() {
    setState(() {
      _boardOrientation = _boardOrientation == BoardOrientation.white
          ? BoardOrientation.black
          : BoardOrientation.white;
    });
  }

  /// Restarts the currently studied line (variation or branch) from scratch.
  void _restartStudy() {
    if (_isOpponentThinking || _isProcessingMove) return;
    if (_activeBranch != null) {
      _loadBranch(_activeBranch!);
    } else if (_activeLine.isNotEmpty && _chapter.variations.isNotEmpty) {
      _loadVariation(_selectedVariationIndex);
    } else {
      // Nothing studied yet: just reset the board.
      _controller.reset();
      setState(() {
        _frontierIndex = -1;
        _viewIndex = -1;
        _commentary = _chapter.description;
      });
    }
  }

  Widget _buildBoardControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            Icons.first_page,
            _controller.canUndo ? _goToStart : null,
            theme,
          ),
          _controlButton(
            Icons.chevron_left,
            _controller.canUndo ? _goBack : null,
            theme,
          ),
          _controlButton(Icons.restart_alt, _restartStudy, theme),
          _controlButton(Icons.sync, _flipBoard, theme),
          _controlButton(
            Icons.chevron_right,
            _controller.canRedo ? _goForward : null,
            theme,
          ),
          _controlButton(
            Icons.last_page,
            _controller.canRedo ? _goToEnd : null,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback? onTap, ThemeData theme) {
    final bool isEnabled = onTap != null;
    return IconButton(
      icon: Icon(
        icon,
        color: isEnabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
        size: 28,
      ),
      onPressed: onTap,
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variation = _chapter.variations.isNotEmpty
        ? _chapter.variations[_selectedVariationIndex]
        : null;
    final Widget? bottomControls = _buildBottomControls();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(_chapter.name),
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTheorySection(variation),
            const SizedBox(height: 12),
            _buildPippoChatSection(),
            const SizedBox(height: 12),
            ChessBoard(
              controller: _controller,
              settings: ChessboardSettings(orientation: _boardOrientation),
              onMove: _handleUserMove,
              enableFreeMove: true,
            ),
            if (_chapterStarted)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _buildBoardControls(theme),
              ),
            const SizedBox(height: 16),
            _buildVariationsHeader(),
            const SizedBox(height: 12),
            _buildVariationsList(),
            const SizedBox(height: 24),
            ?bottomControls,
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // PIPPO CHAT BUBBLE (above the chessboard)
  // =========================================================================

  Widget _buildPippoChatSection() {
    final editTarget = _resolveBubbleEdit();
    return Row(
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
                    _commentary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (editTarget != null)
                  Positioned(
                    top: 0,
                    right: 0,
                  child: _pencilButton(
                    tooltip: AppLocalizations.of(context).editExplanationTooltip,
                      onTap: () => _editExplanation(
                        title: editTarget.title,
                        currentText: editTarget.text,
                        onSave: editTarget.save,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Small pencil icon shown next to MongoDB-backed texts. Disabled while an
  /// edit is being saved.
  Widget _pencilButton({required String tooltip, required VoidCallback onTap}) {
    // Admin-only: free, pro and signed-out users never see the editor, even for
    // content they are allowed to read.
    if (!_isAdmin) return const SizedBox.shrink();

    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
      icon: Icon(
        Icons.edit_outlined,
        size: 18,
        color: _isSavingEdit
            ? AppColors.textTertiaryOf(context).withValues(alpha: 0.4)
            : AppColors.textTertiaryOf(context),
      ),
      onPressed: _isSavingEdit ? null : onTap,
    );
  }

  /// Resolves which MongoDB-backed text (if any) the Pippo bubble is currently
  /// showing, so the pencil icon only appears for editable content. Returns
  /// null while transient prompts are displayed (e.g. "I'm thinking",
  /// "Play e4", "That's not the right move").
  _BubbleEdit? _resolveBubbleEdit() {
    // Branch explanation (with optional "Play X" prompt) at the branch start.
    if (_activeBranch != null &&
        _frontierIndex >= 0 &&
        _frontierIndex < _activeLine.length) {
      final atBranchStart = _frontierIndex == 0 ||
          identical(_activeLine[_frontierIndex], _activeBranch!.plies.first);
      if (atBranchStart) {
        final base = _activeBranch!.explanation;
        final l10n = AppLocalizations.of(context);
        final prompt = l10n.playMovePrompt(_activeLine[_frontierIndex].move);
        if (_commentary == base || _commentary == '$base\n\n$prompt') {
        return _BubbleEdit(
          title: l10n.branchEditTitle(_activeBranch!.name),
          text: base,
          save: (newText) async {
            final variationIndex = _selectedVariationIndex;
            final branchIndex =
                _chapter.variations[variationIndex].branches.indexOf(_activeBranch!);
            final ok = await CourseApiService.updateBranchExplanation(
              courseSlug: widget.course.slug,
              chapterIndex: widget.chapterIndex,
              variationIndex: variationIndex,
              branchIndex: branchIndex,
              explanation: newText,
            );
            if (ok) {
              _activeBranch!.explanation = newText;
              if (mounted) {
                setState(() => _commentary = _commentaryForLineStart(newText));
              }
            }
            return ok;
          },
        );
        }
      }
    }

    // Move explanation shown after the move was played.
    if (_viewIndex >= 0 && _viewIndex < _activeLine.length) {
      final move = _activeLine[_viewIndex];
      if (move.explanation.isNotEmpty && _commentary == move.explanation) {
        final variationIndex = _selectedVariationIndex;
        final viewIndex = _viewIndex;
        final branch = _activeBranch;
        int? branchIndex;
        int plyIndex = viewIndex;
        if (branch != null) {
          final branchStart =
              _activeLine.indexWhere((p) => identical(p, branch.plies.first));
          if (branchStart >= 0 && viewIndex >= branchStart) {
            branchIndex =
                _chapter.variations[variationIndex].branches.indexOf(branch);
            plyIndex = viewIndex - branchStart;
          }
        }
        return _BubbleEdit(
          title: AppLocalizations.of(context).moveEditTitle(move.move),
          text: move.explanation,
          save: (newText) async {
            final bool ok;
            if (branchIndex != null) {
              ok = await CourseApiService.updateBranchMoveExplanation(
                courseSlug: widget.course.slug,
                chapterIndex: widget.chapterIndex,
                variationIndex: variationIndex,
                branchIndex: branchIndex,
                plyIndex: plyIndex,
                explanation: newText,
              );
            } else {
              ok = await CourseApiService.updateMoveExplanation(
                courseSlug: widget.course.slug,
                chapterIndex: widget.chapterIndex,
                variationIndex: variationIndex,
                plyIndex: viewIndex,
                explanation: newText,
              );
            }
            if (ok) {
              move.explanation = newText;
              if (mounted) setState(() => _commentary = newText);
            }
            return ok;
          },
        );
      }
    }

    // Chapter description (start position / start of the study).
    if (_viewIndex < 0 &&
        _activeBranch == null &&
        _commentary == _chapter.description) {
      return _BubbleEdit(
        title: AppLocalizations.of(context).chapterEditTitle(_chapter.name),
        text: _chapter.description,
        save: (newText) async {
          final ok = await CourseApiService.updateChapterDescription(
            courseSlug: widget.course.slug,
            chapterIndex: widget.chapterIndex,
            description: newText,
          );
          if (ok) {
            _chapter.description = newText;
            if (mounted) setState(() => _commentary = newText);
          }
          return ok;
        },
      );
    }

    return null;
  }

  // =========================================================================
  // SECTIONS
  // =========================================================================

  Widget _buildTheorySection(CourseVariationModel? variation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            variation?.theory ?? AppLocalizations.of(context).noTheoryAvailable,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
              height: 1.4,
            ),
          ),
        ),
        if (variation != null)
          _pencilButton(
            tooltip: AppLocalizations.of(context).editTheoryTooltip,
            onTap: () => _editExplanation(
              title: AppLocalizations.of(context).theoryEditTitle(variation.name),
              currentText: variation.theory,
              onSave: (newText) async {
                final ok = await CourseApiService.updateVariationTheory(
                  courseSlug: widget.course.slug,
                  chapterIndex: widget.chapterIndex,
                  variationIndex: _selectedVariationIndex,
                  theory: newText,
                );
                if (ok) {
                  variation.theory = newText;
                  if (mounted) setState(() {});
                }
                return ok;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVariationsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).variationsTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildVariationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chapter.variations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = _chapter.variations[index];
        final isSelected = _selectedVariationIndex == index;
        final hasBranches = v.branches.isNotEmpty;
        final isLocked = !_chapterStarted;

        return Column(
          children: [
            GestureDetector(
              onTap: _canTapVariations ? () => _loadVariation(index) : null,
              child: Opacity(
                opacity: isLocked ? 0.65 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderOf(context),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _completedVariationIndices.contains(index)
                            ? Icons.check_circle_rounded
                            : isSelected
                            ? Icons.play_circle_fill_rounded
                            : Icons.play_circle_outline_rounded,
                        color: _completedVariationIndices.contains(index)
                            ? Colors.green
                            : isSelected
                            ? AppColors.primary
                            : AppColors.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          v.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (hasBranches && isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: v.branches.map((b) => _buildBranchItem(b)).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBranchItem(CourseBranchModel branch) {
    final isLocked = !_chapterStarted;
    return InkWell(
      onTap: _canTapVariations ? () => _loadBranch(branch) : null,
      child: IntrinsicHeight(
        child: Row(
          children: [
            VerticalDivider(
              color: AppColors.borderOf(context),
              thickness: 2,
              width: 16,
            ),
            Container(
              width: 12,
              height: 2,
              color: AppColors.borderOf(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: isLocked ? 0.65 : 1.0,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.call_split_rounded,
                        color: AppColors.textTertiaryOf(context),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BOTTOM CONTROLS
  // =========================================================================

  Widget? _buildBottomControls() {
    final l10n = AppLocalizations.of(context);
    if (_state == StudyState.initial) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtlasButton(
            label: l10n.startChapterButton,
            onPressed: _startChapter,
          ),
        ],
      );
    }

    if (_state == StudyState.variationCompleted) {
      final bool isLastVariation =
          _selectedVariationIndex == _chapter.variations.length - 1;
      if (isLastVariation) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AtlasButton(
              label: l10n.finishChapterButton,
              onPressed: () {
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            AtlasButton(
              label: l10n.takeTestButton,
              isPrimary: false,
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/chapter-test',
                  arguments: {
                    'course': widget.course,
                    'chapterIndex': widget.chapterIndex,
                  },
                );
              },
            ),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtlasButton(
            label: l10n.exploreBranchesButton,
            onPressed: _showBranchesDialog,
          ),
          const SizedBox(height: 12),
          AtlasButton(
            label: l10n.moveToNextVariationButton,
            isPrimary: false,
            onPressed: _completedVariationIndices.contains(_selectedVariationIndex)
                ? _nextVariation
                : null,
          ),
        ],
      );
    }

    if (_state == StudyState.chapterCompleted) {
      return AtlasButton(
        label: l10n.finishChapterButton,
        onPressed: () {
          if (mounted) Navigator.pop(context);
        },
      );
    }

    // Playing state: no fixed bottom controls (board controls live under the
    // chessboard, exactly like the Play Against Pippo page).
    return null;
  }
}

/// Describes an editable MongoDB-backed text: what to show in the edit dialog
/// and how to persist (and locally apply) the edited value.
class _BubbleEdit {
  final String title;
  final String text;
  final Future<bool> Function(String newText) save;

  const _BubbleEdit({
    required this.title,
    required this.text,
    required this.save,
  });
}
