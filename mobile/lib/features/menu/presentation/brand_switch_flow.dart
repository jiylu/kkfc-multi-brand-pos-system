import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menu/presentation/widgets/brands/brand_picker_dialog.dart';
import 'package:mobile/features/menu/presentation/widgets/brands/brand_switch_confirm_dialog.dart';
import 'package:mobile/features/menu/providers/brand_providers.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

Future<void> startBrandSwitch(BuildContext context, WidgetRef ref) async {
  final current = ref.read(activeBrandProvider);
  final brands = ref.read(assignedBrandsProvider);

  final picked = await showBrandPicker(
    context,
    brands: brands,
    current: current,
  );
  if (picked == null || picked.id == current.id) return;
  if (!context.mounted) return;

  final cartCount = ref.read(cartCountProvider);
  if (cartCount > 0) {
    final confirmed = await showBrandSwitchConfirm(
      context,
      current: current,
      target: picked,
      cartCount: cartCount,
    );
    if (confirmed != true) return;
    ref.read(cartProvider.notifier).clear();
  }

  ref.read(activeBrandProvider.notifier).select(picked);
}
