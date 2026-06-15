import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.014),
            blurRadius: isDark ? 4 : 8,
            offset: Offset(0, isDark ? 1 : 2),
          ),
        ],
      ),
      child: child,
    );

    return onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            child: card,
          );
  }
}
