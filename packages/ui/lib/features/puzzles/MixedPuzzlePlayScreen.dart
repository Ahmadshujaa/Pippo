import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/shared/widgets/PippoChatBubble.dart';
import 'package:atlas_ui/features/puzzles/QuotaLockedPuzzleBoard.dart';
import 'package:atlas_ui/features/puzzles/theme_display.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class MixedPuzzlePlayScreen extends StatefulWidget {
  /// Optional theme name from the All Themes screen (e.g. 'Mate In 3').
  /// When null the screen runs in mixed-puzzles mode.
  final String? theme;

  /// When true the screen plays puzzle batches previously downloaded via
  /// [DownloadedPuzzlesService] for offline solving — no network access is
  /// used: the batch comes from local storage, and each solved puzzle is
  /// permanently deleted from the stored set.
  final bool isDownloaded;

  /// When true the screen plays today's single Daily Puzzle (see
  /// [DailyPuzzleService]): one fixed high-rated puzzle, no rating change, and
  /// no "next" puzzle — finishing returns to the home screen.
  final bool daily;

  const MixedPuzzlePlayScreen({
    super.key,
    this.theme,
    this.isDownloaded = false,
    this.daily = false,
  });

  @override
  State<MixedPuzzlePlayScreen> createState() => _MixedPuzzlePlayScreenState();
}

class _MixedPuzzlePlayScreenState extends State<MixedPuzzlePlayScreen>
    with SingleTickerProviderStateMixin {
  late ChessboardController _controller;
  ChessboardSettings _settings = const ChessboardSettings();

  List<MixedPuzzle> _batch = [];
  int _currentIndex = 0;
  int _rating = 400;

  /// Last rating change (+15 / -15): shown in green/red next to the rating.
  int _ratingDelta = 0;

  /// Smoothly counts the rating number up/down instead of jumping.
  late final AnimationController _ratingAnimationController;
  Animation<double> _ratingAnimation =
      const AlwaysStoppedAnimation<double>(400);

  int _solutionIndex = 0;
  bool _isFailed = false;
  bool _isPuzzleCompleted = false;
  bool _isGivingUp = false;
  bool _isProcessing = false;

  int _hintLevel = 0;

  String? _feedbackSquare;
  String? _feedbackOrigin;
  Color? _feedbackColor;
  IconData? _feedbackIcon;
  Color? _feedbackIconColor;

  Color? _hintColorOverride;

  String? _bubbleMessage;

  bool _isLoading = true;
  bool _isLoadingNextBatch = false;
  bool _quotaReached = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController();
    _ratingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _init();
  }

  @override
  void dispose() {
    _ratingAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _isThemed => widget.theme != null;

  bool get _isDownloaded => widget.isDownloaded;

  bool get _isDaily => widget.daily;

  String get _screenTitle {
    final l10n = AppLocalizations.of(context);
    if (_isDaily) return l10n.dailyPuzzleTitle;
    if (_isDownloaded) return l10n.downloadedPuzzlesTitle;
    final theme = widget.theme;
    // The theme slug itself stays English for the backend fetch — only the
    // title the user reads is translated.
    if (theme != null) return themeDisplayName(l10n, theme);
    return l10n.mixedPuzzlesTitle;
  }

  // The mode determines where a batch comes from and what happens when a
  // puzzle is solved:
  //   - Themed mode persists one batch per theme via ThemePuzzleService.
  //   - Mixed mode uses MixedPuzzleService (network refetch when exhausted).
  //   - Downloaded mode plays the local "Downloaded Puzzles" set and NEVER
  //     touches the network — solved puzzles are deleted from that set.
  //   - Daily mode plays the single puzzle chosen for today.
  Future<List<MixedPuzzle>> _ensureBatch() async {
    if (_isDaily) {
      return DailyPuzzleService.getDailyPuzzle().then((p) => [p]);
    }
    if (_isDownloaded) {
      return Future.value(DownloadedPuzzlesService.getPuzzles());
    }
    final existing = _isThemed
        ? await ThemePuzzleService.getBatch(widget.theme!)
        : await MixedPuzzleService.getBatch();
    if (existing.isNotEmpty && existing.any((p) => !p.completed)) {
      return existing;
    }
    return _fetchNewBatch();
  }

  Future<List<MixedPuzzle>> _fetchNewBatch() async {
    if (_isDaily) {
      return DailyPuzzleService.getDailyPuzzle().then((p) => [p]);
    }
    if (_isDownloaded) {
      return Future.value(DownloadedPuzzlesService.getPuzzles());
    }
    final plan = await DailyUsageService.currentPlanStatus();
    final localIds = <String>{};
    localIds.addAll(await MixedPuzzleService.getUnsolvedPuzzleIds());
    localIds.addAll(await ThemePuzzleService.getAllUnsolvedPuzzleIds());
    // These are also Turso puzzles. They count as locally available unsolved
    // puzzles for the batch-size calculation, unlike Pippo-generated puzzles,
    // which are checked separately at the moment they are opened.
    localIds.addAll(
      DownloadedPuzzlesService.getPuzzles().map((puzzle) => puzzle.id),
    );
    final count = await DailyUsageService.tursoFetchCount(
      plan: plan,
      requested: 20,
      unsolvedLocalCount: localIds.length,
    );
    if (count <= 0) {
      throw Exception(
        'You have reached today\'s puzzle limit. Upgrade to Pro for unlimited puzzles.',
      );
    }
    return _isThemed
        ? ThemePuzzleService.fetchAndSaveNewBatch(
            widget.theme!,
            count: count,
          )
        : MixedPuzzleService.fetchAndSaveNewBatch(count: count);
  }

  /// Checks MongoDB immediately before a puzzle is put on the board. This is
  /// especially important for Pippo puzzles, which are created locally and do
  /// not pass through the Turso batch-size calculation.
  Future<bool> _canLoadPuzzle() async {
    final plan = await DailyUsageService.currentPlanStatus();
    return DailyUsageService.canStartPuzzle(plan);
  }

  Future<int> _getIndex() {
    if (_isDownloaded || _isDaily) return Future.value(0);
    return _isThemed
        ? ThemePuzzleService.getCurrentIndex(widget.theme!)
        : MixedPuzzleService.getCurrentIndex();
  }

  Future<void> _setIndex(int index) {
    if (_isDownloaded || _isDaily) return Future.value();
    return _isThemed
        ? ThemePuzzleService.setCurrentIndex(widget.theme!, index)
        : MixedPuzzleService.setCurrentIndex(index);
  }

  Future<void> _markCompleted(String puzzleId) {
    if (_isDownloaded) return DownloadedPuzzlesService.deletePuzzle(puzzleId);
    return _isThemed
        ? ThemePuzzleService.markCompleted(widget.theme!, puzzleId)
        : MixedPuzzleService.markCompleted(puzzleId);
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _quotaReached = false;
    });
    try {
      _rating = await MixedPuzzleService.getRating();
      _ratingAnimation = AlwaysStoppedAnimation<double>(_rating.toDouble());
      _batch = await _ensureBatch();
      if (_batch.isEmpty) {
        throw Exception(_isDownloaded
            ? 'No downloaded puzzles available'
            : 'No puzzles available');
      }
      if (_isDownloaded || _isDaily) {
        // Downloaded puzzles are deleted as they are solved, so there is no
        // per-theme index or "completed" flag to restore — always start from
        // the first puzzle that is still in storage. The daily puzzle is a
        // single, fixed entry and has no stored index at all.
        _currentIndex = 0;
      } else {
        _currentIndex = await _getIndex();
        if (_currentIndex < 0 || _currentIndex >= _batch.length) {
          _currentIndex = 0;
        }
        while (_currentIndex < _batch.length && _batch[_currentIndex].completed) {
          _currentIndex++;
        }
        if (_currentIndex >= _batch.length) {
          _batch = await _fetchNewBatch();
          _currentIndex = 0;
        }
        await _setIndex(_currentIndex);
      }
      if (!await _canLoadPuzzle()) {
        setState(() => _quotaReached = true);
        return;
      }
      _loadPuzzle(_batch[_currentIndex]);
    } catch (e) {
      if (_isQuotaError(e)) {
        setState(() => _quotaReached = true);
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadPuzzle(MixedPuzzle puzzle) {
    _isFailed = false;
    _isPuzzleCompleted = false;
    _isGivingUp = false;
    _isProcessing = false;
    _hintLevel = 0;
    _solutionIndex = 0;
    _feedbackSquare = null;
    _feedbackOrigin = null;
    _feedbackColor = null;
    _feedbackIcon = null;
    _feedbackIconColor = null;
    _hintColorOverride = null;
    _bubbleMessage = null;

    // Determine orientation based on puzzle FEN side to move.
    // In the Turso DB, the FEN's side to move is the blunderer (opponent);
    // the user plays the opposite side.
    final fenParts = puzzle.fen.split(' ');
    final isBlundererWhite = fenParts.length > 1 ? fenParts[1] == 'w' : true;
    final userIsWhite = !isBlundererWhite;
    final sideToMoveLabel = userIsWhite
        ? AppLocalizations.of(context).whiteToPlay
        : AppLocalizations.of(context).blackToPlay;

    // If we have a fenBeforeLastMove, show it first, then animate lastMove
    if (puzzle.lastMove != null && puzzle.fenBeforeLastMove != null) {
      _controller.loadFen(puzzle.fenBeforeLastMove!);
      _isProcessing = true;
      setState(() {
        _settings = _settings.copyWith(
          orientation: userIsWhite ? BoardOrientation.white : BoardOrientation.black,
        );
      });

      // After a delay, play the lastMove to reveal the puzzle position
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final lastMove = puzzle.lastMove!;
        final from = lastMove.substring(0, 2);
        final to = lastMove.substring(2, 4);
        final promo = lastMove.length > 4 ? lastMove[4] : 'q';
        _controller.makeMove(from, to, promotion: promo);
        setState(() {
          _isProcessing = false;
          _bubbleMessage = sideToMoveLabel;
        });
      });
    } else {
      // Turso path: FEN = blunderer to move, solution[0] = the blunder.
      // Load the FEN, auto-play the blunder, then position the user to refute.
      _controller.loadFen(puzzle.fen);
      setState(() {
        _settings = _settings.copyWith(
          orientation: userIsWhite ? BoardOrientation.white : BoardOrientation.black,
        );
      });

      if (puzzle.solution.isNotEmpty) {
        _isProcessing = true;
        setState(() {});
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          final blunder = puzzle.solution[0].toLowerCase().trim();
          if (blunder.length >= 4) {
            final from = blunder.substring(0, 2);
            final to = blunder.substring(2, 4);
            final promo = blunder.length == 5 ? blunder[4] : 'q';
            _controller.makeMove(from, to, promotion: promo);
          }
          _solutionIndex = 1;
          setState(() {
            _isProcessing = false;
            _bubbleMessage = sideToMoveLabel;
          });
        });
      } else {
        _solutionIndex = 0;
      }
    }
  }

  Future<void> _handleMove(String from, String to) async {
    if (_isPuzzleCompleted || _isGivingUp || _isProcessing) return;
    if (_batch.isEmpty) return;

    final puzzle = _batch[_currentIndex];
    if (_solutionIndex >= puzzle.solution.length) return;

    final expectedRaw = puzzle.solution[_solutionIndex];
    final expected = expectedRaw.toLowerCase().trim();
    final playerMove = ('$from$to').toLowerCase();

    bool isCorrect;
    if (expected.length == 5) {
      if (playerMove == expected) {
        isCorrect = true;
      } else if (expected[4] == 'q' && playerMove == expected.substring(0, 4)) {
        isCorrect = true;
      } else {
        isCorrect = false;
      }
    } else {
      isCorrect = playerMove == expected;
    }

    if (isCorrect) {
      final promo = expected.length == 5 ? expected[4] : 'q';
      final success = _controller.makeMove(from, to, promotion: promo);
      if (!success) return;

      setState(() {
        _feedbackSquare = to;
        _feedbackOrigin = from;
        _feedbackColor = const Color(0xFF96BC4B);
        _feedbackIcon = Icons.check_rounded;
        _feedbackIconColor = const Color(0xFF96BC4B);
        _isProcessing = true;
        _controller.clearHints();
        _hintColorOverride = null;
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      setState(() {
        _feedbackSquare = null;
        _feedbackOrigin = null;
        _feedbackColor = null;
        _feedbackIcon = null;
        _feedbackIconColor = null;
      });

      _solutionIndex++;

      if (_solutionIndex >= puzzle.solution.length) {
        await _completePuzzle();
        if (!mounted) return;
        setState(() => _isProcessing = false);
        return;
      }

      final oppMove = puzzle.solution[_solutionIndex].toLowerCase().trim();
      final oppFrom = oppMove.substring(0, 2);
      final oppTo = oppMove.substring(2, 4);
      final oppPromo = oppMove.length == 5 ? oppMove[4] : 'q';

      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      final oppSuccess = _controller.makeMove(oppFrom, oppTo, promotion: oppPromo);
      if (oppSuccess) {
        _solutionIndex++;
        if (_solutionIndex >= puzzle.solution.length) {
          await _completePuzzle();
        }
      }
      if (mounted) setState(() => _isProcessing = false);
    } else {
      _isFailed = true;

      final fenBefore = _controller.game.fen;
      final success = _controller.makeMove(from, to);
      if (!success) return;

      setState(() {
        _feedbackSquare = to;
        _feedbackOrigin = from;
        _feedbackColor = const Color(0xFFB33430);
        _feedbackIcon = Icons.close_rounded;
        _feedbackIconColor = const Color(0xFFB33430);
        _isProcessing = true;
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      if (_controller.canUndo) {
        _controller.undo();
      } else {
        _controller.loadFen(fenBefore);
      }

      setState(() {
        _feedbackSquare = null;
        _feedbackOrigin = null;
        _feedbackColor = null;
        _feedbackIcon = null;
        _feedbackIconColor = null;
        _isProcessing = false;
      });
    }
  }

  Future<void> _completePuzzle() async {
    if (_isPuzzleCompleted) return;
    setState(() => _isPuzzleCompleted = true);

    final puzzle = _batch[_currentIndex];
    if (_isDownloaded) {
      // Downloaded mode: solving a puzzle permanently deletes it from the
      // locally stored set (giving up keeps it for another try later).
      if (!_isFailed) {
        await DownloadedPuzzlesService.deletePuzzle(puzzle.id);
        _batch.removeAt(_currentIndex);
      }
    } else if (_isDaily) {
      // The daily puzzle is not part of the mixed batch, so only the local
      // "solved today" flag changes — the stored batch is left untouched.
      await DailyPuzzleService.markSolvedToday();
    } else {
      await _markCompleted(puzzle.id);
      _batch[_currentIndex] = puzzle.copyWith(completed: true);
      await MixedPuzzleService.saveBatch(_batch);
    }

    if (!_isFailed) {
      final plan = await DailyUsageService.currentPlanStatus();
      await DailyUsageService.recordPuzzleSolved(plan);
    }

    // The daily puzzle is a fixed challenge, not rating-tracked practice.
    if (_isDaily) return;

    final previousRating = _rating;
    final perfect = !_isFailed;
    final newRating = await MixedPuzzleService.adjustRating(perfect: perfect);
    if (!mounted) return;
    setState(() {
      _rating = newRating;
      _ratingDelta = newRating - previousRating;
    });
    _animateRating(previousRating, newRating);
  }

  /// Smoothly counts the displayed rating from [from] to [to] instead of
  /// jumping straight to the new value.
  void _animateRating(int from, int to) {
    _ratingAnimation = Tween<double>(
      begin: from.toDouble(),
      end: to.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _ratingAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _ratingAnimationController.forward(from: 0);
  }

  Future<void> _fetchNextBatch() async {
    setState(() {
      _isLoadingNextBatch = true;
      _error = null;
      _quotaReached = false;
    });
    try {
      _batch = await _fetchNewBatch();
      _currentIndex = 0;
      if (_batch.isNotEmpty) {
        _loadPuzzle(_batch[_currentIndex]);
      }
    } catch (e) {
      if (_isQuotaError(e)) {
        setState(() => _quotaReached = true);
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoadingNextBatch = false);
    }
  }

  bool _isQuotaError(Object error) =>
      error.toString().contains("today's puzzle limit");

  Future<void> _handleHint() async {
    if (_isPuzzleCompleted || _isGivingUp || _isProcessing) return;
    if (_batch.isEmpty) return;
    if (_solutionIndex >= _batch[_currentIndex].solution.length) return;

    final puzzle = _batch[_currentIndex];
    final l10n = AppLocalizations.of(context);
    final themeLabel = _isThemed
        ? themeDisplayName(l10n, widget.theme!).toLowerCase()
        : _themeLabel(puzzle.theme);
    final expected = puzzle.solution[_solutionIndex];
    if (expected.length < 4) return;

    final from = expected.substring(0, 2);
    final piece = _controller.game.get(from);
    if (piece == null) {
      setState(() {
        _hintLevel = 2;
        _bubbleMessage = _randomThemeSentence(themeLabel);
      });
      return;
    }
    final isWhiteTurn = _controller.game.turn == chess.Color.WHITE;
    final pieceIsWhite = piece.color == chess.Color.WHITE;
    if (isWhiteTurn != pieceIsWhite) {
      setState(() {
        _hintLevel = 2;
        _bubbleMessage = _randomThemeSentence(themeLabel);
      });
      return;
    }

    if (_hintLevel == 0) {
      _controller.setHintSquare(from);
      final pieceName = _pieceTypeName(piece.type);
      setState(() {
        _hintColorOverride = const Color(0xFF5C8BB0);
        _hintLevel = 1;
        _bubbleMessage = _randomPick([
          l10n.hintLookAtPiece(pieceName, from),
          l10n.hintPieceIsKey(pieceName, from),
          l10n.hintFocusOnPiece(pieceName, from),
        ]);
      });
    } else if (_hintLevel == 1) {
      setState(() {
        _hintLevel = 2;
        _bubbleMessage = _randomThemeSentence(themeLabel);
      });
    }
  }

  String _randomPick(List<String> options) =>
      options.isEmpty ? '' : options[Random().nextInt(options.length)];

  String _randomThemeSentence(String themeLabel) {
    final l10n = AppLocalizations.of(context);
    return _randomPick([
      l10n.themeHintAbout(themeLabel),
      l10n.themeHintWayOut(themeLabel),
      l10n.themeHintThinking(themeLabel),
    ]);
  }

  String _pieceTypeName(chess.PieceType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case chess.PieceType.PAWN:
        return l10n.piecePawn;
      case chess.PieceType.KNIGHT:
        return l10n.pieceKnight;
      case chess.PieceType.BISHOP:
        return l10n.pieceBishop;
      case chess.PieceType.ROOK:
        return l10n.pieceRook;
      case chess.PieceType.QUEEN:
        return l10n.pieceQueen;
      case chess.PieceType.KING:
        return l10n.pieceKing;
      default:
        return l10n.pieceGeneric;
    }
  }

  /// Backend theme tag in the on-screen language, lowercased to fit the hint
  /// sentence. Known themes.txt slugs map through the shared display names
  /// (matched case-insensitively); anything unrecognized stays as-is.
  String _themeLabel(String theme) {
    final l10n = AppLocalizations.of(context);
    final t = theme.toLowerCase().trim();
    if (t == 'mix') return l10n.mixedTacticsLabel;
    for (final slug in knownThemeSlugs) {
      if (slug.toLowerCase() == t) {
        return themeDisplayName(l10n, slug).toLowerCase();
      }
    }
    return t;
  }

  Future<void> _handleGiveUp() async {
    if (_isPuzzleCompleted || _isGivingUp || _isProcessing) return;
    if (_batch.isEmpty) return;

    setState(() {
      _isGivingUp = true;
      _isProcessing = true;
      _isFailed = true;
      _controller.clearHints();
      _hintColorOverride = null;
    });

    final puzzle = _batch[_currentIndex];
    for (int i = _solutionIndex; i < puzzle.solution.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (_isPuzzleCompleted) break;
      final mv = puzzle.solution[i].toLowerCase().trim();
      if (mv.length < 4) continue;
      final from = mv.substring(0, 2);
      final to = mv.substring(2, 4);
      final promo = mv.length == 5 ? mv[4] : null;
      _controller.makeMove(from, to, promotion: promo ?? 'q');
      setState(() => _solutionIndex = i + 1);
    }

    await _completePuzzle();
    if (mounted) {
      setState(() {
        _isGivingUp = false;
        _isProcessing = false;
      });
    }
    if (_isDownloaded && _batch.isNotEmpty) {
      // Downloading keeps the given-up puzzle in the stored set (it was not
      // solved), but the player moves on to the next one. If this was the
      // only puzzle left, the same one is re-shown as a retry.
      _currentIndex =
          _currentIndex + 1 >= _batch.length ? 0 : _currentIndex + 1;
    }
  }

  Future<void> _handleNext() async {
    if (!_isPuzzleCompleted) return;

    // There is only ever one daily puzzle: finishing it goes back home.
    if (_isDaily) {
      Navigator.pop(context);
      return;
    }

    if (_isDownloaded) {
      // The solved puzzle was already deleted from the stored set, so the
      // next one slides into the current slot. When nothing is left we go
      // back to the puzzles screen — there is never a network refetch here.
      if (_batch.isEmpty) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).allDownloadedSolvedMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final nextIdx = _currentIndex >= _batch.length ? 0 : _currentIndex;
      _currentIndex = nextIdx;
      if (!await _canLoadPuzzle()) {
        setState(() => _quotaReached = true);
        return;
      }
      _loadPuzzle(_batch[_currentIndex]);
      return;
    }

    final nextIdx = _currentIndex + 1;
    if (nextIdx < _batch.length) {
      if (!await _canLoadPuzzle()) {
        setState(() => _quotaReached = true);
        return;
      }
      setState(() => _currentIndex = nextIdx);
      await MixedPuzzleService.setCurrentIndex(_currentIndex);
      _loadPuzzle(_batch[_currentIndex]);
    } else {
      await _fetchNextBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
          title: Text(_screenTitle),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_isLoadingNextBatch) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
          title: Text(_screenTitle),
        ),
        body: Column(
          children: [
            const Spacer(),
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadingNextPuzzles,
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    if (_quotaReached) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_screenTitle),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: QuotaLockedPuzzleBoard()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
          title: Text(_screenTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryOf(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _init,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_batch.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundOf(context),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
          title: Text(_screenTitle),
        ),
        body: Center(child: Text(AppLocalizations.of(context).noPuzzlesAvailable)),
      );
    }

    // The daily puzzle is a single fixed entry, so a "1 / 1" counter would be
    // noise — only batch modes show progress.
    final progressText =
        _isDaily ? '' : '${_currentIndex + 1} / ${_batch.length}';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _screenTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3),
        ),
        actions: [
          if (progressText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  progressText,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PippoChatBubble(message: _bubbleMessage),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChessBoard(
              controller: _controller,
              settings: _settings,
              onSettingsChanged: (s) => setState(() => _settings = s),
              onMove: _handleMove,
              showSettingsButton: false,
              hintColorOverride: _hintColorOverride,
              puzzleFeedbackSquare: _feedbackSquare,
              puzzleFeedbackOriginSquare: _feedbackOrigin,
              puzzleFeedbackColor: _feedbackColor,
              puzzleFeedbackIcon: _feedbackIcon,
              puzzleFeedbackIconColor: _feedbackIconColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isDaily) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).yourRatingLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                AnimatedBuilder(
                  animation: _ratingAnimation,
                  builder: (context, _) => Text(
                    '${_ratingAnimation.value.round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (_ratingDelta != 0) ...[
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _ratingDelta > 0 ? '+$_ratingDelta' : '$_ratingDelta',
                      key: ValueKey<int>(_ratingDelta),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.1,
                        color: _ratingDelta > 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildBottomButton(
                    label: _hintLevel == 0
                        ? AppLocalizations.of(context).hintButton
                        : _hintLevel == 1
                            ? AppLocalizations.of(context).showThemeButton
                            : AppLocalizations.of(context).hintUsedButton,
                    icon: Icons.lightbulb_outline_rounded,
                    onPressed: (_isPuzzleCompleted || _isGivingUp || _isProcessing || _hintLevel >= 2) ? null : _handleHint,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                _buildFlagButton(),
                if (_isPuzzleCompleted) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNextButton(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final enabled = onPressed != null;
    final theme = Theme.of(context);
    return Material(
      color: isPrimary
          ? AppColors.primary
          : (enabled ? theme.cardColor : AppColors.surfaceSubtleOf(context)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? AppColors.primary : theme.dividerColor,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isPrimary ? Colors.white : (enabled ? AppColors.primary : AppColors.textSecondaryOf(context))),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isPrimary ? Colors.white : (enabled ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagButton() {
    final enabled = !_isPuzzleCompleted && !_isGivingUp && !_isProcessing;
    final theme = Theme.of(context);
    return Material(
      color: enabled ? theme.cardColor : AppColors.surfaceSubtleOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? _handleGiveUp : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(
            Icons.flag_outlined,
            size: 22,
            color: enabled ? AppColors.textPrimaryOf(context) : AppColors.textSecondaryOf(context).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final l10n = AppLocalizations.of(context);
    final label = _isDaily ? l10n.doneButton : l10n.nextButton;
    final icon =
        _isDaily ? Icons.check_rounded : Icons.play_arrow_rounded;

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _handleNext,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: -0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
