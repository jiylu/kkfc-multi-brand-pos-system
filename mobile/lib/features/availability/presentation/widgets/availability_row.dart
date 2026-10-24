import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

import 'motion.dart';

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
          borderRadius: BorderRadius.circular(KkfcRadius.sm),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: KkfcSpace.md,
            vertical: KkfcSpace.sm,
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
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: scheme.outlineVariant,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(KkfcSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  SizedBox(height: KkfcSpace.xs),
                  AnimatedSwitcher(
                    duration: motionOf(context, KkfcMotion.normal),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, if (current != null) current],
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
            SizedBox(width: KkfcSpace.md),
            trailing,
          ],
        ),
      ),
    );
  }
}