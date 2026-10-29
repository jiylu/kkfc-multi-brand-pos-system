import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/availability/providers/availability_providers.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class _MemoryTokenStore extends TokenStore {
  @override
  Future<void> clear() async {}
}

void main() {
  final routes = [
    AppRoutes.menu,
    AppRoutes.orders,
    AppRoutes.channelChange,
    AppRoutes.availability,
  ];
  for (final route in routes) {
    testWidgets(
      'IT-MOB-ROUTE-001 Given no session When opening $route Then redirect to login',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.login,
        );
      },
    );

    testWidgets(
      'IT-MOB-ROUTE-002 Given a session on $route When it expires Then redirect to login',
      (tester) async {
        tester.view.physicalSize = const Size(1068, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          route,
        );
        container.read(sessionTokenProvider.notifier).expire('fixture-token');
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.login,
        );
        expect(container.read(sessionExpiredProvider), isTrue);
      },
    );
  }

  testWidgets(
    'IT-MOB-CART-001 Given a draft cart When navigating across order screens Then preserve lines quantities and modifiers',
    (tester) async {
      tester.view.physicalSize = const Size(1068, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          initialTokenProvider.overrideWithValue('fixture-token'),
          menuItemsProvider.overrideWith((ref) async => []),
          assignedBrandProvider.overrideWith(
            (ref) async => sampleAssignedBrands[1],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).clear();
      container
          .read(cartProvider.notifier)
          .add(
            const MenuItem(
              id: 'meal',
              name: 'Meal',
              description: '',
              pricesCentavos: {MenuChannel.dineIn: 12345},
            ),
          );
      final before = container.read(cartProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      for (final route in [
        AppRoutes.menu,
        AppRoutes.orders,
        AppRoutes.channelChange,
        AppRoutes.menu,
      ]) {
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(container.read(cartProvider), same(before));
        expect(container.read(cartCountProvider), 1);
        expect(container.read(cartTotalProvider), 12345);
      }
    },
  );
}
