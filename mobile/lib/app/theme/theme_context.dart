import 'package:flutter/material.dart';

import 'brand_colors.dart';
import 'semantic_colors.dart';
import 'status_colors.dart';

extension KkfcThemeContext on BuildContext {
  KkfcSemanticColors get semanticColors =>
      Theme.of(this).extension<KkfcSemanticColors>()!;

  KkfcStatusColors get statusColors =>
      Theme.of(this).extension<KkfcStatusColors>()!;

  /// Only available once a brand has been applied with themeForBrand.
  KkfcBrandColors get brandColors =>
      Theme.of(this).extension<KkfcBrandColors>()!;
}