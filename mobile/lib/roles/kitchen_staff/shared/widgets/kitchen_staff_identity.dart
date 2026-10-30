import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// "Kitchen staff / Authorized workspace" text block on the navy header.
class KitchenStaffIdentity extends StatelessWidget {
  const KitchenStaffIdentity({
    super.key,
    this.role = 'Kitchen staff',
    this.status = 'Authorized workspace',
  });

  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = context.kitchenOnChrome;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: text.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(status, style: text.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
