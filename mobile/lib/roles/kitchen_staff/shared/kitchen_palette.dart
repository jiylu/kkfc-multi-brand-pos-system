import 'package:flutter/material.dart';

/// Kitchen chrome colors, all derived from the active ColorScheme.
/// Single place to remap if the scheme roles differ from the design.
extension KitchenPalette on BuildContext {
  ColorScheme get _scheme => Theme.of(this).colorScheme;

  Color get kitchenChrome => _scheme.primary; // navy bars
  Color get kitchenOnChrome => _scheme.onPrimary;
  Color get kitchenChromeRaised =>
      Color.alphaBlend(_scheme.onPrimary.withValues(alpha: 0.12), _scheme.primary);
  Color get kitchenSelected => _scheme.secondaryContainer; // peach
  Color get kitchenOnSelected => _scheme.onSecondaryContainer;
  Color get kitchenPage => _scheme.surface;
  Color get kitchenCard => _scheme.surfaceContainerLowest;
  Color get kitchenCardMuted => _scheme.surfaceContainerLow;
  Color get kitchenOutline => _scheme.outlineVariant;
  Color get kitchenText => _scheme.onSurface;
  Color get kitchenTextMuted => _scheme.onSurfaceVariant;
}