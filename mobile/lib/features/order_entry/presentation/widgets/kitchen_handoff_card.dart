import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import '../../data/models/order_confirmed_view_data.dart';
import 'order_entry_shadows.dart';

class KitchenHandoffCard extends StatelessWidget {
  const KitchenHandoffCard({
    super.key,
    required this.data,
    required this.compact,
  });

  final OrderConfirmedViewData data;
  final bool compact; // phone copy and a flatter shadow

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final heading = text.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

    // No maxLines or ellipsis: ticket numbers must never truncate.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KkfcSpace.s32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: compact
            ? OrderEntryShadows.card(context)
            : OrderEntryShadows.raised(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            compact ? data.compactEyebrow : data.eyebrow,
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: KkfcSpace.s8),
          Text(
            compact
                ? data.ticketNumber
                : '${data.ticketNumber}  ·  ${data.sentLabel}',
            style: heading,
          ),
          const SizedBox(height: KkfcSpace.s8),
          Text(
            data.chips.join('  ·  ').toUpperCase(),
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: KkfcSpace.s8),
          Text(
            compact ? data.compactDescription : data.description,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}