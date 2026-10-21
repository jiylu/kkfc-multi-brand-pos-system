import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_line_tile.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_panel_footer.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_panel_header.dart';
import 'package:mobile/features/menu/presentation/widgets/fade_slide_in.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final channel = ref.watch(menuChannelProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CartPanelHeader(
              referenceLabel: channel.referenceLabel,
              canClear: lines.isNotEmpty,
              onClear: () => ref.read(cartProvider.notifier).clear(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.motion(MenuMotion.medium),
                child: lines.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Padding(
                          padding: const EdgeInsets.all(MenuSpace.xl),
                          child: Text(
                            'No items yet. Tap a menu item to add it.',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        key: const ValueKey('lines'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MenuSpace.lg,
                        ),
                        children: [
                          for (final line in lines)
                            FadeSlideIn(
                              key: ValueKey(line.item.id),
                              child: CartLineTile(line: line, channel: channel),
                            ),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            CartPanelFooter(
              count: count,
              total: total,
              canSend: lines.isNotEmpty,
              onSend: () {},
            ),
          ],
        ),
      ),
    );
  }
}
