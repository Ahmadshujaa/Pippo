import 'dart:async';

import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// A thin "No Internet Connection" notice shown at the top of screens whenever
/// the device is offline.
///
/// The banner subscribes to the global [ConnectivityService.isOnline] itself,
/// so any screen can just drop it into its layout — it appears automatically
/// when the connection drops and disappears as soon as connectivity returns.
/// An optional "Retry" tap forces an immediate re-check.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.isOnline,
      builder: (context, isOnline, child) {
        if (isOnline) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context);
        final isDark = AppColors.isDark(context);
        final background = isDark ? const Color(0xFF3A2B20) : const Color(0xFFFBE9D6);
        final foreground =
            isDark ? AppColors.textPrimaryDark : const Color(0xFF7A4E0A);
        final theme = Theme.of(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_bolt_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.offlineBannerTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: foreground,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => unawaited(ConnectivityService.checkNow()),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      l10n.retry,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}