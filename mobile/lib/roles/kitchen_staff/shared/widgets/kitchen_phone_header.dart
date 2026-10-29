import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_brand_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_staff_identity.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

/// Phone header. [bottom] hosts the stage tabs when a screen has them.
class KitchenPhoneHeader extends StatelessWidget {
  const KitchenPhoneHeader({super.key, this.bottom});

  final Widget? bottom;

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
              children: [
                const Flexible(child: KitchenBrandCard()),
                SizedBox(width: KitchenSpace.md),
                const Flexible(child: KitchenStaffIdentity(status: 'Authorized')),
                const Spacer(),
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
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
