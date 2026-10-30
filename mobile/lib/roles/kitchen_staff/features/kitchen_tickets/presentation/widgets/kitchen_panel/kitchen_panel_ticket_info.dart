import 'package:flutter/material.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Card displaying ticket details, status tags, and ordered items.
class KitchenPanelTicketInfo extends StatelessWidget {
  const KitchenPanelTicketInfo({
    super.key,
    this.ticket = _sampleTicket,
    this.statusOverride,
    this.paymentStatus = 'PAYMENT · UNPAID',
  });

  final KitchenTicketData ticket;
  final KkfcStatus? statusOverride;
  final String paymentStatus;

  static const _sampleTicket = KitchenTicketData(
    ticketNumber: 'T-014',
    elapsed: Duration(minutes: 6, seconds: 20),
    age: KitchenTicketAge.onTime,
    status: KkfcStatus.queued,
    channel: 'Dine-in',
    reference: 'Table 3 · sample',
    brand: AssignedBrand(id: 'brand-ai', code: 'AI', name: "Aurelia's Inasal"),
    items: [
      KitchenTicketItem(
        quantity: 2,
        name: 'Paa Inasal',
        modifiers: ['extra rice'],
      ),
      KitchenTicketItem(
        quantity: 1,
        name: 'Pecho Inasal',
        modifiers: ['no onions'],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = statusOverride ?? ticket.status;
    final statusLabel = switch (effectiveStatus) {
      KkfcStatus.queued => 'QUEUED',
      KkfcStatus.acknowledged => 'ACKNOWLEDGED',
      KkfcStatus.preparing => 'PREPARING',
      KkfcStatus.checking => 'CHECKING',
      KkfcStatus.reworking => 'REWORKING',
      KkfcStatus.ready => 'READY',
      KkfcStatus.handedOver => 'HANDED_OVER',
      _ => effectiveStatus.name.toUpperCase(),
    };

    final (statusBg, statusFg) = switch (effectiveStatus) {
      KkfcStatus.queued || KkfcStatus.acknowledged => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
      ),
      KkfcStatus.preparing => (
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      ),
      KkfcStatus.checking || KkfcStatus.reworking => (
        const Color(0xFFEDE9FE),
        const Color(0xFF7C3AED),
      ),
      KkfcStatus.ready || KkfcStatus.handedOver => (
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
      ),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };

    final brandLine =
        '${ticket.ticketNumber} · ${ticket.brand.name.toUpperCase()}';
    final destinationLine = ticket.reference.contains('sample')
        ? '${ticket.channel} · ${ticket.reference}'
        : '${ticket.channel} · ${ticket.reference} · sample';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            brandLine,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            destinationLine,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusFg,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Text(
                  paymentStatus,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < ticket.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildItemRow(ticket.items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(KitchenTicketItem item) {
    final modifierSuffix = item.modifiers.isNotEmpty
        ? ' · ${item.modifiers.join(' · ')}'
        : '';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${item.quantity} × ${item.name}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          if (modifierSuffix.isNotEmpty)
            TextSpan(
              text: modifierSuffix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
        ],
      ),
    );
  }
}
