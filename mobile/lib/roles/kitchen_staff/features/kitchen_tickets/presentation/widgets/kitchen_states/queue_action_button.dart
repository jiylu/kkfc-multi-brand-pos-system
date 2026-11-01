import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';

/// Primary queue action. Pass a null [onPressed] for the disabled state
/// (e.g. "Loading..."). Swap for KkfcLoadingButton once real calls exist.
class QueueActionButton extends StatelessWidget {
  const QueueActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, KitchenMetrics.controlHeight),
        padding: EdgeInsets.symmetric(horizontal: KitchenSpace.xl),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KitchenRadius.sm),
        ),
      ),
      child: Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
