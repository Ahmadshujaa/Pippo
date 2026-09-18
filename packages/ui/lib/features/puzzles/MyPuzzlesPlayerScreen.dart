import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/shared/widgets/PippoChatBubble.dart';
import 'package:atlas_ui/features/puzzles/QuotaLockedPuzzleBoard.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// Solves the puzzles that were generated from the user's own games against
/// Pippo ([UserPuzzleStorageService]).
///
/// These puzzles have no theme, so there is only ONE hint level: highlight
/// the piece that should be moved ("which piece to move") — never the full
/// move like the themed puzzle player does.
class MyPuzzlesPlayerScreen extends StatefulWidget {
  const MyPuzzlesPlayerScreen({super.key});

  @override
  State<MyPuzzlesPlayerScreen> createState() => _MyPuzzlesPlayerScreenState();
}

class _MyPuzzlesPlayerScreenState extends State<MyPuzzlesPlayerScreen> {
  List<UserPuzzle> _puzzles = [];
  int _currentIndex = 0;
  late ChessboardController _controller;
  ChessboardSettings _settings = const ChessboardSettings();
  bool _isSolved = false;
  bool _hintUsed = false;
  bool _limitReached = false;
  String? _bubbleMessage;

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController();
    _puzzles = UserPuzzleStorageService.getPuzzles();
    _initializePuzzle();
  }

  Future<void> _initializePuzzle() async {
    if (_puzzles.isEmpty) return;
    final plan = await DailyUsageService.currentPlanStatus();
    if (!await DailyUsageService.canStartPuzzle(plan)) {
      if (mounted) setState(() => _limitReached = true);
      return;
    }
    if (mounted) _loadCurrentPuzzle();
  }

  void _loadCurrentPuzzle() {
    final puzzle = _puzzles[_currentIndex];
    _controller.loadFen(puzzle.fen);
    _controller.clearHints();
    setState(() {
      _isSolved = false;
      _hintUsed = false;
      _bubbleMessage = _initialBubbleMessage(puzzle);
      _settings = _settings.copyWith(
        orientation: puzzle.playerColor.toLowerCase() == 'black'
            ? BoardOrientation.black
            : BoardOrientation.white,
      );
    });
  }

  String _initialBubbleMessage(UserPuzzle puzzle) {
    final l10n = AppLocalizations.of(context);
    final move = _moveToSan(puzzle.fen, puzzle.playedMove);
    final classification = puzzle.classification.trim().toLowerCase();
    return l10n.myPuzzleIntroMessage(move, _classificationLabel(classification));
  }

  /// Backend classification tag in the on-screen language. Unknown tags
  /// fall back to the raw tag so the message never breaks.
  String _classificationLabel(String classification) {
    final l10n = AppLocalizations.of(context);
    switch (classification) {
      case 'best':
        return l10n.phraseBest;
      case 'brilliant':
        return l10n.phraseBrilliant;
      case 'great':
        return l10n.phraseGreat;
      case 'excellent':
        return l10n.phraseExcellent;
      case 'good':
        return l10n.phraseGood;
      case 'inaccuracy':
      case 'inaccurate':
        return l10n.phraseInaccuracy;
      case 'mistake':
        return l10n.phraseMistake;
      case 'blunder':
        return l10n.phraseBlunder;
      case 'miss':
        return l10n.phraseMiss;
      case 'book':
        return l10n.phraseBook;
      case 'forced':
        return l10n.phraseForced;
      default:
        return classification;
    }
  }

  String _moveToSan(String fen, String uci) {
    final cleanMove = uci.trim().toLowerCase();
    if (cleanMove.length < 4) return uci;

    try {
      final board = chess.Chess.fromFEN(fen);
      final from = cleanMove.substring(0, 2);
      final to = cleanMove.substring(2, 4);
      final promotion = cleanMove.length > 4 ? cleanMove[4] : null;
      for (final move in board.generate_moves()) {
        if (move.fromAlgebraic == from &&
            move.toAlgebraic == to &&
            (move.promotion == null || move.promotion!.name == promotion)) {
          return board.move_to_san(move);
        }
      }
    } catch (_) {
      // Fall back to the stored value if an older puzzle has malformed move data.
    }
    return uci;
  }

  Future<void> _handleMove(String from, String to) async {
    if (_isSolved) return;

    final puzzle = _puzzles[_currentIndex];
    final bestMove = puzzle.bestMove;

    // The stored best move is UCI (possibly with a promotion suffix, e.g.
    // "e7e8q"). The board reports from+to, defaulting to queen promotion —
    // so compare against both the full UCI move and its from/to part.
    final playerMove = '$from$to';
    final bestRoot = bestMove.length > 4 ? bestMove.substring(0, 4) : bestMove;
    if (playerMove != bestMove && playerMove != bestRoot) {
      setState(() {
        _bubbleMessage =
            AppLocalizations.of(context).notBestMoveTryAgain;
      });
      return;
    }

    _controller.makeMove(from, to);
    // Completed puzzles are DELETED from storage — only unsolved ones are
    // ever kept on disk.
    await UserPuzzleStorageService.deletePuzzle(puzzle.id);
    final plan = await DailyUsageService.currentPlanStatus();
    await DailyUsageService.recordPuzzleSolved(plan);
    _controller.clearHints();
    setState(() {
      _isSolved = true;
      _bubbleMessage = AppLocalizations.of(context).greatJobFoundBestMove;
    });
  }

  /// Single-level hint: only highlight WHICH PIECE to move. There is no
  /// second hint because these puzzles carry no theme; all guidance is shown
  /// through Pippo's chat bubble.
  void _provideHint() {
    if (_isSolved || _hintUsed) return;
    final bestMove = _puzzles[_currentIndex].bestMove;
    if (bestMove.length < 4) return;
    final from = bestMove.substring(0, 2);
    final piece = _controller.game.get(from);
    if (piece == null) return;

    _controller.setHintSquare(from);
    setState(() {
      _hintUsed = true;
      final l10n = AppLocalizations.of(context);
      _bubbleMessage =
          l10n.myPuzzleHintPieceToMove(_pieceTypeName(piece.type), from);
    });
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

  Future<void> _nextPuzzle() async {
    if (_currentIndex < _puzzles.length - 1) {
      final plan = await DailyUsageService.currentPlanStatus();
      if (!await DailyUsageService.canStartPuzzle(plan)) {
        if (mounted) setState(() => _limitReached = true);
        return;
      }
      setState(() {
        _currentIndex++;
      });
      _loadCurrentPuzzle();
      return;
    }
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).allMyPuzzlesSolvedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_puzzles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(title: Text(l10n.puzzlesFromYourGamesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.noMyPuzzlesEmptyState,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          l10n.puzzleCounterTitle(_currentIndex + 1, _puzzles.length),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _limitReached
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: QuotaLockedPuzzleBoard()),
            )
          : Column(
        children: [
          OfflineBanner(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PippoChatBubble(message: _bubbleMessage),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ChessBoard(
              controller: _controller,
              settings: _settings,
              onMove: _handleMove,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: AtlasButton(
                    label: _hintUsed ? l10n.hintUsedButton : l10n.hintButton,
                    isPrimary: false,
                    onPressed: _isSolved ? null : _provideHint,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AtlasButton(
                    label: _currentIndex == _puzzles.length - 1
                        ? l10n.finishButton
                        : l10n.nextPuzzleButton,
                    isPrimary: true,
                    onPressed: _isSolved ? _nextPuzzle : null,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
