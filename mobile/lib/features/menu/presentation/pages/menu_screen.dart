import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mobile/features/menu/data/models/menu_models.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_bar.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/menu/presentation/widgets/fade_slide_in.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_header.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_navigation.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_states.dart';
import 'package:mobile/features/menu/presentation/widgets/responsive_card_grid.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Confirm KkfcScaffold's real constructor; I assumed a `body:` parameter.
    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showRail = width >= MenuLayout.compactMax;
          final showCartPanel = width >= MenuLayout.wideMin;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRail) const MenuRail(),
              Expanded(
                child: Column(
                  children: [
                    MenuHeader(compact: !showRail),
                    const Expanded(child: _MenuBody()),
                    if (!showCartPanel) const CartBar(),
                    if (!showRail) const MenuBottomNav(),
                  ],
                ),
              ),
              if (showCartPanel) ...[
                const VerticalDivider(width: 1),
                const SizedBox(
                  width: MenuLayout.cartPanelWidth,
                  child: CartPanel(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MenuBody extends ConsumerStatefulWidget {
  const _MenuBody();

  @override
  ConsumerState<_MenuBody> createState() => _MenuBodyState();
}

class _MenuBodyState extends ConsumerState<_MenuBody> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(menuSearchProvider, (_, query) {
      if (_search.text != query) _search.text = query;
    });

    final channel = ref.watch(menuChannelProvider);
    final query = ref.watch(menuSearchProvider);
    final visible = ref.watch(visibleMenuItemsProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final Widget body = visible.when(
      loading: () => const MenuGridSkeleton(key: ValueKey('loading')),
      error: (_, _) => MenuMessageCard(
        key: const ValueKey('error'),
        icon: Icons.wifi_off,
        title: "Couldn't load the menu",
        body: 'Check the Wi-Fi, then try again.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(menuItemsProvider),
      ),
      data: (items) => items.isEmpty
          ? MenuMessageCard(
              key: const ValueKey('empty'),
              icon: Icons.search_off,
              title: 'No items match "$query"',
              body: "This brand has no item with that name.",
              actionLabel: 'Clear search',
              onAction: () => ref.read(menuSearchProvider.notifier).clear(),
            )
          : ResponsiveCardGrid(
              key: ValueKey('grid-$query'),
              itemCount: items.length,
              itemBuilder: (context, i) => FadeSlideIn(
                index: i,
                child: MenuItemCard(item: items[i], channel: channel),
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              MenuSpace.lg, MenuSpace.lg, MenuSpace.lg, MenuSpace.sm),
          child: SearchBar(
            controller: _search,
            hintText: 'Search menu',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: ref.read(menuSearchProvider.notifier).set,
            trailing: [
              if (query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(menuSearchProvider.notifier).clear(),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MenuSpace.lg),
          child: Wrap(
            spacing: MenuSpace.md,
            runSpacing: MenuSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('All menu items',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (visible.hasValue)
                Text('${visible.requireValue.length} items',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              Text('SAMPLE PRICES · PHOTOS PENDING',
                  style: text.labelSmall?.copyWith(color: scheme.primary)),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: context.motion(MenuMotion.medium),
            switchInCurve: MenuMotion.curve,
            child: body,
          ),
        ),
      ],
    );
  }
}