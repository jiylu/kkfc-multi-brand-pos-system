import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_action.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_meta.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

export 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    this.onAction,
    this.isActionLoading = false,
  });

  final KitchenTicketData ticket;

  /// Null hides the button (e.g. read-only boards).
  final VoidCallback? onAction;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionLabel = kitchenTicketActionLabel(ticket.status);
    final showAction = onAction != null && actionLabel != null;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        side: BorderSide(color: scheme.outlineVariant, width: KkfcBorderWidth.thin),
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
                KitchenTicketBrandRow(
                  brand: ticket.brand,
                  brandName: ticket.brandName,
                ),
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
                      label: actionLabel,
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
}