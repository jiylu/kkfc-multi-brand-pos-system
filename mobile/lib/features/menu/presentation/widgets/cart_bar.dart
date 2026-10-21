import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/animated_peso.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

void showCartSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const FractionallySizedBox(heightFactor: 0.9, child: CartPanel()),
    ),
  );
}

class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: context.motion(MenuMotion.medium),
      curve: MenuMotion.curve,
      alignment: Alignment.bottomCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : Material(
              color: scheme.surface,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(MenuSpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count items in order',
                            style: text.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          AnimatedPeso(
                            centavos: total,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () => showCartSheet(context),
                      child: const Text('View cart'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
