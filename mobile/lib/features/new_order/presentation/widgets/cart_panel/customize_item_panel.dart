import 'package:flutter/material.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/animated_peso.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

class CustomizeResult {
  const CustomizeResult({required this.selections, required this.quantity});
  final Map<String, String> selections;
  final int quantity;
}

class CustomizeItemPanel extends StatefulWidget {
  const CustomizeItemPanel({
    super.key,
    required this.item,
    required this.channel,
    required this.brandCode,
    required this.itemNumber,
    this.editing,
  });

  final MenuItem item;
  final MenuChannel channel;
  final String brandCode; // e.g. AI
  final int itemNumber;
  final CartLine? editing;

  @override
  State<CustomizeItemPanel> createState() => _CustomizeItemPanelState();
}

class _CustomizeItemPanelState extends State<CustomizeItemPanel> {
  late final Map<String, String> _selections = {
    for (final g in widget.item.modifierGroups)
      g.id: widget.editing?.selections[g.id] ?? g.defaultOptionId,
  };
  late int _quantity = widget.editing?.quantity ?? 1;

  static const _maxQuantity = 99;

  List<Widget> _addOnSection(MenuItem item) {
    final addOns = item.modifierGroups.where((g) => g.isAddOn).toList();
    if (addOns.isEmpty) return const [];
    return [
      const SizedBox(height: MenuSpace.md),
      _AddOnsCard(
        addOns: addOns,
        selections: _selections,
        onChanged: (group, on) => setState(
          () => _selections[group.id] = on
              ? ModifierGroup.addOnOn
              : ModifierGroup.addOnOff,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final item = widget.item;
    final isEditing = widget.editing != null;
    final base = item.priceFor(widget.channel);
    final unit = base + modifiersCentavosFor(item, _selections);
    final total = unit * _quantity;
    final eyebrow =
        '${isEditing ? 'EDIT ORDER' : 'NEW ORDER'} / '
        'ITEM ${widget.itemNumber.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MenuSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eyebrow,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  'Customize item',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MenuSpace.lg),
                _ItemSummary(
                  brandCode: widget.brandCode,
                  name: item.name,
                  basePrice: base,
                ),
                ..._addOnSection(item),
                for (final group in item.modifierGroups.where(
                  (g) => !g.isAddOn,
                )) ...[
                  const SizedBox(height: MenuSpace.md),
                  _ModifierGroupCard(
                    group: group,
                    selectedId: _selections[group.id]!,
                    onSelected: (id) =>
                        setState(() => _selections[group.id] = id),
                  ),
                ],
                const SizedBox(height: MenuSpace.lg),
                _QuantityRow(
                  quantity: _quantity,
                  onDecrement: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  onIncrement: _quantity < _maxQuantity
                      ? () => setState(() => _quantity++)
                      : null,
                ),
                const SizedBox(height: MenuSpace.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(MenuRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(MenuSpace.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'LINE TOTAL',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        AnimatedPeso(
                          centavos: total,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MenuSpace.md),
                Text(
                  'Add-ons and prices are loaded from the server.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(MenuSpace.lg),
          child: SizedBox(
            width: double.infinity,
            child: KkfcLoadingButton(
              label: isEditing ? 'Update order' : 'Add to order',
              loadingLabel: 'Saving…',
              isLoading: false,
              onPressed: () => Navigator.of(context).pop(
                CustomizeResult(
                  selections: Map.of(_selections),
                  quantity: _quantity,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({
    required this.brandCode,
    required this.name,
    required this.basePrice,
  });

  final String brandCode;
  final String name;
  final int basePrice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(MenuRadius.md),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(MenuSpace.sm),
                child: Text(
                  brandCode,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: MenuSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Base price ${formatPeso(basePrice)} · Sample',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddOnsCard extends StatelessWidget {
  const _AddOnsCard({
    required this.addOns,
    required this.selections,
    required this.onChanged,
  });

  final List<ModifierGroup> addOns;
  final Map<String, String> selections;
  final void Function(ModifierGroup group, bool on) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(MenuRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MenuSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADD-ONS',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: MenuSpace.xs),
            for (final group in addOns)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                value: selections[group.id] == ModifierGroup.addOnOn,
                onChanged: (v) => onChanged(group, v ?? false),
                title: Text(
                  '${group.title} · ${formatPesoDelta(group.options.last.priceDeltaCentavos)}',
                  style: text.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModifierGroupCard extends StatelessWidget {
  const _ModifierGroupCard({
    required this.group,
    required this.selectedId,
    required this.onSelected,
  });

  final ModifierGroup group;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(MenuRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MenuSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title.toUpperCase(),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: MenuSpace.xs),
            for (final option in group.options)
              _OptionRow(
                option: option,
                selected: option.id == selectedId,
                onTap: () => onSelected(option.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ModifierOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final price = option.priceDeltaCentavos == 0
        ? 'included'
        : formatPesoDelta(option.priceDeltaCentavos);

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(MenuRadius.sm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${option.label} · $price',
                  style: text.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
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
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'QUANTITY',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Remove one',
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: MenuSpace.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(MenuRadius.sm),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: context.motion(MenuMotion.fast),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: text.titleMedium,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: MenuSpace.sm),
        IconButton.outlined(
          tooltip: 'Add one',
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
