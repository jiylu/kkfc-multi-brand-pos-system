import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/menu/data/models/menu_models.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

class MenuItemCard extends ConsumerStatefulWidget {
  const MenuItemCard({super.key, required this.item, required this.channel});

  final MenuItem item;
  final MenuChannel channel;

  @override
  ConsumerState<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends ConsumerState<MenuItemCard> {
  bool _pressed = false;

  ({String title, String detail})? _note(MenuAvailability a) => switch (a) {
    MenuAvailability.available => null,
    MenuAvailability.stockout => (
      title: 'Out of stock',
      detail: 'Shared inventory',
    ),
    MenuAvailability.manualOff => (
      title: 'Manual unavailable',
      detail: 'On ${widget.channel.label}',
    ),
    MenuAvailability.inactive => (
      title: 'Inactive item',
      detail: 'Not on sale',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final availability = item.availabilityFor(widget.channel);
    final orderable = availability == MenuAvailability.available;
    final note = _note(availability);
    final price = formatPeso(item.priceFor(widget.channel));

    final qty = ref.watch(
      cartProvider.select(
        (lines) => lines
            .where((l) => l.item.id == item.id)
            .fold(0, (sum, l) => sum + l.quantity),
      ),
    );
    final selected = qty > 0;

    return Semantics(
      button: true,
      enabled: orderable,
      selected: selected,
      label: '${item.name}, $price',
      child: AnimatedScale(
        scale: _pressed && orderable ? 0.97 : 1,
        duration: context.motion(MenuMotion.fast),
        curve: MenuMotion.curve,
        child: AnimatedContainer(
          duration: context.motion(MenuMotion.medium),
          curve: MenuMotion.curve,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(MenuRadius.md),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? MenuBorder.thick : MenuBorder.thin,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(MenuRadius.md),
              onTap: orderable
                  ? () => ref.read(cartProvider.notifier).add(item)
                  : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Opacity(
                opacity: orderable ? 1 : MenuLayout.disabledOpacity,
                child: Padding(
                  padding: const EdgeInsets.all(MenuSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  MenuRadius.sm,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.restaurant,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          if (!orderable)
                            Positioned(
                              left: MenuSpace.sm,
                              top: MenuSpace.sm,
                              child: _AvailabilityBadge(availability),
                            ),
                          Positioned(
                            right: MenuSpace.sm,
                            top: MenuSpace.sm,
                            child: AnimatedSwitcher(
                              duration: context.motion(MenuMotion.fast),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: qty > 0
                                  ? _QtyBadge(
                                      key: ValueKey(qty),
                                      qty: qty,
                                      selected: selected,
                                    )
                                  : const SizedBox.shrink(key: ValueKey(0)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MenuSpace.sm),
                      AnimatedDefaultTextStyle(
                        duration: context.motion(MenuMotion.fast),
                        curve: MenuMotion.curve,
                        style: (text.titleSmall ?? const TextStyle()).copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected ? scheme.onPrimary : scheme.onSurface,
                        ),
                        child: Text(item.name),
                      ),
                      const SizedBox(height: MenuSpace.xs),
                      if (note == null)
                        AnimatedDefaultTextStyle(
                          duration: context.motion(MenuMotion.fast),
                          curve: MenuMotion.curve,
                          style: (text.bodySmall ?? const TextStyle()).copyWith(
                            color: selected
                                ? scheme.onPrimary.withValues(
                                    alpha: KkfcOpacity.soft,
                                  )
                                : scheme.onSurfaceVariant,
                          ),
                          child: Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else ...[
                        AnimatedDefaultTextStyle(
                          duration: context.motion(MenuMotion.fast),
                          curve: MenuMotion.curve,
                          style: (text.bodySmall ?? const TextStyle()).copyWith(
                            color: selected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                          child: Text(note.title),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: context.motion(MenuMotion.fast),
                          curve: MenuMotion.curve,
                          style: (text.bodySmall ?? const TextStyle()).copyWith(
                            color: selected
                                ? scheme.onPrimary.withValues(
                                    alpha: KkfcOpacity.soft,
                                  )
                                : scheme.onSurfaceVariant,
                          ),
                          child: Text(note.detail),
                        ),
                      ],
                      const SizedBox(height: MenuSpace.sm),
                      // No maxLines/ellipsis on prices.
                      AnimatedSwitcher(
                        duration: context.motion(MenuMotion.fast),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: context.motion(MenuMotion.fast),
                          curve: MenuMotion.curve,
                          style: (text.titleMedium ?? const TextStyle())
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                              ),
                          child: Text(price, key: ValueKey(price)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({super.key, required this.qty, required this.selected});
  final int qty;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? scheme.onPrimary : scheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MenuSpace.xs),
            child: Text(
              '$qty',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? scheme.primary : scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge(this.availability);
  final MenuAvailability availability;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    // TODO: swap for context.semanticColors tones (warning / neutral).
    final (bg, fg, label) = switch (availability) {
      MenuAvailability.stockout => (
        s.errorContainer,
        s.onErrorContainer,
        'STOCKOUT',
      ),
      MenuAvailability.manualOff => (
        s.errorContainer,
        s.onErrorContainer,
        'MANUAL OFF',
      ),
      MenuAvailability.inactive => (
        s.surfaceContainerHighest,
        s.onSurfaceVariant,
        'INACTIVE',
      ),
      MenuAvailability.available => (
        s.primaryContainer,
        s.onPrimaryContainer,
        '',
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MenuSpace.sm,
          vertical: MenuSpace.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}
