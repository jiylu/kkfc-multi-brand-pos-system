import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

abstract final class LoginLayout {
  // Breakpoints and widths
  static const double wideBreakpoint = 900;
  static const double maxContentWidth = 1120;
  static const double formMaxWidth = 480;
  static const double panelCopyMaxWidth = 360;
  static const double minControlHeight = KkfcSizing.controlMd;
  static const double spinnerSize = 18;
  static const double iconSm = KkfcSizing.iconSm;
  static const double iconMd = KkfcSizing.iconMd;
  static const double iconLg = KkfcSizing.iconLg;
  static const double iconXl = KkfcSizing.iconXl;

  // Spacing
  static const double gapXs = KkfcSpace.s4;
  static const double gapSm = KkfcSpace.s8;
  static const double gapMd = KkfcSpace.s16;
  static const double gapLg = KkfcSpace.s24;
  static const double gapXl = KkfcSpace.s32;

  // Shape
  static const double radiusSm = KkfcRadius.sm;
  static const double radiusMd = KkfcRadius.md;
  static const double radiusLg = KkfcRadius.lg;
  static const double borderWidth = KkfcBorderWidth.thin;
  static const double focusBorderWidth = KkfcBorderWidth.focus;
  static const double accentBarWidth = 4;
  static const double accentBarHeight = 56;

  // Opacity
  static const double softAlpha = KkfcOpacity.soft;
  static const double lineAlpha = KkfcOpacity.line;

  // Motion
  static const Duration fast = KkfcMotion.fast;
  static const Duration base = KkfcMotion.base;
  static const Duration slow = KkfcMotion.slow;
  static const Duration stagger = KkfcMotion.stagger;
  static const Curve curve = Curves.easeOutCubic;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < wideBreakpoint;

  /// Returns zero when the OS asks for reduced motion.
  static Duration motion(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
