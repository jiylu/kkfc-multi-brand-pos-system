import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_brand_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_staff_identity.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

/// Phone header. [bottom] hosts the stage tabs when a screen has them.
class KitchenPhoneHeader extends StatelessWidget {
  const KitchenPhoneHeader({
    super.key,
    this.bottom,
    this.role = 'Kitchen staff',
    this.status = 'Authorized',
  });

  final Widget? bottom;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.kitchenChrome,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(KitchenSpace.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Flexible(child: KitchenBrandCard()),
                SizedBox(width: KitchenSpace.md),
                Flexible(
                  child: KitchenStaffIdentity(role: role, status: status),
                ),
                SizedBox(width: KitchenSpace.sm),
                LogoutButton(
                  color: context.kitchenOnChrome,
                  constraints: const BoxConstraints(
                    minWidth: KitchenMetrics.controlHeight,
                    minHeight: KitchenMetrics.controlHeight,
                  ),
                ),
                IconButton(
                  tooltip: 'More',
                  constraints: const BoxConstraints(
                    minWidth: KitchenMetrics.controlHeight,
                    minHeight: KitchenMetrics.controlHeight,
                  ),
                  onPressed: null, // static for now
                  icon: Icon(Symbols.more_vert, color: context.kitchenOnChrome),
                ),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}
