import 'package:flutter/material.dart';

import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge_style.dart';

/// A small pill showing an order, ticket, or payment status.
class KkfcStatusBadge extends StatelessWidget {
  const KkfcStatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  final KkfcStatus status;

  /// Overrides the default label, for example for a translation.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors =
        resolveBadgeColors(context, status.family, status.variant);
    final text = label ?? status.label;
    final icon = status.icon;

    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(KkfcRadius.sm),
            border: Border.all(
              width: KkfcBorderWidth.thin, // verify
              color: colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KkfcSpace.s12,
              vertical: KkfcSpace.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: KkfcSizing.iconSm, color: colors.foreground),
                  const SizedBox(width: KkfcSpace.s8),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: colors.foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}