import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';

import 'order_entry_shadows.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.data});

  final OrderEntryViewData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(KkfcSpace.s32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: OrderEntryShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.summaryTitle, style: text.titleMedium),
          const SizedBox(height: KkfcSpace.s16),
          for (final row in data.rows) ...[
            _Row(label: row.label, value: row.value),
            const SizedBox(height: KkfcSpace.s8),
            if (row.label == 'Items' && data.items.isNotEmpty) ...[
              for (final item in data.items) ...[
                _ItemRow(item: item),
                const SizedBox(height: KkfcSpace.s8),
              ],
            ],
          ],
          Divider(height: KkfcSpace.s32 * 2, color: scheme.outlineVariant),
          _Row(label: data.totalLabel, value: data.total, emphasized: true),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderEntryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: KkfcSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} × ${item.name}',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: KkfcSpace.s16),
              Flexible(
                child: Text(
                  item.total,
                  textAlign: TextAlign.end,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (item.modifiers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: KkfcSpace.s4),
              child: Text(
                item.modifiers.join(' · '),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // No maxLines/ellipsis: prices must never truncate.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: KkfcSpace.s16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: emphasized ? text.titleLarge : text.bodyMedium,
          ),
        ),
      ],
    );
  }
}
