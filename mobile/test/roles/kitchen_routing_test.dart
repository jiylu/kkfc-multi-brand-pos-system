import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/availability/providers/availability_providers.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/pages/kitchen_tickets_page.dart';

class _MemoryTokenStore extends TokenStore {
  @override
  Future<void> clear() async {}
}

void main() {
  group('UserRole', () {
    test('parses kitchen roles and correctly flags isKitchen', () {
      expect(UserRole.fromApiValue('KITCHEN_STAFF'), UserRole.kitchenStaff);
      expect(UserRole.fromApiValue('kitchen_staff'), UserRole.kitchenStaff);
      expect(UserRole.kitchenStaff.isKitchen, isTrue);

      expect(UserRole.fromApiValue('KITCHEN_HEAD'), UserRole.kitchenHead);
      expect(UserRole.fromApiValue('kitchen_head'), UserRole.kitchenHead);
      expect(UserRole.kitchenHead.isKitchen, isTrue);
    });

    test('non-kitchen roles are not flagged as isKitchen', () {
      expect(UserRole.fromApiValue('CASHIER_STAFF'), UserRole.cashierStaff);
      expect(UserRole.cashierStaff.isKitchen, isFalse);

      expect(UserRole.fromApiValue('MANAGER'), UserRole.manager);
      expect(UserRole.manager.isKitchen, isFalse);

      expect(UserRole.fromApiValue('SUPERADMIN'), UserRole.superadmin);
      expect(UserRole.superadmin.isKitchen, isFalse);

      expect(UserRole.fromApiValue(null), isNull);
      expect(UserRole.fromApiValue('UNKNOWN_ROLE'), isNull);
    });
  });

  group('Kitchen routing & access control', () {
    testWidgets(
      'Given logged out user When opening kitchen tickets Then redirects to login',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        container.read(routerProvider).go(AppRoutes.kitchenTickets);
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
      'Given user with KITCHEN_STAFF role When on login Then redirects to kitchen tickets',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenStaff),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsOneWidget);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.kitchenTickets,
        );
      },
    );

    testWidgets(
      'Given user with KITCHEN_HEAD role When on login Then redirects to kitchen tickets',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenHead),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsOneWidget);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.kitchenTickets,
        );
      },
    );

    testWidgets(
      'Given kitchen user When attempting to navigate to cashier menu Then redirects back to kitchen tickets',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenStaff),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        // Attempt navigation to cashier menu
        container.read(routerProvider).go(AppRoutes.menu);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsOneWidget);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.kitchenTickets,
        );
      },
    );

    testWidgets(
      'Given non-kitchen user (CASHIER_STAFF) When navigating to kitchen tickets Then redirects to menu',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.cashierStaff),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        // Attempt navigation to kitchen tickets
        container.read(routerProvider).go(AppRoutes.kitchenTickets);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsNothing);
        expect(
          container
              .read(routerProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoutes.menu,
        );
      },
    );

    testWidgets(
      'Given kitchen user on tablet layout When tapping logout Then signs out and redirects to login',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenStaff),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsOneWidget);
        expect(find.byTooltip('Logout'), findsOneWidget);

        await tester.tap(find.byTooltip('Logout'));
        await tester.pumpAndSettle();

        expect(container.read(sessionTokenProvider), isNull);
        expect(container.read(userRoleProvider), isNull);
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
      'Given kitchen user on phone layout When tapping logout Then signs out and redirects to login',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            initialTokenProvider.overrideWithValue('fixture-token'),
            initialRoleProvider.overrideWithValue(UserRole.kitchenStaff),
            tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
            menuItemsProvider.overrideWith((ref) async => []),
            availabilityMenuItemsProvider.overrideWith((ref) async => []),
            authenticatedBrandIdProvider.overrideWith(
              (ref) async => '00000000-0000-0000-0000-000000000001',
            ),
            assignedBrandProvider.overrideWith(
              (ref) async => sampleAssignedBrands.first,
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const App()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketsPage), findsOneWidget);
        expect(find.byTooltip('Logout'), findsOneWidget);

        await tester.tap(find.byTooltip('Logout'));
        await tester.pumpAndSettle();

        expect(container.read(sessionTokenProvider), isNull);
        expect(container.read(userRoleProvider), isNull);
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
  });
}
