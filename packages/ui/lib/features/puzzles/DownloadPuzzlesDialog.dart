import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// Amount-selection dialog for the "Download Puzzles" feature.
///
/// Lets the user pick how many puzzles to download (between 10 and 100, in
/// steps of 10) and confirms with a Download button. The chosen count is
/// handed back to the caller through `Navigator.pop`:
///
/// ```dart
/// final count = await showDialog<int>(
///   context: context,
///   builder: (context) => const DownloadPuzzlesDialog(canDownload: true),
/// );
/// ```
class DownloadPuzzlesDialog extends StatefulWidget {
  final bool canDownload;

  const DownloadPuzzlesDialog({
    super.key,
    required this.canDownload,
  });

  @override
  State<DownloadPuzzlesDialog> createState() => _DownloadPuzzlesDialogState();
}

class _DownloadPuzzlesDialogState extends State<DownloadPuzzlesDialog> {
  static const int _kMin = 10;
  static const int _kMax = 100;
  static const int _kStep = 10;

  double _count = 50;

  int get _selectedCount => (_count / _kStep).round() * _kStep;

  /// The dialog is a pure selector — the actual download happens on the
  /// puzzles screen, which receives the chosen count when we pop.
  void _confirm(BuildContext context) {
    Navigator.pop<int>(context, _selectedCount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (widget.canDownload) _buildSlider(context) else _buildUpgradeBody(context),
            const SizedBox(height: 26),
            Row(
              children: [
                _buildCancelButton(context),
                const SizedBox(width: 14),
                Expanded(
                  child: AtlasButton(
                    label: widget.canDownload
                        ? l10n.downloadButton
                        : l10n.upgradeNow,
                    icon: widget.canDownload
                        ? Icons.download_rounded
                        : Icons.arrow_forward_rounded,
                    isPrimary: true,
                    onPressed: () => widget.canDownload
                        ? _confirm(context)
                        : Navigator.pop<int>(context, -1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.offlineDownloadsProNotice,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _count,
          min: _kMin.toDouble(),
          max: _kMax.toDouble(),
          divisions: (_kMax - _kMin) ~/ _kStep,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _count = value),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$_kMin',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.selectedPuzzleCount(_selectedCount),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.savedForOffline,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$_kMax',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Close ("cancel") affordance: a bordered cross on the left of the
  /// Download button, styled to match AtlasButton's outline.
  Widget _buildCancelButton(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.close_rounded,
          size: 22,
          color: AppColors.textSecondaryOf(context),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.download_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.downloadPuzzlesTitle,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppColors.textPrimaryOf(context),
            ),
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
}
