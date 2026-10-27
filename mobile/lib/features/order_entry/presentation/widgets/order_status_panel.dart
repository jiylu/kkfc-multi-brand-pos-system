import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';
import 'order_entry_shadows.dart';

class OrderStatusPanel extends StatelessWidget {
  const OrderStatusPanel({super.key, required this.data});

  final OrderEntryViewData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tone = context.semanticColors.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KkfcSpace.s32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: OrderEntryShadows.card(context),
      ),
      child: AnimatedSwitcher(
        duration: KkfcMotion.fast,
        switchInCurve: Curves.easeOutCubic,
        child: Column(
          key: ValueKey(data.statusBadge),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.statusTitle,
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: KkfcSpace.s8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(KkfcRadius.sm),
                border: tone.border == null
                    ? null
                    : Border.all(color: tone.border!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KkfcSpace.s8,
                  vertical: 4,
                ),
                child: Text(
                  data.statusBadge,
                  style: text.labelMedium?.copyWith(color: tone.fg),
                ),
              ),
            ),
            const SizedBox(height: KkfcSpace.s16),
            Text(data.statusMessage, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}