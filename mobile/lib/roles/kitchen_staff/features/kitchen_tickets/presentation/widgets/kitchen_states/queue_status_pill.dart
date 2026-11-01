import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';

/// Uppercase status strip at the top of the queue panel
/// ("NO ACTIVE TICKETS", "SYNC IN PROGRESS", ...).
class QueueStatusPill extends StatelessWidget {
  const QueueStatusPill({super.key, required this.label, required this.tone});

  final String label;
  final KkfcTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(KitchenRadius.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: KitchenSpace.md,
          vertical: KitchenSpace.sm,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: tone.fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
