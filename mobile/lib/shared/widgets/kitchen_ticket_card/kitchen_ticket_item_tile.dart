import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

class KitchenTicketItemTile extends StatelessWidget {
  const KitchenTicketItemTile({super.key, required this.item});

  final KitchenTicketItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 20),
          child: Text(
            '${item.quantity}',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: KkfcSpace.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              for (final mod in item.modifiers)
                Padding(
                  padding: const EdgeInsets.only(top: KkfcSpace.s4),
                  child: Text(
                    mod,
                    style: text.bodyMedium?.copyWith(color: muted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}