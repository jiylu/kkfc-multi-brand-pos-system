import 'package:flutter/material.dart';

/// Must match the `family:` names in pubspec.yaml exactly.
abstract final class KkfcFonts {
  static const numeric = 'IBMPlexSansCondensed'; // tickets, timers, prices, totals
  static const text = 'AtkinsonHyperlegibleNext'; // all UI text
  static const mono = 'AtkinsonHyperlegibleMono'; // order and platform references
}

// Tabular digits keep columns aligned; slashed zero separates 0 from O.
const _numberFeatures = [FontFeature.tabularFigures(), FontFeature.slashedZero()];

TextStyle _style(
  String family,
  FontWeight weight,
  double size,
  double lineHeight,
  double letterSpacing, {
  List<FontFeature>? features,
}) {
  return TextStyle(
    fontFamily: family,
    fontWeight: weight,
    fontSize: size,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    fontFeatures: features,
  );
}

abstract final class KkfcTypography {
  // Kitchen display (read from 1 to 1.5 m)
  static final kdsTicket = _style(KkfcFonts.numeric, FontWeight.w700, 48, 52, 0, features: _numberFeatures);
  static final kdsTimer = _style(KkfcFonts.numeric, FontWeight.w600, 32, 36, 0, features: _numberFeatures);
  static final kdsItem = _style(KkfcFonts.text, FontWeight.w600, 24, 30, 0);
  static final kdsModifier = _style(KkfcFonts.text, FontWeight.w500, 20, 26, 0);

  // Four-lane kitchen board
  static final kdsTicketCompact = _style(KkfcFonts.numeric, FontWeight.w700, 32, 36, 0, features: _numberFeatures);
  static final kdsTimerCompact = _style(KkfcFonts.numeric, FontWeight.w600, 22, 28, 0, features: _numberFeatures);
  static final kdsItemCompact = _style(KkfcFonts.text, FontWeight.w600, 18, 24, 0);
  static final kdsModifierCompact = _style(KkfcFonts.text, FontWeight.w500, 16, 22, 0);
  static final kdsGroup = _style(KkfcFonts.text, FontWeight.w700, 20, 26, 0);
  static final kdsGroupCompact = _style(KkfcFonts.text, FontWeight.w700, 16, 22, 0);

  // General UI
  static final display = _style(KkfcFonts.numeric, FontWeight.w700, 40, 44, 0, features: _numberFeatures);
  static final headline = _style(KkfcFonts.numeric, FontWeight.w600, 28, 34, 0);
  static final title = _style(KkfcFonts.text, FontWeight.w700, 20, 28, 0);
  static final bodyLg = _style(KkfcFonts.text, FontWeight.w400, 18, 26, 0);
  static final body = _style(KkfcFonts.text, FontWeight.w400, 16, 24, 0);
  static final labelLg = _style(KkfcFonts.text, FontWeight.w600, 16, 24, 0.2);
  static final label = _style(KkfcFonts.text, FontWeight.w600, 14, 20, 0.2);
  static final caption = _style(KkfcFonts.text, FontWeight.w500, 13, 18, 0.2);
  static final price = _style(KkfcFonts.numeric, FontWeight.w600, 18, 24, 0, features: _numberFeatures);
  static final reference = _style(KkfcFonts.mono, FontWeight.w500, 16, 22, 0);
}

/// Maps Material's text roles to the design's type scale.
final TextTheme kkfcTextTheme = TextTheme(
  displayLarge: KkfcTypography.display,
  headlineMedium: KkfcTypography.headline,
  titleLarge: KkfcTypography.title,
  bodyLarge: KkfcTypography.bodyLg,
  bodyMedium: KkfcTypography.body,
  labelLarge: KkfcTypography.labelLg,
  labelMedium: KkfcTypography.label,
  bodySmall: KkfcTypography.caption,
);