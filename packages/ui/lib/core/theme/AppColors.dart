import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (theme-invariant) - Warm Yellow/Gold Palette
  static const Color primary = Color(0xFFF59E0B); // Amber 500
  static const Color primaryDark = Color(0xFFD97706); // Amber 600
  static const Color secondary = Color(0xFFFBBF24); // Amber 400
  static const Color secondaryDark = Color(0xFFB45309); // Amber 700
  
  // Light Theme Colors - Soft Warm Cream / Ivory (Non-blinding, Elegant)
  static const Color background = Color(0xFFFDFBF7); // Warm Ivory / Cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF5EFEB); // Soft Warm Sand
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFEAE2D8);
  static const Color borderStrong = Color(0xFFD5C9BC);

  static const Color textPrimary = Color(0xFF2D2622); // Deep Warm Espresso / Slate
  static const Color textSecondary = Color(0xFF6B5F55);
  static const Color textTertiary = Color(0xFF9E9288);

  // Dark Theme Colors - Deep Warm Charcoal & Obsidian
  static const Color backgroundDark = Color(0xFF161412); // Deep Warm Charcoal
  static const Color surfaceDark = Color(0xFF211D1A); // Warm Slate Surface
  static const Color surfaceSubtleDark = Color(0xFF2E2824);
  static const Color surfaceElevatedDark = Color(0xFF26211D);

  static const Color borderDark = Color(0xFF332B25);
  static const Color borderStrongDark = Color(0xFF4A3F37);

  static const Color textPrimaryDark = Color(0xFFFDF8F3); // Warm Crisp Ivory
  static const Color textSecondaryDark = Color(0xFFD4C9C1);
  static const Color textTertiaryDark = Color(0xFF9E948A);

  // Semantic Colors (theme-invariant)
  static const Color accent = Color(0xFFF59E0B); // Amber Gold
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // =========================================================================
  // Theme-aware helpers — use these instead of hardcoding light-only colors.
  // =========================================================================

  /// Returns true when the current theme is dark mode.
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Scaffold background.
  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? backgroundDark : background;

  /// Card / surface background.
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? surfaceDark : surface;

  /// Muted surface (progress bars, chip backgrounds, etc.).
  static Color surfaceSubtleOf(BuildContext context) =>
      isDark(context) ? surfaceSubtleDark : surfaceSubtle;

  /// Elevated surface (modals, popovers).
  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceElevated;

  /// Subtle border color.
  static Color borderOf(BuildContext context) =>
      isDark(context) ? borderDark : border;

  /// Stronger border color.
  static Color borderStrongOf(BuildContext context) =>
      isDark(context) ? borderStrongDark : borderStrong;

  /// Primary text color.
  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimary;

  /// Secondary text color.
  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondary;

  /// Tertiary text color.
  static Color textTertiaryOf(BuildContext context) =>
      isDark(context) ? textTertiaryDark : textTertiary;
}
