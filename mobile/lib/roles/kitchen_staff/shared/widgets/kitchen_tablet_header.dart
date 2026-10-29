import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_brand_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_segment_tabs.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_staff_identity.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

class KitchenTabletHeader extends StatelessWidget {
  const KitchenTabletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.kitchenChrome,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: KitchenSpace.lg, vertical: KitchenSpace.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(child: KitchenBrandCard()),
            SizedBox(width: KitchenSpace.md),
            const Flexible(
              child: KitchenSegmentTabs(
                labels: ['ALL PERMITTED BRANDS', 'KITCHEN OPERATIONS'],
                selectedIndex: 0,
              ),
            ),
            SizedBox(width: KitchenSpace.lg),
            const KitchenStaffIdentity(),
            SizedBox(width: KitchenSpace.sm),
            LogoutButton(color: context.kitchenOnChrome),
          ],
        ),
      ),
    );
  }
}
