import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessBoard.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/shared/widgets/OfflineBanner.dart';
import 'package:atlas_ui/features/puzzles/QuotaLockedPuzzleBoard.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';


class PuzzlePlayerScreen extends StatefulWidget {
  final List<PuzzleDocModel> puzzleDocs;
  const PuzzlePlayerScreen({super.key, required this.puzzleDocs});

  @override
  State<PuzzlePlayerScreen> createState() => _PuzzlePlayerScreenState();
}

class _PuzzlePlayerScreenState extends State<PuzzlePlayerScreen> {
  late List<Map<String, dynamic>> _allPuzzles;
  int _currentIndex = 0;
  late ChessboardController _controller;
  ChessboardSettings _settings = const ChessboardSettings();
  bool _isSolved = false;
  bool _limitReached = false;
  int _hintLevel = 0;

  @override
  void initState() {
    super.initState();
    _allPuzzles = widget.puzzleDocs
        .expand((doc) => doc.puzzles.map((p) => {
              'docId': doc.id,
              'puzzle': p,
              'playerColor': doc.playerColor,
            }))
        .toList();
    _controller = ChessboardController();
    _initializePuzzle();
  }

  Future<void> _initializePuzzle() async {
    if (_allPuzzles.isEmpty) return;
    final plan = await DailyUsageService.currentPlanStatus();
    if (!await DailyUsageService.canStartPuzzle(plan)) {
      if (mounted) setState(() => _limitReached = true);
      return;
    }
    if (mounted) _loadCurrentPuzzle();
  }

  void _loadCurrentPuzzle() {
    final puzzleData = _allPuzzles[_currentIndex];
    final puzzle = puzzleData['puzzle'] as PuzzleModel;
    final playerColor = puzzleData['playerColor'] as String;
    
    _controller.loadFen(puzzle.fen);
    _controller.clearHints();
    
    setState(() {
      _isSolved = false;
      _hintLevel = 0;
      _settings = _settings.copyWith(
        orientation: playerColor.toLowerCase() == 'black' 
            ? BoardOrientation.black 
            : BoardOrientation.white,
      );
    });
  }

  Future<void> _handleMove(String from, String to) async {
    if (_isSolved) return;
    
    final puzzleData = _allPuzzles[_currentIndex];
    final puzzle = puzzleData['puzzle'] as PuzzleModel;
    final bestMove = puzzle.bestMove;
    
    // Normalize move string (from+to)
    final playerMove = '$from$to';
    
    if (playerMove == bestMove) {
      _controller.makeMove(from, to);
      setState(() {
        _isSolved = true;
      });
      _controller.clearHints();
      
      // Save progress locally instead of cloud
      await LocalPuzzleService.saveSolved(puzzle.id);
      final plan = await DailyUsageService.currentPlanStatus();
      await DailyUsageService.recordPuzzleSolved(plan);
      
      // Update local memory state
      final updatedPuzzle = PuzzleModel(
        id: puzzle.id,
        fen: puzzle.fen,
        bestMove: puzzle.bestMove,
        completed: true,
      );
      _allPuzzles[_currentIndex]['puzzle'] = updatedPuzzle;
    } else {
      // In a real app, we might check if it's a legal move but not the best one
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).puzzleNotBest),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _provideHint() {
    if (_isSolved) return;

    final puzzle = _allPuzzles[_currentIndex]['puzzle'] as PuzzleModel;
    final bestMove = puzzle.bestMove;
    if (bestMove.length < 4) return;

    final from = bestMove.substring(0, 2);
    final to = bestMove.substring(2, 4);

    setState(() {
      if (_hintLevel == 0) {
        _controller.setHintSquare(from);
        _hintLevel = 1;
      } else if (_hintLevel == 1) {
        _controller.setHintMove(from, to);
        _hintLevel = 2;
      }
    });
  }

  Future<void> _nextPuzzle() async {
    if (_currentIndex < _allPuzzles.length - 1) {
      final plan = await DailyUsageService.currentPlanStatus();
      if (!await DailyUsageService.canStartPuzzle(plan)) {
        if (mounted) setState(() => _limitReached = true);
        return;
      }
      setState(() {
        _currentIndex++;
        _loadCurrentPuzzle();
      });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).puzzleSessionComplete)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_allPuzzles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.practiceTitle)),
        body: Center(child: Text(l10n.puzzleEmpty)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(l10n.puzzleCounter(_currentIndex + 1, _allPuzzles.length)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
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
                    label: _hintLevel == 0 ? l10n.puzzleHint : (_hintLevel == 1 ? l10n.puzzleShowMove : l10n.puzzleUsedHint),
                    isPrimary: false,
                    onPressed: _isSolved ? null : _provideHint,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AtlasButton(
                    label: l10n.puzzleNext,
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
