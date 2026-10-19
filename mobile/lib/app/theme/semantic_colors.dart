import 'package:flutter/material.dart';

@immutable
class KkfcTone {
  const KkfcTone({required this.bg, required this.fg, this.border});

  final Color bg;
  final Color fg;
  final Color? border;

  static KkfcTone lerp(KkfcTone a, KkfcTone b, double t) => KkfcTone(
    bg: Color.lerp(a.bg, b.bg, t)!,
    fg: Color.lerp(a.fg, b.fg, t)!,
    border: Color.lerp(a.border, b.border, t),
  );
}

@immutable
class KkfcSemanticColors extends ThemeExtension<KkfcSemanticColors> {
  const KkfcSemanticColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgRaised,
    required this.bgSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textInverse,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderFocusInverse,
    required this.tag,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.actionSuccess,
    required this.ageNormal,
    required this.ageCaution,
    required this.ageLate,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgRaised;
  final Color bgSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textInverse;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderFocus;
  final Color borderFocusInverse;
  final KkfcTone tag;
  final KkfcTone success;
  final KkfcTone warning;
  final KkfcTone danger;
  final KkfcTone info;
  final KkfcTone actionSuccess;
  final KkfcTone ageNormal;
  final KkfcTone ageCaution;
  final KkfcTone ageLate;

  // Light (counter), from theme/light
  static const light = KkfcSemanticColors(
    bgCanvas: Color(0xFFF2F4F8), // ink.50
    bgSurface: Color(0xFFFFFFFF), // white
    bgRaised: Color(0xFFFFFFFF), // white
    bgSunken: Color(0xFFE3E7EF), // ink.100
    textPrimary: Color(0xFF141D2E), // ink.900
    textSecondary: Color(0xFF374763), // ink.600
    textDisabled: Color(0xFF6E7E9C), // ink.400
    textInverse: Color(0xFFFFFFFF), // white
    borderDefault: Color(0xFFC7CFDD), // ink.200
    borderStrong: Color(0xFF6E7E9C), // ink.400
    borderFocus: Color(0xFF1F5FD6), // blue.600
    borderFocusInverse: Color(0xFF93B4EE), // blue.300
    tag: KkfcTone(
      bg: Color(0xFFE3E7EF),
      fg: Color(0xFF283650),
    ), // ink.100 / ink.700
    success: KkfcTone(
      bg: Color(0xFFD9F2EC),
      fg: Color(0xFF0A5C4E),
      border: Color(0xFF86D5C4),
    ),
    warning: KkfcTone(
      bg: Color(0xFFFFF3CC),
      fg: Color(0xFF6E4A00),
      border: Color(0xFFFFD24D),
    ),
    danger: KkfcTone(
      bg: Color(0xFFFCE4E1),
      fg: Color(0xFF861B10),
      border: Color(0xFFF4A398),
    ),
    info: KkfcTone(
      bg: Color(0xFFE1EAFB),
      fg: Color(0xFF173F8A),
      border: Color(0xFF93B4EE),
    ),
    actionSuccess: KkfcTone(
      bg: Color(0xFF0E7A68),
      fg: Color(0xFFFFFFFF),
    ), // teal.700 / white
    ageNormal: KkfcTone(
      bg: Color(0xFFE3E7EF),
      fg: Color(0xFF141D2E),
    ), // ink.100 / ink.900
    ageCaution: KkfcTone(
      bg: Color(0xFFF5B400),
      fg: Color(0xFF0B111D),
    ), // amber.500 / ink.950
    ageLate: KkfcTone(
      bg: Color(0xFFC62A1A),
      fg: Color(0xFFFFFFFF),
    ), // red.600 / white
  );

  // Dark (kitchen), from theme/dark
  static const dark = KkfcSemanticColors(
    bgCanvas: Color(0xFF0B111D), // ink.950
    bgSurface: Color(0xFF141D2E), // ink.900
    bgRaised: Color(0xFF1D2940), // ink.800
    bgSunken: Color(0xFF0B111D), // ink.950
    textPrimary: Color(0xFFF2F4F8), // ink.50
    textSecondary: Color(0xFF9CA9C0), // ink.300
    textDisabled: Color(0xFF4C5D7D), // ink.500
    textInverse: Color(0xFF0B111D), // ink.950
    borderDefault: Color(0xFF283650), // ink.700
    borderStrong: Color(0xFF6E7E9C), // ink.400
    borderFocus: Color(0xFF93B4EE), // blue.300
    borderFocusInverse: Color(0xFF1F5FD6), // blue.600
    tag: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFE3E7EF),
    ), // ink.800 / ink.100
    success: KkfcTone(
      bg: Color(0xFF052A24),
      fg: Color(0xFF86D5C4),
      border: Color(0xFF0E7A68),
    ),
    warning: KkfcTone(
      bg: Color(0xFF332300),
      fg: Color(0xFFFFD24D),
      border: Color(0xFF6E4A00),
    ),
    danger: KkfcTone(
      bg: Color(0xFF3D0C06),
      fg: Color(0xFFF4A398),
      border: Color(0xFFC62A1A),
    ),
    info: KkfcTone(
      bg: Color(0xFF0C1D3F),
      fg: Color(0xFF93B4EE),
      border: Color(0xFF173F8A),
    ),
    actionSuccess: KkfcTone(
      bg: Color(0xFF0E7A68),
      fg: Color(0xFFFFFFFF),
    ), // teal.700 / white
    ageNormal: KkfcTone(
      bg: Color(0xFF1D2940),
      fg: Color(0xFFF2F4F8),
    ), // ink.800 / ink.50
    ageCaution: KkfcTone(
      bg: Color(0xFFF5B400),
      fg: Color(0xFF0B111D),
    ), // amber.500 / ink.950
    ageLate: KkfcTone(
      bg: Color(0xFFC62A1A),
      fg: Color(0xFFFFFFFF),
    ), // red.600 / white
  );

  @override
  KkfcSemanticColors copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgRaised,
    Color? bgSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textInverse,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderFocusInverse,
    KkfcTone? tag,
    KkfcTone? success,
    KkfcTone? warning,
    KkfcTone? danger,
    KkfcTone? info,
    KkfcTone? actionSuccess,
    KkfcTone? ageNormal,
    KkfcTone? ageCaution,
    KkfcTone? ageLate,
  }) {
    return KkfcSemanticColors(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgRaised: bgRaised ?? this.bgRaised,
      bgSunken: bgSunken ?? this.bgSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderFocusInverse: borderFocusInverse ?? this.borderFocusInverse,
      tag: tag ?? this.tag,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      actionSuccess: actionSuccess ?? this.actionSuccess,
      ageNormal: ageNormal ?? this.ageNormal,
      ageCaution: ageCaution ?? this.ageCaution,
      ageLate: ageLate ?? this.ageLate,
    );
  }

  @override
  KkfcSemanticColors lerp(ThemeExtension<KkfcSemanticColors>? other, double t) {
    if (other is! KkfcSemanticColors) return this;
    return KkfcSemanticColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgRaised: Color.lerp(bgRaised, other.bgRaised, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderFocusInverse: Color.lerp(
        borderFocusInverse,
        other.borderFocusInverse,
        t,
      )!,
      tag: KkfcTone.lerp(tag, other.tag, t),
      success: KkfcTone.lerp(success, other.success, t),
      warning: KkfcTone.lerp(warning, other.warning, t),
      danger: KkfcTone.lerp(danger, other.danger, t),
      info: KkfcTone.lerp(info, other.info, t),
      actionSuccess: KkfcTone.lerp(actionSuccess, other.actionSuccess, t),
      ageNormal: KkfcTone.lerp(ageNormal, other.ageNormal, t),
      ageCaution: KkfcTone.lerp(ageCaution, other.ageCaution, t),
      ageLate: KkfcTone.lerp(ageLate, other.ageLate, t),
    );
  }
}
