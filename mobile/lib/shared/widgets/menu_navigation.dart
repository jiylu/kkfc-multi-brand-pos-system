import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/menu_layout.dart';

typedef _Destination = ({IconData icon, IconData selected, String label});

const List<_Destination> _destinations = [
  (
    icon: Icons.add_shopping_cart_outlined,
    selected: Icons.add_shopping_cart,
    label: 'New order',
  ),
  (
    icon: Icons.receipt_long_outlined,
    selected: Icons.receipt_long,
    label: 'Orders',
  ),
  (
    icon: Icons.restaurant_menu_outlined,
    selected: Icons.restaurant_menu,
    label: 'Menu',
  ),
  (icon: Icons.history_outlined, selected: Icons.history, label: 'Audit'),
];

class MenuRail extends StatelessWidget {
  const MenuRail({super.key, this.selectedIndex = 0, this.onSelected});

  final int selectedIndex;
  // TODO: route between tabs once Orders / Audit screens exist.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.inverseSurface,
      child: SizedBox(
        width: MenuLayout.railWidth,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: MenuSpace.sm),
              for (var i = 0; i < _destinations.length; i++)
                _NavItem(
                  destination: _destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected?.call(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuBottomNav extends StatelessWidget {
  const MenuBottomNav({super.key, this.selectedIndex = 0, this.onSelected});

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.inverseSurface,
      child: SafeArea(
        top: false,
        child: Row(
          // No stretch: the bar sits in a Column, which hands its
          // non-flexible children an unbounded height.
          children: [
            for (var i = 0; i < _destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: _destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected?.call(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onDark = scheme.onInverseSurface;
    final labelStyle = Theme.of(context).textTheme.labelMedium!;

    // Edit these three lines to change the look.
    final highlight = selected ? onDark : Colors.transparent;
    final fg = selected ? scheme.inverseSurface : onDark.withValues(alpha: 0.7);
    // For rounded corners, add borderRadius to a BoxDecoration instead of `color:`.

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: AnimatedContainer(
        duration: context.motion(MenuMotion.fast),
        curve: MenuMotion.curve,
        color: highlight, // square, no radius
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              final pressed = states.contains(WidgetState.pressed);
              final active =
                  pressed ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused);
              if (!active) return null;

              final base = selected ? scheme.inverseSurface : onDark;
              return base.withValues(
                alpha: pressed ? KkfcOpacity.pressed : KkfcOpacity.hover,
              );
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MenuSpace.sm,
                  horizontal: MenuSpace.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: fg),
                      duration: context.motion(MenuMotion.fast),
                      builder: (context, color, _) => Icon(
                        selected ? destination.selected : destination.icon,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: MenuSpace.xs),
                    AnimatedDefaultTextStyle(
                      duration: context.motion(MenuMotion.fast),
                      style: labelStyle.copyWith(color: fg),
                      textAlign: TextAlign.center,
                      child: Text(
                        destination.label,
                        textAlign: TextAlign.center,
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
