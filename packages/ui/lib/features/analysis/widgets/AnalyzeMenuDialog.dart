import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// Centered menu shown when the user taps "Analyze" on the Analysis screen.
///
/// Lets the user pick between a full-game Analysis (Stockfish classification
/// of every move) and a Game Review (move-by-move explanations on top), and
/// choose the engine depth for the run. Also surfaces how many game reviews
/// the user has left today.
class AnalyzeMenuDialog extends StatefulWidget {
  final int reviewsLeftToday;
  final int reviewLimit;
  final bool isAdmin;
  final bool canReview;
  final int initialDepth;
  final ValueChanged<int> onDepthChanged;
  final VoidCallback onAnalysisSelected;
  final VoidCallback onReviewSelected;

  const AnalyzeMenuDialog({
    super.key,
    required this.reviewsLeftToday,
    required this.reviewLimit,
    required this.isAdmin,
    required this.canReview,
    required this.initialDepth,
    required this.onDepthChanged,
    required this.onAnalysisSelected,
    required this.onReviewSelected,
  });

  @override
  State<AnalyzeMenuDialog> createState() => _AnalyzeMenuDialogState();
}

class _AnalyzeMenuDialogState extends State<AnalyzeMenuDialog> {
  late double _depth = widget.initialDepth.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 6),
            _buildReviewsLeft(theme),
            const SizedBox(height: 16),
            _buildModeOptions(theme),
            const SizedBox(height: 22),
            _buildDepthSection(theme),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECTIONS
  // =========================================================================

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context).analyzeGameTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildReviewsLeft(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(
          Icons.local_activity_rounded,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          widget.isAdmin
              ? l10n.reviewsUnlimited
              : l10n.reviewsLeftToday(widget.reviewsLeftToday, widget.reviewLimit),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModeOptions(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.analyzeTypeHeader,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.onAnalysisSelected,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                  : AppColors.surfaceSubtle.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.analyzeModeAnalysis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.analyzeModeAnalysisDesc,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: widget.canReview ? widget.onReviewSelected : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                  : AppColors.surfaceSubtle.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                    const Spacer(),
                    if (!widget.canReview)
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.canReview ? l10n.analyzeModeReview : l10n.upgradeToProTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.canReview
                      ? l10n.reviewModeDesc
                      : l10n.reviewLockedDesc,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepthSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.engineDepthHeader,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtleOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                l10n.depthValueLabel(_depth.round()),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _depth,
                  min: 7,
                  max: 20,
                  divisions: 13,
                  label: l10n.depthValueLabel(_depth.round()),
                  onChanged: (value) {
                    setState(() => _depth = value);
                    widget.onDepthChanged(value.round());
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.depthHint,
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

}
