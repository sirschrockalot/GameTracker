import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/glass_tokens.dart';

/// Platform-adaptive glass surface: iOS liquid glass (blur + low opacity + border),
/// Android (reduced blur + higher opacity + small elevation).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.padding,
    this.borderRadius,
    required this.child,
  });

  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final radius = borderRadius ?? BorderRadius.circular(GlassTokens.radiusMd);
    final padding = this.padding ?? const EdgeInsets.all(16);
    final surfaceColor = Colors.white.withValues(
      alpha: GlassTokens.surfaceOpacity(context),
    );
    final borderColor = GlassTokens.borderColor(context);
    final elevation = GlassTokens.elevation(context);
    final sigma = GlassTokens.blurSigma(context);

    if (isIOS) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: radius,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    return Material(
      elevation: elevation,
      borderRadius: radius,
      color: Colors.transparent,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
