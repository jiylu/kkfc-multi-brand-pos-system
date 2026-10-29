import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Green check tile + "Queue is clear".
class QueueClearHeader extends StatelessWidget {
  const QueueClearHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final tone = context.semanticColors.success;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone.bg,
            borderRadius: BorderRadius.circular(KitchenRadius.md),
          ),
          child: Padding(
            padding: EdgeInsets.all(KitchenSpace.md),
            child: Icon(Symbols.check, color: tone.fg),
          ),
        ),
        SizedBox(width: KitchenSpace.md),
        Expanded(
          child: Text(
            'Queue is clear',
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