import 'package:flutter/material.dart';

import 'package:mobile/shared/shared_layout.dart';

/// One label/value line inside a [CancelDetailCard].
@immutable
class CancelDetailRow {
  const CancelDetailRow(
    this.label,
    this.value, {
    this.emphasized = false,
    this.danger = false,
  });

  final String label;
  final String value;

  /// Renders the value with the stronger title style.
  final bool emphasized;

  /// Renders the value in the error colour (e.g. "Not authorized").
  final bool danger;
}

/// Bordered card used by every cancel-order screen: a small uppercase section
/// label, a list of label/value rows and an optional footer (reason field or
/// sample-outcome controls).
class CancelDetailCard extends StatelessWidget {
  const CancelDetailCard({
    super.key,
    required this.label,
    required this.rows,
    this.footer,
  });

  final String label;
  final List<CancelDetailRow> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MenuSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MenuRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: MenuBorder.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          for (final row in rows) ...[
            SizedBox(height: MenuSpace.lg),
            _CancelDetailValueRow(row: row),
          ],
          if (footer != null) ...[
            SizedBox(height: MenuSpace.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _CancelDetailValueRow extends StatelessWidget {
  const _CancelDetailValueRow({required this.row});

  final CancelDetailRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    final style = row.emphasized ? text.titleSmall : text.bodyMedium;
    final color = row.danger ? scheme.error : scheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            row.label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        SizedBox(width: MenuSpace.md),
        Expanded(
          flex: 3,
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: style?.copyWith(
              color: color,
              fontWeight: row.emphasized || row.danger
                  ? FontWeight.w700
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
