import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/up_next_ticket_card.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';

/// Single-stage queue view for phone layout.
class KitchenBoardPhoneView extends StatelessWidget {
  const KitchenBoardPhoneView({
    super.key,
    this.stageTitle = 'NEW ORDERS',
    this.stageCount = '02',
    this.stageBackgroundColor,
    this.stageBorderColor,
    this.stageColor,
    this.activeTicket = KitchenBoardSampleData.t014,
    this.upNextTicket = KitchenBoardSampleData.t018,
    this.onTicketAction,
  });

  final String stageTitle;
  final String stageCount;
  final Color? stageBackgroundColor;
  final Color? stageBorderColor;
  final Color? stageColor;
  final KitchenBoardItem activeTicket;
  final KitchenBoardItem upNextTicket;
  final void Function(KitchenBoardItem item)? onTicketAction;

  @override
  Widget build(BuildContext context) {
    final isCooking = stageTitle.toUpperCase().contains('COOK');
    final effectiveBg = stageBackgroundColor ??
        (isCooking ? const Color(0xFFFDF6EE) : const Color(0xFFF1F6FB));
    final effectiveBorder = stageBorderColor ??
        (isCooking ? const Color(0xFFF7E2CD) : const Color(0xFFD6E4EE));
    final effectiveColor = stageColor ??
        (isCooking ? const Color(0xFFD97706) : const Color(0xFF0284C7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stage pill banner (e.g. "NEW ORDERS      02" or "COOKING      03")
        Container(
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: effectiveBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stageTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: effectiveColor,
                ),
              ),
              Text(
                stageCount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Active Ticket Card
        KitchenTicketCard.board(
          ticket: activeTicket.ticket,
          actionLabel: activeTicket.actionLabel,
          isActionEnabled: activeTicket.isActionEnabled,
          onAction: onTicketAction != null
              ? () => onTicketAction!(activeTicket)
              : null,
        ),
        const SizedBox(height: 12),
        // Up Next Ticket Card
        UpNextTicketCard(
          ticket: upNextTicket.ticket,
          onTap: onTicketAction != null
              ? () => onTicketAction!(upNextTicket)
              : null,
        ),
      ],
    );
  }
}
