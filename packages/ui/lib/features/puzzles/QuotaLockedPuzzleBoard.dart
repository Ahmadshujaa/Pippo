import 'package:flutter/material.dart';

import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// A non-interactive empty chessboard shown when a free user's daily puzzle
/// allowance is exhausted.
class QuotaLockedPuzzleBoard extends StatelessWidget {
  const QuotaLockedPuzzleBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 64,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final column = index % 8;
              final isLight = (row + column).isEven;
              return ColoredBox(
                color: isLight
                    ? const Color(0xFFE8DCC5)
                    : const Color(0xFF9B7653),
              );
            },
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                l10n.quotaUpgradeCta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
