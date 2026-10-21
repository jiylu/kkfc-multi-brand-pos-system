import 'package:flutter/material.dart';
import 'package:mobile/features/new_order/presentation/menu_layout.dart';

/// A rounded, bordered card with a primary label, an optional secondary
/// line, and an optional trailing widget. Set [emphasiseSubtitle] when the
/// secondary line is the value (for example, the selected channel name).
class RepricingRow extends StatelessWidget {
  const RepricingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.emphasiseSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool emphasiseSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final titleStyle = emphasiseSubtitle
        ? text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)
        : text.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle = emphasiseSubtitle
        ? text.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MenuSpace.lg,
        vertical: MenuSpace.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(MenuRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: MenuSpace.xs),
                  Text(subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: MenuSpace.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
