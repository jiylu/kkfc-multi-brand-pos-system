import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(MenuRadius.sm),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MenuSpace.md,
            vertical: MenuSpace.sm,
          ),
          child: Center(
            widthFactor: 1,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MenuRadius.md),
        border: Border.all(
          color: scheme.outlineVariant,
          width: MenuBorder.thin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(MenuSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  SizedBox(height: MenuSpace.xs),
                  AnimatedSwitcher(
                    duration: context.motion(MenuMotion.medium),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      subtitle,
                      key: ValueKey(subtitle),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: MenuSpace.md),
            trailing,
          ],
        ),
      ),
    );
  }
}
