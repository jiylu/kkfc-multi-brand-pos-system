import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Read-only "All brands · All channels · Active tickets" summary (tablet).
class KitchenFilterBar extends StatelessWidget {
  const KitchenFilterBar({
    super.key,
    this.filters = const ['All brands', 'All channels', 'Active tickets'],
    this.trailing,
  });

  final List<String> filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: context.kitchenText, fontWeight: FontWeight.w700);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCard,
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        border: Border.all(
          color: context.kitchenOutline,
          width: KitchenMetrics.borderWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: KitchenSpace.md,
          vertical: KitchenSpace.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: KitchenSpace.md,
                runSpacing: KitchenSpace.xs,
                children: [
                  for (var i = 0; i < filters.length; i++) ...[
                    if (i > 0) Text('·', style: label),
                    Text(filters[i], style: label),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: KitchenSpace.md),
              Flexible(child: trailing!),
            ],
          ],
        ),
      ),
    );
  }
}
