import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/tokens.dart';

import 'order_entry_shadows.dart';

class OrderContextCard extends StatelessWidget {
  const OrderContextCard({
    super.key,
    required this.brand,
    required this.channelLine,
    required this.orderStatus,
    required this.paymentStatus,
    required this.note,
    this.orderTone,
    this.paymentTone,
  });

  final String brand; // Aurelia's Inasal
  final String channelLine; // Dine-in · Table 3
  final String orderStatus; // Draft
  final String paymentStatus; // Unpaid
  final String note;
  final KkfcTone? orderTone;
  final KkfcTone? paymentTone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
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
          Text(
            'ORDER CONTEXT',
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: KkfcSpace.s8),
          Text(
            brand,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: KkfcSpace.s8),
          Text(
            channelLine,
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: KkfcSpace.s16),
          _StatusPill(
            label: 'Order',
            value: orderStatus,
            tone: orderTone ?? context.semanticColors.info,
          ),
          const SizedBox(height: KkfcSpace.s8),
          _StatusPill(
            label: 'Payment',
            value: paymentStatus,
            tone: paymentTone ?? context.semanticColors.warning,
          ),
          const SizedBox(height: KkfcSpace.s16),
          Text(
            note,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final KkfcTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // minHeight, not a fixed height, so large text scale never clips.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(KkfcRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KkfcSpace.s16,
            vertical: KkfcSpace.s8,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: label.toUpperCase()),
                  const TextSpan(text: ' '),
                  TextSpan(text: value.toUpperCase()),
                ],
              ),
              style: text.labelLarge?.copyWith(
                color: tone.fg,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
