import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// "KITCHEN STAFF / DESIGN SAMPLE · NOT LIVE" marker (tablet only).
class KitchenSampleBadge extends StatelessWidget {
  const KitchenSampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCard,
        borderRadius: BorderRadius.circular(KitchenRadius.sm),
        border: Border.all(
          color: context.kitchenOutline,
          width: KitchenMetrics.borderWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: KitchenSpace.md,
          vertical: KitchenSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KITCHEN STAFF',
              style: text.labelMedium?.copyWith(
                color: context.kitchenText,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'DESIGN SAMPLE · NOT LIVE',
              style: text.labelSmall?.copyWith(color: context.kitchenTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}
