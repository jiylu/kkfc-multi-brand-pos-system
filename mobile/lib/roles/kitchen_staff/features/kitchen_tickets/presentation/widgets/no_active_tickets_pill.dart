import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';

/// "NO ACTIVE TICKETS" status strip. Uses the success tone.
class NoActiveTicketsPill extends StatelessWidget {
  const NoActiveTicketsPill({super.key});

  @override
  Widget build(BuildContext context) {
    final tone = context.semanticColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(KitchenRadius.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: KitchenSpace.md, vertical: KitchenSpace.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'NO ACTIVE TICKETS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone.fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}