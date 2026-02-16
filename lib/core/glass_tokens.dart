import 'package:flutter/material.dart';

/// Design tokens for glass / liquid-glass surfaces (platform-adaptive).
class GlassTokens {
  GlassTokens._();

  // Border radius scale
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // iOS: liquid glass — blur, low opacity, subtle border, no heavy shadow
  static const double surfaceOpacityIOS = 0.28;
  static const double blurSigmaIOS = 12;
  static const Color borderColorIOS = Colors.white;
  static const double borderOpacityIOS = 0.22;
  static const double elevationIOS = 0;

  // Android: reduced blur or none, higher opacity, small elevation
  static const double surfaceOpacityAndroid = 0.52;
  static const double blurSigmaAndroid = 2;
  static const Color borderColorAndroid = Colors.white;
  static const double borderOpacityAndroid = 0.15;
  static const double elevationAndroid = 1;

  static double surfaceOpacity(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? surfaceOpacityIOS
          : surfaceOpacityAndroid;

  static double blurSigma(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? blurSigmaIOS
          : blurSigmaAndroid;

  static Color borderColor(BuildContext context) =>
      (Theme.of(context).platform == TargetPlatform.iOS
          ? borderColorIOS
          : borderColorAndroid)
          .withValues(alpha: Theme.of(context).platform == TargetPlatform.iOS
              ? borderOpacityIOS
              : borderOpacityAndroid);

  static double elevation(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? elevationIOS
          : elevationAndroid;

  static bool useBlur(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;
}
