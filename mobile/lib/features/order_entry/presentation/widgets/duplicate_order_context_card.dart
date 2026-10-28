import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/tokens.dart';
import '../../data/models/duplicate_platform_order_view_data.dart';
import 'order_entry_shadows.dart';

class DuplicateOrderContextCard extends StatelessWidget {
  const DuplicateOrderContextCard({
    super.key,
    required this.data,
    required this.tone,
  });

  final DuplicatePlatformOrderViewData data;
  final KkfcTone tone;

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
            data.contextEyebrow.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KkfcSpace.s12),
          Text(
            data.contextTitle,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: KkfcSpace.s12),
          Text(
            data.contextDescription,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: KkfcSpace.s20),
          _DesignReviewPill(
            text: data.reviewBadgeText,
            tone: tone,
          ),
          const SizedBox(height: KkfcSpace.s16),
          Text(
            data.brandFooter,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignReviewPill extends StatelessWidget {
  const _DesignReviewPill({
    required this.text,
    required this.tone,
  });

  final String text;
  final KkfcTone tone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
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
            child: Text(
              text.toUpperCase(),
              style: t.labelMedium?.copyWith(
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
