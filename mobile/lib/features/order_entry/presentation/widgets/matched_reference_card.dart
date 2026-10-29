import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

import '../../data/models/duplicate_platform_order_view_data.dart';
import 'order_entry_shadows.dart';

class MatchedReferenceCard extends StatelessWidget {
  const MatchedReferenceCard({
    super.key,
    required this.data,
    required this.compact,
  });

  final DuplicatePlatformOrderViewData data;
  final bool compact;

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
        boxShadow: compact
            ? OrderEntryShadows.card(context)
            : OrderEntryShadows.raised(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.matchedEyebrow.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KkfcSpace.s24),
          _ReferenceRow(
            label: data.orderTicketLabel,
            value: data.orderTicketValue,
          ),
          const SizedBox(height: KkfcSpace.s16),
          _ReferenceRow(label: data.storeLabel, value: data.storeValue),
          const SizedBox(height: KkfcSpace.s16),
          _ReferenceRow(label: data.externalLabel, value: data.externalValue),
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

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
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
