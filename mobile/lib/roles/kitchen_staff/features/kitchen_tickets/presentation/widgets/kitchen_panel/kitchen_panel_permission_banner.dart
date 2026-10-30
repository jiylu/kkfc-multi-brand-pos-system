import 'package:flutter/material.dart';

/// Information banner informing about backend permission requirements.
class KitchenPanelPermissionBanner extends StatelessWidget {
  const KitchenPanelPermissionBanner({
    super.key,
    this.message = 'Preparer permission requires Backend approval.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
