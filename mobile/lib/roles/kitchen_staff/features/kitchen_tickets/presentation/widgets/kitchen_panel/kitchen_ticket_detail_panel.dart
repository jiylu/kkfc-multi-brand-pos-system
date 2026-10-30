import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_actions.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_confirm_checklist.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_header.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_permission_banner.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_ticket_info.dart';

/// The ticket detail panel (right panel on tablet, full queue detail on phone).
///
/// Designed as a stateless component with sample data defaults and callbacks
/// for closing the panel or acknowledging the ticket.
class KitchenTicketDetailPanel extends StatelessWidget {
  const KitchenTicketDetailPanel({
    super.key,
    this.ticket = KitchenBoardSampleData.t014,
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.width,
    this.backButtonLabel = 'Back to board',
    this.acknowledgeButtonLabel = 'Acknowledge ticket',
    this.paymentStatus = 'PAYMENT · UNPAID',
    this.confirmationItems = const [
      'Check all items and modifiers',
      'Verify brand and destination',
    ],
    this.permissionNotice = 'Preparer permission requires Backend approval.',
  });

  /// Ticket data to display (defaults to T-014 sample data).
  final KitchenBoardItem ticket;

  /// Callback when user taps close button "×" or back button.
  final VoidCallback? onClose;

  /// Optional specific callback for the back button. Defaults to [onClose].
  final VoidCallback? onBack;

  /// Callback when user taps "Acknowledge ticket".
  final VoidCallback? onAcknowledge;

  /// Optional fixed width for the panel (e.g. 400 or 440 on tablet).
  final double? width;

  final String backButtonLabel;
  final String acknowledgeButtonLabel;
  final String paymentStatus;
  final List<String> confirmationItems;
  final String permissionNotice;

  void _handleDismiss() {
    if (onClose != null) {
      onClose!();
    } else if (onBack != null) {
      onBack!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = ticket.ticket;

    final panelWidget = Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          KitchenPanelHeader(
            badgeText: 'NEW ORDER · QUEUED',
            ticketNumber: ticketData.ticketNumber,
            subtitle: 'Ready to acknowledge',
            onClose: _handleDismiss,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitchenPanelTicketInfo(
                    ticket: ticketData,
                    paymentStatus: paymentStatus,
                  ),
                  const SizedBox(height: 12),
                  KitchenPanelConfirmChecklist(
                    items: confirmationItems,
                  ),
                  const SizedBox(height: 12),
                  KitchenPanelPermissionBanner(
                    message: permissionNotice,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          // Action Buttons
          KitchenPanelActions(
            backLabel: backButtonLabel,
            acknowledgeLabel: acknowledgeButtonLabel,
            onClose: _handleDismiss,
            onBack: _handleDismiss,
            onAcknowledge: onAcknowledge,
            isAcknowledgeEnabled: ticket.isActionEnabled,
          ),
        ],
      ),
    );

    return panelWidget;
  }
}

/// Alias for [KitchenTicketDetailPanel].
typedef KitchenTicketPanel = KitchenTicketDetailPanel;
