import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AtlasButton.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.pricingTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero text
            Text(
              l10n.pricingHeroTitle,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pricingHeroSubtitle,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Free Tier
            _buildTierCard(
              context,
              isPro: false,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Pro Tier
            _buildTierCard(
              context,
              isPro: true,
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              l10n.pricingFaqHeader,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              l10n.pricingFaqCancelQuestion,
              l10n.pricingFaqCancelAnswer,
            ),
            _buildFaqItem(
              context,
              l10n.pricingFaqTrialQuestion,
              l10n.pricingFaqTrialAnswer,
            ),
            _buildFaqItem(
              context,
              l10n.pricingFaqPaymentQuestion,
              l10n.pricingFaqPaymentAnswer,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, {required bool isPro, required bool isDark}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPro
            ? null
            : (isDark ? AppColors.surfaceDark : Colors.white),
        gradient: isPro
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: isPro
            ? null
            : Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
        boxShadow: [
          if (isPro)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.pricingMostPopularBadge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          if (!isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.pricingFreeBadge,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Title + Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPro ? l10n.pricingProTierName : l10n.pricingFreeTierName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isPro ? Colors.white : theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  isPro ? l10n.pricingProPrice : l10n.pricingFreePrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features
          ..._getFeatures(context, isPro).map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isPro
                            ? Colors.white.withValues(alpha: 0.9)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Button
          if (isPro)
            AtlasButton(
              label: l10n.pricingStartTrialButton,
              useGradient: true,
              onPressed: () {
                // TODO: Implement subscription logic
              },
            )
          else
            AtlasButton(
              label: l10n.pricingCurrentPlanButton,
              isPrimary: false,
              onPressed: null,
            ),
        ],
      ),
    );
  }

  List<String> _getFeatures(BuildContext context, bool isPro) {
    final l10n = AppLocalizations.of(context);
    if (isPro) {
      return [
        l10n.pricingFeatureUnlimitedAnalysis,
        l10n.pricingFeatureDeepClassification,
        l10n.pricingFeatureAiReview,
        l10n.pricingFeatureOpeningExplorer,
        l10n.pricingFeatureUnlimitedPuzzles,
        l10n.pricingFeatureTrainingPlans,
        l10n.pricingFeaturePrioritySupport,
        l10n.pricingFeatureEarlyAccess,
      ];
    }
    return [
      l10n.pricingFeatureBasicAnalysis,
      l10n.pricingFeatureStandardClassification,
      l10n.pricingFeatureGameImport,
      l10n.pricingFeatureLimitedPuzzles,
      l10n.pricingFeatureCommunityAccess,
    ];
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
