import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

abstract final class MenuSpace {
  static const double xs = KkfcSpace.s4;
  static const double sm = KkfcSpace.s8;
  static const double md = KkfcSpace.s12;
  static const double lg = KkfcSpace.s16;
  static const double xl = KkfcSpace.s24;
  static const double xxl = KkfcSpace.s64;
}

abstract final class MenuRadius {
  static const double sm = KkfcRadius.sm;
  static const double md = KkfcRadius.md;
  static const double lg = KkfcRadius.lg;
}

abstract final class MenuBorder {
  static const double thin = KkfcBorderWidth.thin;
  static const double thick = KkfcBorderWidth.thick;
}

abstract final class MenuLayout {
  static const double compactMax = 600; // below: phone layout
  static const double wideMin = 1000; // from here: cart panel on the right
  static const double cartPanelWidth = 380;
  static const double railWidth = KkfcSizing.navRail;
  static const double minCardWidth = 168;
  static const double disabledOpacity = 0.6;
}

abstract final class MenuMotion {
  static const Duration fast = KkfcMotion.fast;
  static const Duration medium = KkfcMotion.base;
  static const Duration slow = KkfcMotion.slow;
  static const Curve curve = Curves.easeOutCubic;
}

extension MenuMotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Every animation duration goes through this so the OS
  /// "reduce motion" setting is respected.
  Duration motion(Duration d) => reduceMotion ? Duration.zero : d;
}
