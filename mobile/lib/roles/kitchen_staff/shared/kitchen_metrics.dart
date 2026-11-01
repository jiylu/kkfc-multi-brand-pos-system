import 'package:mobile/app/theme/tokens.dart';

/// Single place where the kitchen role maps onto design tokens.
/// If a token name differs in tokens.dart, fix it HERE only.
abstract final class KitchenSpace {
  static const double xs = KkfcSpace.s4;
  static const double sm = KkfcSpace.s8;
  static const double md = KkfcSpace.s16;
  static const double lg = KkfcSpace.s32;
  static const double xl = KkfcSpace.s64;
}

abstract final class KitchenRadius {
  static const double sm = KkfcRadius.sm;
  static const double md = KkfcRadius.md;
  static const double lg = KkfcRadius.lg;
}

abstract final class KitchenMetrics {
  static const double borderWidth = KkfcBorderWidth.thin;
  static const double controlHeight = KkfcSizing.controlLg; // 56, all buttons

  /// Layout-only values read from the Figma frames (not design tokens).
  static const double tabletBreakpoint = 720;
  static const double sideNavWidth = 88;
  static const double panelAccentWidth = 4;
  static const double maxContentWidth = 1200;
}
