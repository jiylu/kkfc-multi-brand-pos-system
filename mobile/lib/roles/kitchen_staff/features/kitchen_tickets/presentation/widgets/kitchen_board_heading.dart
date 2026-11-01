import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Page title + subtitle, with an optional trailing widget (tablet badge).
class KitchenBoardHeading extends StatelessWidget {
  const KitchenBoardHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.headlineMedium?.copyWith(
                  color: context.kitchenText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: KitchenSpace.xs),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: context.kitchenTextMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: KitchenSpace.md), trailing!],
      ],
    );
  }
}
