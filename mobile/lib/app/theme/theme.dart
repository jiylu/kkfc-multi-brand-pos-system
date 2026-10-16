import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'semantic_colors.dart';
import 'status_colors.dart';
import 'tokens.dart';

ThemeData _buildTheme(ColorScheme scheme, KkfcSemanticColors semantic, KkfcStatusColors status) {
  OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: semantic.bgCanvas,
    extensions: [semantic, status],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: semantic.bgSurface,
      border: inputBorder(semantic.borderStrong, KkfcBorderWidth.thin),
      enabledBorder: inputBorder(semantic.borderStrong, KkfcBorderWidth.thin),
      focusedBorder: inputBorder(semantic.borderFocus, KkfcBorderWidth.focus),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, KkfcSizing.controlMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KkfcRadius.md)),
      ),
    ),
  );
}

final ThemeData counterTheme = _buildTheme(
  kkfcCounterScheme,
  KkfcSemanticColors.light,
  KkfcStatusColors.light,
);

final ThemeData kitchenTheme = _buildTheme(
  kkfcKitchenScheme,
  KkfcSemanticColors.dark,
  KkfcStatusColors.dark,
);