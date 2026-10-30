import 'package:flutter/material.dart';

import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/shared/shared_layout.dart';

import 'cancel_tone.dart';

/// Right-hand "ORDER CONTEXT" card on tablet (design frame 10) and the tinted
/// note that replaces it on phone (design frames 10-15).
class CancelContextCard extends StatelessWidget {
  const CancelContextCard({
    super.key,
    required this.step,
    required this.body,
    required this.stateLabel,
    this.stateCaption = 'DESIGN REVIEW STATE',
    this.compact = false,
  });

  final CancelOrderStep step;
  final String body;

  /// Copy of the state chip, e.g. "SERVER CONFIRMED".
  final String stateLabel;

  /// Caption above [stateLabel]. The demo screens label it as a design review
  /// state; a live order labels it as the server state.
  final String stateCaption;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final tone = cancelTone(context, step.tone);
    final chipTone = cancelTone(
      context,
      step == CancelOrderStep.cancelled ? CancelTone.success : step.tone,
    );

    if (compact) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(MenuSpace.md),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(MenuRadius.md),
        ),
        child: Text(body, style: text.bodySmall?.copyWith(color: tone.fg)),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MenuSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MenuRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: MenuBorder.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MenuSpace.md,
              vertical: MenuSpace.xs,
            ),
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: BorderRadius.circular(MenuRadius.sm),
            ),
            child: Text(
              step.bannerLabel,
              style: text.labelSmall?.copyWith(
                color: tone.fg,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: MenuSpace.lg),
          Text(
            step.bannerLabel,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: MenuSpace.sm),
          Text(
            body,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: MenuSpace.xl),
          Text(
            stateCaption,
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: MenuSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MenuSpace.md,
              vertical: MenuSpace.sm,
            ),
            decoration: BoxDecoration(
              color: chipTone.bg,
              borderRadius: BorderRadius.circular(MenuRadius.sm),
            ),
            child: Text(
              stateLabel,
              style: text.labelMedium?.copyWith(color: chipTone.fg),
            ),
          ),
        ],
      ),
    );
  }
}
