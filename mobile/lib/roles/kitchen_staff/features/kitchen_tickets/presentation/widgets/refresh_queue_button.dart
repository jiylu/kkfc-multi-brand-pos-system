import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';

/// Primary action. Static for now: onPressed is null until wired.
/// Swap for KkfcLoadingButton once the refresh call exists.
class RefreshQueueButton extends StatelessWidget {
  const RefreshQueueButton({super.key, this.onPressed, this.fullWidth = false});

  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed ?? () {},
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, KitchenMetrics.controlHeight),
        padding: EdgeInsets.symmetric(horizontal: KitchenSpace.xl),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KitchenRadius.sm)),
      ),
      child: const Text('Refresh queue'),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}