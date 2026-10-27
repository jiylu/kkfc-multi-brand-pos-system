import 'package:flutter/material.dart';

class OrderEntryHeader extends StatelessWidget {
  const OrderEntryHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: text.headlineSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}