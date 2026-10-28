import 'package:flutter/material.dart';

class OrderEntryHeader extends StatelessWidget {
  const OrderEntryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.tag,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? tag; // e.g. the green "✓ ORDER CONFIRMED" pill

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tag != null) ...[
          tag!,
          const SizedBox(height: 12),
        ],
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          title,
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: text.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}