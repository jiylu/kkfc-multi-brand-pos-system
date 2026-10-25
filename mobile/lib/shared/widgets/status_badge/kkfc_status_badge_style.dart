import 'package:flutter/material.dart';

import 'package:mobile/app/theme/semantic_colors.dart'; // verify path (KkfcTone)
import 'package:mobile/app/theme/theme_context.dart';

/// The color family a badge belongs to.
enum KkfcBadgeFamily { neutral, info, review, success, danger }

/// How the family's colors are applied.
enum KkfcBadgeVariant {
  /// Tinted background, matching border, dark text.
  soft,

  /// Solid fill, light text.
  solid,

  /// Plain surface with a grey border.
  outlined,

  /// Very light grey, for finished or historical states.
  subtle,
}

@immutable
class KkfcBadgeColors {
  const KkfcBadgeColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

KkfcBadgeColors resolveBadgeColors(
  BuildContext context,
  KkfcBadgeFamily family,
  KkfcBadgeVariant variant,
) {
  final c = context.semanticColors;

  switch (variant) {
    case KkfcBadgeVariant.outlined:
      return KkfcBadgeColors(
        background: c.bgSurface,
        border: c.borderStrong,
        foreground: c.textSecondary,
      );

    case KkfcBadgeVariant.subtle:
      return KkfcBadgeColors(
        background: c.bgCanvas,
        border: c.borderDefault,
        foreground: c.textSecondary,
      );

    case KkfcBadgeVariant.soft:
      final KkfcTone tone = switch (family) {
        KkfcBadgeFamily.neutral => c.tag,
        KkfcBadgeFamily.info => c.info,
        KkfcBadgeFamily.review => c.review,
        KkfcBadgeFamily.success => c.success,
        KkfcBadgeFamily.danger => c.danger,
      };
      return KkfcBadgeColors(
        background: tone.bg,
        border: tone.border ?? c.borderDefault,
        foreground: tone.fg,
      );

    case KkfcBadgeVariant.solid:
      if (family == KkfcBadgeFamily.neutral) {
        // Not used by any status today; kept so the switch stays exhaustive.
        return KkfcBadgeColors(
          background: c.textPrimary,
          border: c.textPrimary,
          foreground: c.textInverse,
        );
      }
      final KkfcTone tone = switch (family) {
        KkfcBadgeFamily.info => c.actionInfo,
        KkfcBadgeFamily.review => c.actionReview,
        KkfcBadgeFamily.success => c.actionSuccess,
        KkfcBadgeFamily.danger => c.ageLate,
        KkfcBadgeFamily.neutral => c.tag, // unreachable
      };
      return KkfcBadgeColors(
        background: tone.bg,
        border: tone.bg, // solid badges have no visible border
        foreground: tone.fg,
      );
  }
}