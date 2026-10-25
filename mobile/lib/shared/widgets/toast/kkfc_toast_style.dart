import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/theme_context.dart';

import 'package:mobile/shared/data/models/kkfc_toast_tone.dart';

@immutable
class KkfcToastStyle {
  const KkfcToastStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.action,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color action;

  factory KkfcToastStyle.fromTone(KkfcTone tone) => KkfcToastStyle(
        background: tone.bg,
        foreground: tone.fg,
        border: tone.border ?? Colors.transparent,
        action: tone.fg,
      );

  factory KkfcToastStyle.resolve(BuildContext context, KkfcToastTone tone) {
    final colors = context.semanticColors;
    switch (tone) {
      case KkfcToastTone.success:
        return KkfcToastStyle.fromTone(colors.success);
      case KkfcToastTone.warning:
        return KkfcToastStyle.fromTone(colors.warning);
      case KkfcToastTone.danger:
        return KkfcToastStyle.fromTone(colors.danger);
      case KkfcToastTone.inverse:
        final scheme = Theme.of(context).colorScheme;
        return KkfcToastStyle(
          background: scheme.inverseSurface,
          foreground: scheme.onInverseSurface,
          border: Colors.transparent,
          action: scheme.onInverseSurface,
        );
    }
  }

  static IconData defaultIcon(KkfcToastTone tone) => switch (tone) {
        KkfcToastTone.success => Symbols.check_circle,
        KkfcToastTone.inverse => Symbols.info,
        KkfcToastTone.warning => Symbols.warning,
        KkfcToastTone.danger => Symbols.error,
      };
}