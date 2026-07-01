import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final bool fullWidth;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.fullWidth = true,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = isOutlined ? AppButtonVariant.outline : variant;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: effectiveVariant == AppButtonVariant.outline
                  ? AppColors.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSmall),
                const SizedBox(width: AppSizes.paddingSmall),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final effectiveOnPressed = isLoading ? null : onPressed;
    final button = switch (effectiveVariant) {
      AppButtonVariant.outline => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceMuted,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
        ),
        child: child,
      ),
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
    };

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, height: 48, child: button);
  }
}
