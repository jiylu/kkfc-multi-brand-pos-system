import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/menu_header.dart';

const _meal = MenuItem(
  id: 'meal',
  name: 'Meal',
  description: '',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio(), TokenStore());

  final logoutTokens = <String>[];

  @override
  Future<void> logout(String token) async {
    logoutTokens.add(token);
  }
}

void main() {
  testWidgets('header logout clears the draft order and the session', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        initialTokenProvider.overrideWithValue('tok-abc'),
        authRepositoryProvider.overrideWithValue(repo),
        assignedBrandProvider.overrideWith(
          (ref) async => sampleAssignedBrands[1],
        ),
        menuItemsProvider.overrideWith((ref) async => const <MenuItem>[]),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).add(_meal);
    container.read(orderReferenceProvider.notifier).set('ORDER-1');
    container.read(storeReferenceProvider.notifier).set('STORE-1');
    container.read(menuSearchProvider.notifier).set('meal');
    container.read(menuChannelProvider.notifier).select(MenuChannel.takeaway);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: counterTheme,
          home: const Scaffold(body: MenuHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider), isEmpty);
    expect(container.read(cartCountProvider), 0);
    expect(container.read(cartTotalProvider), 0);
    expect(container.read(orderReferenceProvider), isEmpty);
    expect(container.read(storeReferenceProvider), isEmpty);
    expect(container.read(menuSearchProvider), isEmpty);
    expect(container.read(menuChannelProvider), MenuChannel.dineIn);
    expect(
      container.read(menuChannelProvider.notifier).previousChannel,
      isNull,
    );
    expect(container.read(sessionTokenProvider), isNull);
    expect(repo.logoutTokens, ['tok-abc']);
  });
}
