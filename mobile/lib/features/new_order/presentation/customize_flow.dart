import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/customize_item_panel.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/shared_layout.dart';

Future<void> openCustomize(
  BuildContext context,
  WidgetRef ref, {
  required MenuItem item,
  CartLine? editing,
}) async {
  final channel = ref.read(menuChannelProvider);
  final lines = ref.read(cartProvider);
  final itemNumber = editing == null
      ? lines.length + 1
      : lines.indexWhere((l) => l.id == editing.id) + 1;

  final result = await _present(
    context,
    CustomizeItemPanel(
      item: item,
      channel: channel,
      brandCode: ref.read(activeBrandProvider).code,
      itemNumber: itemNumber,
      editing: editing,
    ),
  );
  if (result == null) return;

  final cart = ref.read(cartProvider.notifier);
  if (editing == null) {
    cart.addConfigured(item, result.selections, result.quantity);
  } else {
    cart.updateLine(editing.id, result.selections, result.quantity);
  }
}

Future<CustomizeResult?> _present(BuildContext context, Widget panel) {
  final isWide = MediaQuery.sizeOf(context).width >= MenuLayout.compactMax;
  final scheme = Theme.of(context).colorScheme;

  if (!isWide) {
    return showModalBottomSheet<CustomizeResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.95, child: panel),
    );
  }

  return showGeneralDialog<CustomizeResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scheme.scrim.withValues(alpha: 0.5),
    transitionDuration: context.motion(MenuMotion.medium),
    pageBuilder: (context, _, __) => Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 440,
        height: double.infinity,
        child: Material(
          color: scheme.surface,
          elevation: 8,
          child: SafeArea(child: panel),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: animation,
        curve: MenuMotion.curve,
        reverseCurve: Curves.easeIn,
      )),
      child: child,
    ),
  );
}