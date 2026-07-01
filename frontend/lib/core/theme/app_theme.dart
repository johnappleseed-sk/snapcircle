import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        titleLarge: AppTextStyles.headingMedium,
        titleMedium: AppTextStyles.headingSmall,
        titleSmall: AppTextStyles.bodyLarge,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        disabledColor: AppColors.surfaceMuted,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.border,
            );
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(46),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF12090B);
    const darkSurface = Color(0xFF1A1012);
    const darkCard = Color(0xFF211517);
    const darkText = Color(0xFFFFF6F7);
    const darkMuted = Color(0xFFD8C4C8);
    const darkBorder = Color(0xFF3A262A);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: const Color(0xFFFF5A70),
      secondary: const Color(0xFFFF9AAD),
      surface: darkSurface,
    );

    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        shape: Border(bottom: BorderSide(color: darkBorder)),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkMuted),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          borderSide: const BorderSide(color: Color(0xFFFF5A70), width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: lightTheme.textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      dividerColor: darkBorder,
    );
  }
}
