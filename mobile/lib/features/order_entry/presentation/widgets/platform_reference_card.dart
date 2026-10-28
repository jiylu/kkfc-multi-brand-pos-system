import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kkfc_text_field.dart';
import 'package:mobile/features/order_entry/data/models/platform_reference_view_data.dart';
import 'order_entry_shadows.dart';

class PlatformReferenceCard extends StatelessWidget {
  const PlatformReferenceCard({
    super.key,
    required this.data,
  });

  final PlatformReferenceViewData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KkfcSpace.s32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: OrderEntryShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLATFORM REFERENCE',
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: KkfcSpace.s16),
          for (final field in data.fields) ...[
            _FieldRow(field: field),
            const SizedBox(height: KkfcSpace.s20),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final PlatformReferenceField field;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: field.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (field.required)
                const TextSpan(
                  text: '  ·  Required',
                  style: TextStyle(color: Color(0xFF6E7E9C), fontWeight: FontWeight.w500),
                ),
            ],
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KkfcSpace.s8),
        KkfcTextField(
          label: '',
          hint: field.hint,
          errorText: field.errorText,
          hasError: field.errorText != null,
          valueStyle: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
