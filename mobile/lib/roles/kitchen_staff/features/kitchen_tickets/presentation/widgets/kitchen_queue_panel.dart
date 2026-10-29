import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// White card with the green accent on top that holds the queue content.
class KitchenQueuePanel extends StatelessWidget {
  const KitchenQueuePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCard,
        borderRadius: BorderRadius.circular(KitchenRadius.lg),
        border: Border(
          top: BorderSide(
            color: context.semanticColors.success.fg,
            width: KitchenMetrics.panelAccentWidth,
          ),
        ),
      ),
      child: Padding(padding: EdgeInsets.all(KitchenSpace.lg), child: child),
    );
  }
}