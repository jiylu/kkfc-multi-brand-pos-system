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
    this.activeTicket = KitchenBoardSampleData.t014,
    this.upNextTicket = KitchenBoardSampleData.t018,
    this.onTicketAction,
  });

  final String stageTitle;
  final String stageCount;
  final KitchenBoardItem activeTicket;
  final KitchenBoardItem upNextTicket;
  final void Function(KitchenBoardItem item)? onTicketAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stage pill banner (e.g. "NEW ORDERS      02")
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6E4EE), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stageTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF0284C7),
                ),
              ),
              Text(
                stageCount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
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
