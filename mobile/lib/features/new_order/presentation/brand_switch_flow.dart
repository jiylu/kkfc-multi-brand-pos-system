import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_picker_dialog.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_switch_confirm_dialog.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

Future<void> startBrandSwitch(BuildContext context, WidgetRef ref) async {
  late final AssignedBrand assignedBrand;
  try {
    assignedBrand = await ref.read(assignedBrandProvider.future);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your assigned brand.')),
      );
    }
    return;
  }
  if (!context.mounted) return;

  // The API currently assigns one brand per non-superadmin user. Keep the
  // visible selection in sync with that real backend record before opening
  // the picker, rather than exposing demo brands that cannot be authorized.
  ref.read(activeBrandProvider.notifier).select(assignedBrand);
  final current = assignedBrand;
  final brands = [assignedBrand];

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
