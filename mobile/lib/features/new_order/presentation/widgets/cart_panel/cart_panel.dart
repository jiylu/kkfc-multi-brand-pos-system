import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_line_tile.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel_footer.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel_header.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';

class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  late final TextEditingController _referenceController;

  @override
  void initState() {
    super.initState();
    _referenceController = TextEditingController(
      text: ref.read(orderReferenceProvider),
    );
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(orderReferenceProvider, (_, reference) {
      if (_referenceController.text != reference) {
        _referenceController.text = reference;
      }
    });

    final lines = ref.watch(cartProvider);
    final channel = ref.watch(menuChannelProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
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
              referenceController: _referenceController,
              onReferenceChanged: ref.read(orderReferenceProvider.notifier).set,
              // TODO: set referenceHelperText, referenceErrorText,
              // referenceEnabled and referenceDisabledText from the channel
              // rules (e.g. "Not used for GrabFood") once they exist.
              canClear: lines.isNotEmpty,
              onClear: () => ref.read(cartProvider.notifier).clear(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : KkfcMotion.base,
                child: lines.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Padding(
                          padding: const EdgeInsets.all(KkfcSpace.s24),
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
                          horizontal: KkfcSpace.s16,
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
              onSend: () => context.push(
                AppRoutes.orderEntry,
                extra: OrderEntryViewData.checkBeforeSending.withOrderDetails(
                  brandName: ref.read(activeBrandProvider).name,
                  channel: channel.label,
                  reference: _referenceController.text,
                  itemCount: count,
                  items: [
                    for (final line in lines)
                      OrderEntryItem(
                        name: line.item.name,
                        quantity: line.quantity,
                        total: formatPeso(line.totalCentavos(channel)),
                        modifiers: line.modifierSummary,
                      ),
                  ],
                  total: formatPeso(total),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
