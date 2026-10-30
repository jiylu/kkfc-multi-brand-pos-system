import 'package:flutter/material.dart';

/// Bottom action buttons for the kitchen ticket panel:
/// - "Back to board" (or "Back to brand") to dismiss/close the panel.
/// - "Acknowledge ticket" to transition the ticket to the next stage.
class KitchenPanelActions extends StatelessWidget {
  const KitchenPanelActions({
    super.key,
    this.backLabel = 'Back to board',
    this.acknowledgeLabel = 'Acknowledge ticket',
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.isAcknowledgeEnabled = true,
  });

  final String backLabel;
  final String acknowledgeLabel;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final VoidCallback? onAcknowledge;
  final bool isAcknowledgeEnabled;

  void _handleBack() {
    if (onBack != null) {
      onBack!();
    } else if (onClose != null) {
      onClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                key: const ValueKey('kitchen_panel_back_button'),
                onPressed: _handleBack,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: backLabel == 'Back to board'
                      ? 'Back to brand'
                      : (backLabel == 'Stay acknowledged'
                          ? 'Stay here'
                          : backLabel),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (backLabel == 'Stay acknowledged')
                        const Text(
                          'Stay here',
                          style: TextStyle(color: Colors.transparent),
                        )
                      else if (backLabel == 'Stay here')
                        const Text(
                          'Stay acknowledged',
                          style: TextStyle(color: Colors.transparent),
                        ),
                      Text(backLabel),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('kitchen_panel_acknowledge_button'),
                onPressed: isAcknowledgeEnabled ? onAcknowledge : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(acknowledgeLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
