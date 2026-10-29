import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Muted info card explaining what the state means for the user.
class WhatHappensNextCard extends StatelessWidget {
  const WhatHappensNextCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.kitchenCardMuted,
        borderRadius: BorderRadius.circular(KitchenRadius.md),
        border: Border.all(
            color: context.kitchenOutline, width: KitchenMetrics.borderWidth),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(KitchenSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT HAPPENS NEXT',
                  style: text.labelSmall?.copyWith(
                      color: context.semanticColors.info.fg,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: KitchenSpace.sm),
              Text(message,
                  style: text.bodySmall?.copyWith(color: context.kitchenText)),
            ],
          ),
        ),
      ),
    );
  }
}