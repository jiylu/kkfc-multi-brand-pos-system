import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_segment_tabs.dart';

/// Phone-only NEW / COOK / QC / READY stage tabs (defaults to NEW selected).
class KitchenStageTabs extends StatelessWidget {
  const KitchenStageTabs({super.key, this.selectedIndex = 0, this.onSelected});

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        KitchenSpace.md,
        0,
        KitchenSpace.md,
        KitchenSpace.md,
      ),
      child: KitchenSegmentTabs(
        labels: const ['NEW', 'COOK', 'QC', 'READY'],
        selectedIndex: selectedIndex,
        onSelected: onSelected,
        expand: true,
      ),
    );
  }
}
