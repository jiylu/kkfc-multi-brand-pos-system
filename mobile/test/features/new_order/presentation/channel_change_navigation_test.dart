import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/seed/sample_menu.dart';
import 'package:mobile/features/new_order/presentation/pages/channel_repricing_screen.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/channel_tabs.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

void main() {
  group('ChannelTabs selection', () {
    testWidgets('tapping a different channel updates state and notifies', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
      );
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).add(sampleMenu[0]);
      MenuChannel? notified;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: Center(child: ChannelTabs(onSelected: (c) => notified = c)),
            ),
          ),
        ),
      );

      await tester.tap(find.text('GrabFood'));
      await tester.pumpAndSettle();

      expect(notified, MenuChannel.grabFood);
      expect(container.read(menuChannelProvider), MenuChannel.grabFood);
    });

    testWidgets('tapping the current channel does not notify', (tester) async {
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
      );
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).add(sampleMenu[0]);
      MenuChannel? notified;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: Center(child: ChannelTabs(onSelected: (c) => notified = c)),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dine-in'));
      await tester.pumpAndSettle();

      expect(notified, isNull);
    });
  });

  group('Channel change navigation', () {
    testWidgets('changing the channel opens the repricing screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: AppRoutes.menu,
        routes: [
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: AppRoutes.channelChange,
            builder: (context, state) => const ChannelRepricingScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
      );
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).add(sampleMenu[0]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: counterTheme, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChannelRepricingScreen), findsNothing);

      await tester.ensureVisible(find.text('GrabFood'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GrabFood'));
      await tester.pumpAndSettle();

      expect(find.byType(ChannelRepricingScreen), findsOneWidget);
      expect(find.text('GrabFood prices updated'), findsOneWidget);
    });

    testWidgets('switching again on the notice updates it in place', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: AppRoutes.channelChange,
        routes: [
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: AppRoutes.channelChange,
            builder: (context, state) => const ChannelRepricingScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(theme: counterTheme, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dine-in prices updated'), findsOneWidget);

      await tester.tap(find.text('Takeaway'));
      await tester.pumpAndSettle();

      expect(find.byType(ChannelRepricingScreen), findsOneWidget);
      expect(find.text('Takeaway prices updated'), findsOneWidget);
    });
  });
}
