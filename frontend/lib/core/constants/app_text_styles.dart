import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}
