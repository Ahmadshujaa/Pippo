import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// The app's primary bottom navigation tabs.
enum AppTab { home, courses, puzzles, analysis, menu }

/// Shared bottom navigation bar shown on the main feature screens.
///
/// Kept as a single widget so every screen that shows it stays visually and
/// behaviorally identical (and the active tab is easy to pin).
class AppBottomNav extends StatelessWidget {
  final AppTab active;

  const AppBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
                context, active, AppTab.home, Icons.home_rounded, l10n.navHome),
            _buildNavItem(context, active, AppTab.courses,
                Icons.menu_book_outlined, l10n.navCourses),
            _buildNavItem(context, active, AppTab.puzzles,
                Icons.extension_rounded, l10n.navPuzzles),
            _buildNavItem(context, active, AppTab.analysis,
                Icons.analytics_outlined, l10n.navAnalysis),
            _buildNavItem(
                context, active, AppTab.menu, Icons.menu_rounded, l10n.navMenu),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppTab active,
    AppTab tab,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    final isActive = active == tab;
    final color =
        isActive ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        if (!isActive) {
          switch (tab) {
            case AppTab.home:
              Navigator.pushReplacementNamed(context, '/home');
            case AppTab.courses:
              Navigator.pushNamed(context, '/courses');
            case AppTab.puzzles:
              Navigator.pushNamed(context, '/puzzles');
            case AppTab.analysis:
              Navigator.pushReplacementNamed(context, '/analysis');
            case AppTab.menu:
              Navigator.pushNamed(context, '/profile-settings');
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}