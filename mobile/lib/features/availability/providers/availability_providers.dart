import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';

/// Loads every menu item in the active brand, including inactive items.
final availabilityMenuItemsProvider =
    FutureProvider.autoDispose<List<MenuItem>>((ref) async {
      ref.watch(activeBrandProvider);
      final brandId = await ref.watch(authenticatedBrandIdProvider.future);
      return ref
          .watch(menuRepositoryProvider)
          .getByBrand(brandId, activeOnly: false);
    });
