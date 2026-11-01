import 'package:flutter/material.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';

/// Compact card showing the upcoming ticket in the phone queue.
class UpNextTicketCard extends StatelessWidget {
  const UpNextTicketCard({super.key, required this.ticket, this.onTap});

  final KitchenTicketData ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final elapsedStr = KitchenTicketHeader.formatElapsed(ticket.elapsed);
    final brandShort = ticket.brand.name.replaceAll(' · sample', '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UP NEXT · ${ticket.ticketNumber}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0284C7),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$brandShort · ${ticket.channel} · $elapsedStr',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < ticket.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              Text(
                '${ticket.items[i].quantity} × ${ticket.items[i].name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
