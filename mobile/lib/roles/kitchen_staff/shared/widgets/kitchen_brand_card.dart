import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// White "KKFC POS / Shared kitchen" card in the header.
class KitchenBrandCard extends StatelessWidget {
  const KitchenBrandCard({
    super.key,
    this.title = 'KKFC POS',
    this.subtitle = 'Shared kitchen',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCard,
        borderRadius: BorderRadius.circular(KitchenRadius.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: KitchenSpace.md, vertical: KitchenSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: text.titleSmall?.copyWith(
                    color: context.kitchenText, fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: text.labelSmall?.copyWith(color: context.kitchenTextMuted)),
          ],
        ),
      ),
    );
  }
}