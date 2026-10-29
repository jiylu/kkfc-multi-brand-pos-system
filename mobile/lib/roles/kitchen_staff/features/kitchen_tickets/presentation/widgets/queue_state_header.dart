import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Icon tile + headline ("Queue is clear", "Loading Kitchen tickets").
class QueueStateHeader extends StatelessWidget {
  const QueueStateHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final KkfcTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone.bg,
            borderRadius: BorderRadius.circular(KitchenRadius.md),
          ),
          child: Padding(
            padding: EdgeInsets.all(KitchenSpace.md),
            child: Icon(icon, color: tone.fg),
          ),
        ),
        SizedBox(width: KitchenSpace.md),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.kitchenText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}