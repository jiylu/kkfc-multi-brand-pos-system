import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/features/new_order/data/models/brand_models.dart';

final assignedBrandsProvider = Provider<List<AssignedBrand>>(
  (ref) => sampleAssignedBrands,
);

class ActiveBrandNotifier extends Notifier<AssignedBrand> {
  @override
  AssignedBrand build() => ref.read(assignedBrandsProvider)[1]; // Aurelia's Inasal

  void select(AssignedBrand brand) => state = brand;
}

final activeBrandProvider =
    NotifierProvider<ActiveBrandNotifier, AssignedBrand>(
      ActiveBrandNotifier.new,
    );
