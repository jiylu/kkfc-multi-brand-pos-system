import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

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
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(KkfcSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            for (final f in fields) ...[
              SizedBox(height: KkfcSpace.lg),
              Text(
                f.label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: KkfcSpace.xs),
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