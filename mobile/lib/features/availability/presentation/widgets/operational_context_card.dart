import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class ContextField {
  const ContextField(this.label, this.value, {this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;
}

class OperationalContextCard extends StatelessWidget {
  const OperationalContextCard({
    super.key,
    required this.title,
    required this.fields,
  });

  final String title;
  final List<ContextField> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MenuRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: MenuBorder.thin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(MenuSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            for (final f in fields) ...[
              SizedBox(height: MenuSpace.lg),
              Text(
                f.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: MenuSpace.xs),
              Text(
                f.value,
                style: f.emphasized
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
