import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';
import 'package:mobile/shared/widgets/kkfc_brand_tag.dart';
import 'package:mobile/shared/widgets/kkfc_text_field.dart';

class CartPanelHeader extends StatelessWidget {
  const CartPanelHeader({
    super.key,
    required this.brand,
    required this.channel,
    required this.referenceController,
    required this.canClear,
    required this.onClear,
    this.referenceHelperText,
    this.referenceErrorText,
    this.referenceDisabledText,
    this.referenceEnabled = true,
    this.onReferenceChanged,
  });

  final AssignedBrand brand;
  final MenuChannel channel;
  final TextEditingController referenceController;
  final bool canClear;
  final VoidCallback onClear;

  /// e.g. "Enter the order reference".
  final String? referenceHelperText;

  /// Non-null shows the error look, e.g. "Enter the GrabFood order number".
  final String? referenceErrorText;

  /// Shown inside the field when disabled, e.g. "Not used for GrabFood".
  final String? referenceDisabledText;

  final bool referenceEnabled;
  final ValueChanged<String>? onReferenceChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KkfcSpace.s16,
            KkfcSpace.s16,
            KkfcSpace.s8,
            KkfcSpace.s8,
          ),
          child: Row(
            children: [
              Expanded(
                // TODO: use a heading style from KkfcTypography instead of
                // overriding the weight here.
                child: Text('New order', style: text.titleLarge),
              ),
              TextButton(
                onPressed: canClear ? onClear : null,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KkfcSpace.s16,
            vertical: KkfcSpace.s12,
          ),
          child: Align(
            alignment: Alignment.center,
            child: KkfcBrandTag(
              label: brand.name,
              logoAsset: BrandLogo.assetFor(brand.code),
              compact: true,
            ),
          ),
        ),
        if (channel.isPlatform)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KkfcSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ReferenceBlock(
                  label: 'Store reference',
                  value: 'From brand and channel setup',
                ),
                const SizedBox(height: KkfcSpace.s12),
                _ReferenceBlock(
                  label: 'External order reference',
                  value: 'Enter reference from ${channel.label}',
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KkfcSpace.s16),
            child: KkfcTextField(
              label: channel.referenceLabel,
              controller: referenceController,
              helperText: referenceHelperText,
              errorText: referenceErrorText,
              disabledText: referenceDisabledText,
              enabled: referenceEnabled,
              onChanged: onReferenceChanged,
              textAlign: TextAlign.center,
              valueStyle: KkfcTypography.bodyLg,
            ),
          ),
        const SizedBox(height: KkfcSpace.s8),
      ],
    );
  }
}

class _ReferenceBlock extends StatelessWidget {
  const _ReferenceBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: KkfcSpace.s4),
        Text(
          value,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
