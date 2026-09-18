import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';

class AtlasButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool useGradient;
  final IconData? icon;
  final double? width;
  final bool isLoading;

  const AtlasButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.useGradient = false,
    this.icon,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width ?? double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: (isPrimary && useGradient && isEnabled) ? AppColors.primaryGradient : null,
        boxShadow: isPrimary && isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (isPrimary && useGradient)
              ? Colors.transparent
              : (isPrimary ? AppColors.primary : Theme.of(context).cardColor),
          foregroundColor: isPrimary ? Colors.white : AppColors.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: isPrimary ? null : BorderSide(
            color: Theme.of(context).dividerColor, 
            width: 1.5
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  // Flexible + FittedBox: the label scales down instead of
                  // overflowing when the button is too narrow for it (e.g.
                  // two side-by-side buttons on small screens).
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


