import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Icon over label. Used by both the tablet side nav and phone bottom nav.
class KitchenNavItem extends StatelessWidget {
  const KitchenNavItem({
    super.key,
    required this.destination,
    required this.selected,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  final KitchenDestination destination;
  final bool selected;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.kitchenOnSelected : context.kitchenOnChrome;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: selected ? context.kitchenSelected : Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KitchenMetrics.controlHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: KitchenSpace.xs,
                vertical: KitchenSpace.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(destination.icon, color: color),
                  SizedBox(height: KitchenSpace.xs),
                  Text(
                    destination.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}