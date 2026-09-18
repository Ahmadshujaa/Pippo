import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

/// Self-contained evaluation bar + engine panel.
///
/// Subscribes directly to the Stockfish analysis stream and rebuilds only
/// itself on every engine publish. Before this widget existed, every engine
/// update triggered a full-page setState (plus a second rebuild from a
/// page-level StreamBuilder), which is what made the board stutter while the
/// engine was searching.
class EngineAnalysisPanel extends StatefulWidget {
  final ChessboardController controller;
  final bool engineEnabled;
  final int lines;

  const EngineAnalysisPanel({
    super.key,
    required this.controller,
    required this.engineEnabled,
    required this.lines,
  });

  @override
  State<EngineAnalysisPanel> createState() => _EngineAnalysisPanelState();
}

class _EngineAnalysisPanelState extends State<EngineAnalysisPanel> {
  AnalysisResult? _current;
  StreamSubscription<AnalysisResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = StockfishEngineService.instance.analysisStream.listen((
      result,
    ) {
      if (!mounted) return;
      // Only surface results that belong to the position currently on the
      // board; stale searches (e.g. a line the user just navigated away from)
      // are ignored and will be cleared by the controller listener below.
      if (result.fen == widget.controller.game.fen) {
        setState(() => _current = result);
      }
    });
    // Clear the panel as soon as the board position changes, so a stale eval
    // never lingers while the engine catches up (or while it is disabled).
    widget.controller.addListener(_onBoardChanged);
  }

  @override
  void didUpdateWidget(covariant EngineAnalysisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engineEnabled && !widget.engineEnabled) {
      _current = null;
    }
  }

  void _onBoardChanged() {
    if (_current != null && _current!.fen != widget.controller.game.fen) {
      setState(() => _current = null);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onBoardChanged);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Guard against stale data when the engine has not caught up yet.
    final display = (_current?.fen == widget.controller.game.fen)
        ? _current
        : null;

    return RepaintBoundary(
      child: Column(
        children: [
          _buildEvaluationBar(isDark, display),
          const SizedBox(height: 12),
          _buildEnginePanel(theme, display),
        ],
      ),
    );
  }

  Widget _buildEvaluationBar(bool isDark, AnalysisResult? analysis) {
    const double barHeight = 24;

    // Evaluation for the bar, always from WHITE's perspective.
    // Stockfish reports from the side-to-move's perspective, so flip the
    // score when it is Black's turn. A mate score for the side to move is
    // positive by convention (M3 = side to move mates in 3), so the flip
    // covers mates too: mate FOR black ends up negative, mate FOR white
    // positive.
    double score = 0;
    String text = '';

    if (analysis != null) {
      score = analysis.evaluation;
      if (analysis.turn == chess.Color.BLACK) score = -score;

      final double whitePawns = analysis.isMate
          ? (score > 0 ? 100.0 : -100.0)
          : score / 100.0;

      // No label at a dead-equal 0.0.
      if (!analysis.isMate && whitePawns == 0) {
        text = '';
      } else if (analysis.isMate) {
        text =
            '${whitePawns < 0 ? '-' : ''}M${analysis.evaluation.toInt().abs()}';
      } else {
        final absVal = whitePawns.abs().toString();
        text = '${whitePawns > 0 ? '+' : '-'}$absVal';
      }
    }

    // Cap score at +/- 500 centipawns for bar visualization
    // 0 = middle, -500 = black win, 500 = white win
    double factor = 0.5;
    if (analysis != null) {
      if (analysis.isMate) {
        factor = score > 0 ? 1.0 : 0.0;
      } else {
        // Linear mapping from [-500, 500] to [0, 1]
        factor = (score.clamp(-500.0, 500.0) + 500.0) / 1000.0;
      }
    }

    // White's share of the bar fills from the LEFT in white; black's share
    // is the rest, in black (muted in dark mode so it stays visible on the
    // dark scaffold). The winning side always takes the larger portion of
    // its own color: white losing (-4) => bar mostly black, white winning
    // (+4) => bar mostly white.
    final whiteSideColor = Colors.white;
    final blackSideColor = isDark ? Colors.white24 : Colors.black;
    // The label sits on the winning side: black text on the white half,
    // white text on the black half. Empty at a dead-equal 0.0.
    final labelOnWhiteSide = factor >= 0.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: barHeight,
            width: double.infinity,
            color: blackSideColor,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor,
              child: Container(color: whiteSideColor),
            ),
          ),
          Row(
            mainAxisAlignment: labelOnWhiteSide
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  text,
                  style: TextStyle(
                    color: labelOnWhiteSide ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnginePanel(ThemeData theme, AnalysisResult? analysis) {
    if (!widget.engineEnabled) return const SizedBox.shrink();

    final isCorrectFen = analysis?.fen == widget.controller.game.fen;
    final depth = isCorrectFen ? (analysis?.depth ?? 0) : 0;
    final lines = (depth >= 6) ? (analysis?.lines ?? []) : [];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Stockfish 19',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).engineDepthLabel(analysis?.depth ?? 0),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(widget.lines, (index) {
              if (index < lines.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _engineLine(
                    lines[index].moves,
                    lines[index].eval,
                    theme,
                    lines[index].isPrimary,
                    analysis!.turn,
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSingleSkeleton(theme),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSkeleton(ThemeData theme) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _engineLine(
    String moves,
    String eval,
    ThemeData theme,
    bool isPrimary,
    chess.Color turn,
  ) {
    // Stockfish reports evals from the side-to-move perspective. Normalize to
    // White's perspective (positive = White is winning) so line evals match
    // the evaluation bar above.
    String displayEval = eval;
    if (turn == chess.Color.BLACK) {
      if (eval.startsWith('M')) {
        // Mate score: raw "M3" means the side to move mates in 3.
        // From White's perspective that is White being mated.
        displayEval = '-$eval';
      } else if (eval.startsWith('+')) {
        displayEval = '-${eval.substring(1)}';
      } else if (eval.startsWith('-')) {
        displayEval = '+${eval.substring(1)}';
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayEval,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: isPrimary
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              moves,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isPrimary ? 0.9 : 0.6,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
