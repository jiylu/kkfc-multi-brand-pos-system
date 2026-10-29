import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_nav_item.dart';

/// Phone navigation bar.
class KitchenBottomNav extends StatelessWidget {
  const KitchenBottomNav({super.key, required this.selected, this.onSelected});

  final KitchenDestination selected;
  final ValueChanged<KitchenDestination>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.kitchenChrome,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final d in KitchenDestination.values)
              Expanded(
                child: KitchenNavItem(
                  destination: d,
                  selected: d == selected,
                  onTap: onSelected == null ? null : () => onSelected!(d),
                ),
              ),
          ],
        ),
      ),
    );
  }
}