import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_action.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_meta.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

export 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

enum KitchenTicketVariant { standard, board }

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    this.onAction,
    this.isActionLoading = false,
    this.variant = KitchenTicketVariant.standard,
    this.actionLabel,
    this.isActionEnabled = true,
  });

  const KitchenTicketCard.board({
    super.key,
    required this.ticket,
    this.onAction,
    this.isActionLoading = false,
    this.actionLabel,
    this.isActionEnabled = true,
  }) : variant = KitchenTicketVariant.board;

  final KitchenTicketData ticket;

  /// Null hides the button (e.g. read-only boards).
  final VoidCallback? onAction;
  final bool isActionLoading;
  final KitchenTicketVariant variant;
  final String? actionLabel;
  final bool isActionEnabled;

  @override
  Widget build(BuildContext context) {
    if (variant == KitchenTicketVariant.board) {
      return _buildBoardCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultLabel = kitchenTicketActionLabel(ticket.status);
    final resolvedLabel = actionLabel ?? defaultLabel;
    final showAction = onAction != null && resolvedLabel != null;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        side: BorderSide(
          color: scheme.outlineVariant,
          width: KkfcBorderWidth.thin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitchenTicketHeader(
            ticketNumber: ticket.ticketNumber,
            elapsed: ticket.elapsed,
            age: ticket.age,
          ),
          Padding(
            padding: const EdgeInsets.all(KkfcSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitchenTicketChannelLine(
                  channel: ticket.channel,
                  reference: ticket.reference,
                ),
                const SizedBox(height: KkfcSpace.s8),
                KitchenTicketStatusRow(status: ticket.status),
                const SizedBox(height: KkfcSpace.s8),
                KitchenTicketBrandRow(brand: ticket.brand),
                const SizedBox(height: KkfcSpace.s16),
                for (var i = 0; i < ticket.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: KkfcSpace.s16),
                  KitchenTicketItemTile(item: ticket.items[i]),
                ],
                if (showAction) ...[
                  const SizedBox(height: KkfcSpace.s16),
                  AnimatedSwitcher(
                    duration: KkfcMotion.base,
                    child: KkfcLoadingButton(
                      key: ValueKey(ticket.status),
                      label: resolvedLabel,
                      loadingLabel: 'Signing in…',
                      isLoading: isActionLoading,
                      onPressed: onAction,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isLate = ticket.age == KitchenTicketAge.late;
    final resolvedActionLabel =
        actionLabel ?? kitchenTicketActionLabel(ticket.status);

    final (statusBg, statusFg, statusText) = switch (ticket.status) {
      KkfcStatus.queued => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
        'QUEUED',
      ),
      KkfcStatus.acknowledged => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
        'ACKNOWLEDGED',
      ),
      KkfcStatus.preparing => (
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
        'PREPARING',
      ),
      KkfcStatus.checking => (
        const Color(0xFFEDE9FE),
        const Color(0xFF7C3AED),
        'CHECKING',
      ),
      KkfcStatus.reworking => (
        const Color(0xFFEDE9FE),
        const Color(0xFF7C3AED),
        'REWORKING',
      ),
      KkfcStatus.ready => (
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        'READY',
      ),
      _ => (
        const Color(0xFFF1F5F9),
        const Color(0xFF64748B),
        ticket.status.name.toUpperCase(),
      ),
    };

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                ticket.ticketNumber,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isLate
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  KitchenTicketHeader.formatElapsed(ticket.elapsed),
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isLate
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF334155),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            ticket.brand.name,
            style: text.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${ticket.channel} · ${ticket.reference}',
            style: text.bodySmall?.copyWith(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < ticket.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ticket.items[i].quantity} × ${ticket.items[i].name}',
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (ticket.items[i].modifiers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ticket.items[i].modifiers.join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusFg,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (resolvedActionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: isActionEnabled ? (onAction ?? () {}) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: isActionEnabled
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF8E9CAE),
                  disabledBackgroundColor: const Color(0xFF8E9CAE),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(resolvedActionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
