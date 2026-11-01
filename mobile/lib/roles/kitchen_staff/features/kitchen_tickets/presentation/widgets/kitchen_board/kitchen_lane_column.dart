import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';

class KitchenLaneColumn extends StatelessWidget {
  const KitchenLaneColumn({
    super.key,
    required this.title,
    required this.count,
    required this.tickets,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.badgeColor,
    this.onTicketAction,
  });

  factory KitchenLaneColumn.newOrders({
    Key? key,
    required List<KitchenBoardItem> tickets,
    void Function(KitchenBoardItem item)? onTicketAction,
  }) {
    return KitchenLaneColumn(
      key: key,
      title: 'NEW ORDERS',
      count: tickets.length.toString().padLeft(2, '0'),
      tickets: tickets,
      backgroundColor: const Color(0xFFF1F6FB),
      borderColor: const Color(0xFFD6E4EE),
      titleColor: const Color(0xFF0F2942),
      badgeColor: const Color(0xFF0284C7),
      onTicketAction: onTicketAction,
    );
  }

  factory KitchenLaneColumn.cooking({
    Key? key,
    required List<KitchenBoardItem> tickets,
    void Function(KitchenBoardItem item)? onTicketAction,
  }) {
    return KitchenLaneColumn(
      key: key,
      title: 'COOKING',
      count: tickets.length.toString().padLeft(2, '0'),
      tickets: tickets,
      backgroundColor: const Color(0xFFFDF6EE),
      borderColor: const Color(0xFFF7E2CD),
      titleColor: const Color(0xFF3B2314),
      badgeColor: const Color(0xFFD97706),
      onTicketAction: onTicketAction,
    );
  }

  factory KitchenLaneColumn.qualityCheck({
    Key? key,
    required List<KitchenBoardItem> tickets,
    void Function(KitchenBoardItem item)? onTicketAction,
  }) {
    return KitchenLaneColumn(
      key: key,
      title: 'QUALITY CHECK',
      count: tickets.length.toString().padLeft(2, '0'),
      tickets: tickets,
      backgroundColor: const Color(0xFFF7F3FD),
      borderColor: const Color(0xFFE8DCFA),
      titleColor: const Color(0xFF2E1C4D),
      badgeColor: const Color(0xFF7C3AED),
      onTicketAction: onTicketAction,
    );
  }

  factory KitchenLaneColumn.ready({
    Key? key,
    required List<KitchenBoardItem> tickets,
    void Function(KitchenBoardItem item)? onTicketAction,
  }) {
    return KitchenLaneColumn(
      key: key,
      title: 'READY',
      count: tickets.length.toString().padLeft(2, '0'),
      tickets: tickets,
      backgroundColor: const Color(0xFFF0FAF4),
      borderColor: const Color(0xFFD0EEDB),
      titleColor: const Color(0xFF133B23),
      badgeColor: const Color(0xFF16A34A),
      onTicketAction: onTicketAction,
    );
  }

  final String title;
  final String count;
  final List<KitchenBoardItem> tickets;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color badgeColor;
  final void Function(KitchenBoardItem item)? onTicketAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: titleColor,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < tickets.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            KitchenTicketCard.board(
              ticket: tickets[i].ticket,
              actionLabel: tickets[i].actionLabel,
              isActionEnabled: tickets[i].isActionEnabled,
              onAction: onTicketAction != null
                  ? () => onTicketAction!(tickets[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
