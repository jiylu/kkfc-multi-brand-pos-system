import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_breakpoints.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_bottom_nav.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_phone_header.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_side_nav.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_tablet_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

/// Header + navigation frame for every kitchen-staff screen.
/// Tablet: top header + side rail. Phone: header (+ optional tabs) + bottom nav.
class KitchenShell extends StatelessWidget {
  const KitchenShell({
    super.key,
    required this.selectedDestination,
    required this.body,
    this.phoneHeaderBottom,
    this.onDestinationSelected,
  });

  final KitchenDestination selectedDestination;
  final Widget body;
  final Widget? phoneHeaderBottom;
  final ValueChanged<KitchenDestination>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final tablet = context.isKitchenTablet;
    return KkfcScaffold(
      body: ColoredBox(
        color: context.kitchenPage,
        child: tablet ? _tablet() : _phone(),
      ),
    );
  }

  Widget _tablet() => Column(
        children: [
          const KitchenTabletHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitchenSideNav(
                  selected: selectedDestination,
                  onSelected: onDestinationSelected,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      );

  Widget _phone() => Column(
        children: [
          KitchenPhoneHeader(bottom: phoneHeaderBottom),
          Expanded(child: body),
          KitchenBottomNav(
            selected: selectedDestination,
            onSelected: onDestinationSelected,
          ),
        ],
      );
}