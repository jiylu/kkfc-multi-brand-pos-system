import 'package:flutter/material.dart';

enum KkfcBrand {
  gamcheon(code: 'GC', displayName: 'Gamcheon', accent: Color(0xFF3D5A80)),
  aurelias(
    code: 'AI',
    displayName: "Aurelia's Inasal",
    accent: Color(0xFF9A4A1F),
  ),
  kingKungs(
    code: 'KK',
    displayName: 'King Kungs Kafé',
    accent: Color(0xFF5C4033),
  );

  const KkfcBrand({
    required this.code,
    required this.displayName,
    required this.accent,
  });

  final String code;
  final String displayName;
  // PLACEHOLDER until client assets arrive (D-02)
  final Color accent;
}

@immutable
class KkfcBrandColors extends ThemeExtension<KkfcBrandColors> {
  const KkfcBrandColors({required this.accent, required this.onAccent});

  factory KkfcBrandColors.of(KkfcBrand brand) =>
      KkfcBrandColors(accent: brand.accent, onAccent: const Color(0xFFFFFFFF));

  final Color accent;
  final Color onAccent;

  @override
  KkfcBrandColors copyWith({Color? accent, Color? onAccent}) => KkfcBrandColors(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
  );

  @override
  KkfcBrandColors lerp(ThemeExtension<KkfcBrandColors>? other, double t) {
    if (other is! KkfcBrandColors) return this;
    return KkfcBrandColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Applies a brand on top of a base mode theme (counterTheme or kitchenTheme).
ThemeData themeForBrand(ThemeData base, KkfcBrand brand) {
  return base.copyWith(
    extensions: [
      ...base.extensions.values.where((e) => e is! KkfcBrandColors),
      KkfcBrandColors.of(brand),
    ],
  );
}
