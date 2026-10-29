import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Tablet-only "DESIGN-ONLY EXAMPLE / No active tasks" card.
class DesignOnlyExampleCard extends StatelessWidget {
  const DesignOnlyExampleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCardMuted,
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        border: Border.all(
            color: context.kitchenOutline, width: KitchenMetrics.borderWidth),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(KitchenSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DESIGN-ONLY EXAMPLE',
                  style: text.labelSmall?.copyWith(color: context.kitchenTextMuted)),
              SizedBox(height: KitchenSpace.lg),
              Text('No active tasks',
                  style: text.titleMedium?.copyWith(
                      color: context.kitchenText, fontWeight: FontWeight.w700)),
              SizedBox(height: KitchenSpace.lg),
              Text(
                'A confirmed empty queue means no pending tickets for these '
                'filters. Check again after new orders arrive.',
                style: text.bodySmall?.copyWith(color: context.kitchenTextMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}