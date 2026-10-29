import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_nav_item.dart';

/// Tablet navigation rail.
class KitchenSideNav extends StatelessWidget {
  const KitchenSideNav({super.key, required this.selected, this.onSelected});

  final KitchenDestination selected;
  final ValueChanged<KitchenDestination>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.kitchenChrome,
      child: SizedBox(
        width: KitchenMetrics.sideNavWidth,
        child: Padding(
          padding: EdgeInsets.all(KitchenSpace.sm),
          child: Column(
            children: [
              for (final d in KitchenDestination.values) ...[
                KitchenNavItem(
                  destination: d,
                  selected: d == selected,
                  borderRadius: BorderRadius.circular(KitchenRadius.md),
                  onTap: onSelected == null ? null : () => onSelected!(d),
                ),
                SizedBox(height: KitchenSpace.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}