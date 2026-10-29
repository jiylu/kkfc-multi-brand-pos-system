import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_segment_tabs.dart';

/// Phone-only NEW / COOK / QC / READY stage tabs (static: NEW selected).
class KitchenStageTabs extends StatelessWidget {
  const KitchenStageTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          KitchenSpace.md, 0, KitchenSpace.md, KitchenSpace.md),
      child: const KitchenSegmentTabs(
        labels: ['NEW', 'COOK', 'QC', 'READY'],
        selectedIndex: 0,
        expand: true,
      ),
    );
  }
}