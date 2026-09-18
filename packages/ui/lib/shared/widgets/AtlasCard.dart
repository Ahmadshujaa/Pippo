import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';

class AtlasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final double borderRadius;

  const AtlasCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevated = false,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? (elevated 
              ? Theme.of(context).colorScheme.surface 
              : Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(borderRadius),
          border: elevated ? null : Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border
          ),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}


