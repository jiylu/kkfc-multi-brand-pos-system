import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/repositories/brand_repository.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/core/models/brand_models.dart';

final assignedBrandsProvider = Provider<List<AssignedBrand>>(
  (ref) => sampleAssignedBrands,
);

/// The only brand a non-superadmin may access under the current API contract.
final assignedBrandProvider = FutureProvider.autoDispose<AssignedBrand>((
  ref,
) async {
  final brandId = await ref.watch(authenticatedBrandIdProvider.future);
  return ref.watch(brandRepositoryProvider).getById(brandId);
});

class ActiveBrandNotifier extends Notifier<AssignedBrand> {
  @override
  AssignedBrand build() => ref.read(assignedBrandsProvider)[1]; // Aurelia's Inasal

  void select(AssignedBrand brand) => state = brand;
}

final activeBrandProvider =
    NotifierProvider<ActiveBrandNotifier, AssignedBrand>(
      ActiveBrandNotifier.new,
    );
