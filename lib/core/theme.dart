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

  /// Soft gradient colors for liquid-glass background (light).
  static const Color gradientStartLight = Color(0xFFFAFAFA);
  static const Color gradientEndLight = Color(0xFFE9ECEF); // chipInactive

  /// Soft gradient colors for liquid-glass background (dark).
  static const Color gradientStartDark = Color(0xFF1C1C1E);
  static const Color gradientEndDark = Color(0xFF2C2C2E);
}

/// Soft gradient background for liquid-glass effect; uses theme brightness.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final start = isDark ? AppColors.gradientStartDark : AppColors.gradientStartLight;
    final end = isDark ? AppColors.gradientEndDark : AppColors.gradientEndLight;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [start, end],
        ),
      ),
      child: child,
    );
  }
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
