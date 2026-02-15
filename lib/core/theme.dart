import 'package:flutter/material.dart';

/// Design-aligned colors from UI screenshots.
class AppColors {
  AppColors._();

  static const Color primaryOrange = Color(0xFFE85D04);
  static const Color onCourtGreen = Color(0xFF2D6A4F);
  static const Color skillStrong = Color(0xFFE07C3A);
  static const Color skillDev = Color(0xFF4A90D9);
  static const Color saveAwardsGold = Color(0xFFE9C46A);
  static const Color fairnessBehind = Color(0xFFF4A261);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color chipInactive = Color(0xFFE9ECEF);
  static const Color navInactive = Color(0xFF495057);
}

ThemeData get appTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryOrange,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
      outline: AppColors.chipInactive,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
  );
}
