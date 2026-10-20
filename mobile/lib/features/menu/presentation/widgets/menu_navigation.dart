import 'package:flutter/material.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';

const _destinations = [
  (icon: Icons.add_shopping_cart_outlined, selected: Icons.add_shopping_cart, label: 'New order'),
  (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: 'Orders'),
  (icon: Icons.restaurant_menu_outlined, selected: Icons.restaurant_menu, label: 'Menu'),
  (icon: Icons.history_outlined, selected: Icons.history, label: 'Audit'),
];

class MenuRail extends StatelessWidget {
  const MenuRail({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelMedium!;
    final onDark = scheme.onInverseSurface;

    return NavigationRail(
      backgroundColor: scheme.inverseSurface,
      indicatorColor: onDark,
      selectedIndex: 0,
      labelType: NavigationRailLabelType.all,
      // Pushes the whole destination group down. The pill moves with the
      // icons because nothing is translated or padded inside the icons.
      leading: const SizedBox(height: MenuSpace.xxl),
      // TODO: route between tabs once Orders / Audit screens exist.
      onDestinationSelected: (_) {},
      selectedIconTheme: IconThemeData(color: scheme.inverseSurface),
      unselectedIconTheme: IconThemeData(color: onDark.withValues(alpha: 0.7)),
      selectedLabelTextStyle: label.copyWith(color: onDark),
      unselectedLabelTextStyle:
          label.copyWith(color: onDark.withValues(alpha: 0.7)),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selected),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class MenuBottomNav extends StatelessWidget {
  const MenuBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelMedium!;
    final onDark = scheme.onInverseSurface;

    return NavigationBar(
      backgroundColor: scheme.inverseSurface,
      indicatorColor: onDark.withValues(alpha: 0.12),
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon, color: onDark.withValues(alpha: 0.7)),
            selectedIcon: Icon(d.selected, color: onDark),
            label: d.label,
            tooltip: d.label,
          ),
      ],
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return label.copyWith(
          color: selected ? onDark : onDark.withValues(alpha: 0.7),
        );
      }),
    );
  }
}