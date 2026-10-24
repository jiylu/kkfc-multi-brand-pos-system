import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/shared/shared_layout.dart';

class RepricingNotice extends StatelessWidget {
  const RepricingNotice({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MenuSpace.lg),
      decoration: BoxDecoration(
        color: semantic.info.bg,
        borderRadius: BorderRadius.circular(MenuRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleSmall?.copyWith(
              color: semantic.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MenuSpace.sm),
          Text(
            body,
            style: text.bodyMedium?.copyWith(color: semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}
