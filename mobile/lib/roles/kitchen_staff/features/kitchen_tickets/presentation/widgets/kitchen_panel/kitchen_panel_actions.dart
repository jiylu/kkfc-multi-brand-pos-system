import 'package:flutter/material.dart';

/// Bottom action buttons for the kitchen ticket panel:
/// - "Back to board" (or "Back to brand") to dismiss/close the panel.
/// - "Acknowledge ticket" to transition the ticket to the next stage.
class KitchenPanelActions extends StatelessWidget {
  const KitchenPanelActions({
    super.key,
    this.backLabel = 'Back to board',
    this.acknowledgeLabel = 'Acknowledge ticket',
    this.isQC = false,
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.onPassQC,
    this.onFailQC,
    this.isAcknowledgeEnabled = true,
  });

  final String backLabel;
  final String acknowledgeLabel;
  final bool isQC;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onPassQC;
  final VoidCallback? onFailQC;
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
    if (isQC) {
      final passLabel = backLabel.isEmpty || backLabel == 'Back to board'
          ? 'Pass QC'
          : backLabel;
      final failLabel = acknowledgeLabel.isEmpty || acknowledgeLabel == 'Acknowledge ticket'
          ? 'Fail QC'
          : acknowledgeLabel;

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('kitchen_panel_pass_qc_button'),
                  onPressed: onPassQC ?? _handleBack,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(passLabel),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('kitchen_panel_fail_qc_button'),
                  onPressed: isAcknowledgeEnabled ? (onFailQC ?? onAcknowledge) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
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
                  child: Text(failLabel),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                  foregroundColor: backLabel == 'History (pending)'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                  side: BorderSide(
                    color: backLabel == 'History (pending)'
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFCBD5E1),
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
