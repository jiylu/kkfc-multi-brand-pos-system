import 'package:flutter/material.dart';

import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/shared/shared_layout.dart';

/// Prototype-only switcher so QA can open every design frame (10-15) without
/// waiting for the cancellation API. Remove once server responses drive the
/// step.
class CancelPrototypeStates extends StatelessWidget {
  const CancelPrototypeStates({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final CancelOrderStep current;
  final ValueChanged<CancelOrderStep> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIGMA QA ONLY · SAMPLE STATES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: MenuSpace.sm),
        Wrap(
          spacing: MenuSpace.sm,
          runSpacing: MenuSpace.sm,
          children: [
            for (final step in CancelOrderStep.values)
              ChoiceChip(
                label: Text(step.label),
                selected: step == current,
                onSelected: (_) => onSelected(step),
              ),
          ],
        ),
      ],
    );
  }
}
