import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_dialog.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

/// Returns the brand the user continued with, or null if dismissed.
Future<AssignedBrand?> showBrandPicker(
  BuildContext context, {
  required List<AssignedBrand> brands,
  required AssignedBrand current,
}) {
  return showMenuDialog<AssignedBrand>(
    context,
    builder: (_) => _BrandPickerContent(brands: brands, current: current),
  );
}

class _BrandPickerContent extends StatefulWidget {
  const _BrandPickerContent({required this.brands, required this.current});

  final List<AssignedBrand> brands;
  final AssignedBrand current;

  @override
  State<_BrandPickerContent> createState() => _BrandPickerContentState();
}

class _BrandPickerContentState extends State<_BrandPickerContent> {
  late AssignedBrand _selected = widget.current;

  String _subtitle(AssignedBrand brand) {
    final isCurrent = brand.id == widget.current.id;
    final isSelected = brand.id == _selected.id;
    if (isCurrent) {
      return isSelected ? 'Current brand · Selected' : 'Current brand';
    }
    return 'Available to this demo account';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final codes = widget.brands.map((b) => b.code).join('/');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose assigned brand',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: MenuSpace.xs),
        Text(
          'DEMO ACCOUNT · ${widget.brands.length} ASSIGNED BRANDS',
          style: text.labelSmall?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: MenuSpace.md),
        for (final brand in widget.brands)
          Padding(
            padding: const EdgeInsets.only(bottom: MenuSpace.sm),
            child: _BrandTile(
              brand: brand,
              subtitle: _subtitle(brand),
              selected: brand.id == _selected.id,
              onTap: () => setState(() => _selected = brand),
            ),
          ),
        const SizedBox(height: MenuSpace.xs),
        Text(
          'Production only shows assigned brands. $codes access is '
          'illustrative, not a universal staff permission.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: MenuSpace.lg),
        KkfcLoadingButton(
          label: 'Continue with selected brand',
          loadingLabel: 'Loading…',
          isLoading: false, // TODO: wire to the real sending state once the backend exists.
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    required this.brand,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final AssignedBrand brand;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '${brand.name}, $subtitle',
      child: AnimatedContainer(
        duration: context.motion(MenuMotion.medium),
        curve: MenuMotion.curve,
        decoration: BoxDecoration(
          color: selected
              ? context.semanticColors.highlightsSecondary
              : scheme.surface,
          borderRadius: BorderRadius.circular(MenuRadius.md),
          border: Border.all(
            color: selected
                ? context.semanticColors.highlights
                : scheme.outlineVariant,
            width: selected ? MenuBorder.thick : MenuBorder.thin,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(MenuRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MenuSpace.md,
                  vertical: MenuSpace.sm,
                ),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: BrandLogo(brand: brand, height: 32),
                    ),
                    const SizedBox(width: MenuSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand.name,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: context.motion(MenuMotion.fast),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        key: ValueKey(selected),
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
