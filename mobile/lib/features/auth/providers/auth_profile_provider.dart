import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/auth/data/repository/auth_repository.dart';

/// The UUID that scopes all brand-owned POS API requests for this session.
final authenticatedBrandIdProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final brandId = await ref.watch(authRepositoryProvider).getCurrentBrandId();
  if (brandId == null) {
    throw StateError('The signed-in user is not assigned to a brand.');
  }
  return brandId;
});
