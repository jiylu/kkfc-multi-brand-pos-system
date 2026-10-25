import 'package:flutter/widgets.dart';
import 'package:mobile/app/theme/tokens.dart';

abstract final class KkfcToastMetrics {
  // Layout breakpoint: below this the toast stretches edge to edge.
  static const double compactBreakpoint = 600;
  static const double maxWidth = 560;

  // Spacing (confirm token names)
  static final double screenGap = KkfcSpace.s16;
  static final double paddingX = KkfcSpace.s24;
  static final double paddingY = KkfcSpace.s16;
  static final double paddingEndWithAction = KkfcSpace.s8;
  static final double gap = KkfcSpace.s16 ;

  // Shape
  static final double radius = KkfcRadius.md;
  static final double borderWidth = KkfcBorderWidth.thin;

  // Sizing
  static final double minHeight = KkfcSizing.controlLg; // 56
  static final double iconSize = KkfcSizing.iconMd;
  static const Size actionMinSize = Size(48, 48); // touch target
  static const double actionPaddingX = 12;
  static const double floatingElevation = 4;

  // Motion
  static final Duration enter = KkfcMotion.base;
  static final Duration exit = KkfcMotion.fast;
  static const double slideFraction = 0.4; // of the toast's own height
  static const double scaleFrom = 0.96;

  // How long a toast stays when not persistent
  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration actionDuration = Duration(seconds: 8);
}