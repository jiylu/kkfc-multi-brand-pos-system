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
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/features/new_order/presentation/widgets/repricing/operational_context_card.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _phone = Size(412, 915);
const _narrowPhone = Size(320, 900);
const _tablet = Size(1068, 800);

Future<void> _pumpScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
  );
  addTearDown(container.dispose);
  container.read(menuChannelProvider.notifier).select(MenuChannel.grabFood);

  final extraRice = ModifierGroup.addOn(
    id: 'extra-rice',
    name: 'Extra rice',
    priceCentavos: 2500,
  );
  final cart = container.read(cartProvider.notifier);
  cart.addConfigured(sampleMenu[0].withModifierGroups([extraRice]), {
    extraRice.id: ModifierGroup.addOnOn,
  }, 2);
  cart.addConfigured(sampleMenu[1], const {}, 1);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: counterTheme,
        home: const ChannelRepricingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ChannelRepricingScreen layout', () {
    testWidgets('a phone shows the updated order summary and got it action', (
      tester,
    ) async {
      await _pumpScreen(tester, _phone);

      expect(find.text('GrabFood prices updated'), findsOneWidget);
      expect(find.text('Channel change and undo'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.byType(MenuBottomNav), findsOneWidget);
      expect(find.byType(MenuRail), findsNothing);
      expect(find.byType(OperationalContextCard), findsNothing);
    });

    testWidgets('a tablet docks the rail, context card and got it action', (
      tester,
    ) async {
      await _pumpScreen(tester, _tablet);

      expect(find.text('Prices updated for GrabFood'), findsOneWidget);
      expect(find.byType(MenuRail), findsOneWidget);
      expect(find.byType(OperationalContextCard), findsOneWidget);
      expect(find.text('Operational context'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('shows the recalculated channel prices', (tester) async {
      await _pumpScreen(tester, _phone);

      expect(find.text('Selected channel'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('2 × Paa Inasal'), findsOneWidget);
      expect(find.text('2 × (₱205.00 + ₱25.00)'), findsOneWidget);
      expect(find.text('₱460.00'), findsOneWidget);
      expect(find.text('1 × Pecho Inasal'), findsOneWidget);
      expect(find.text('1 × ₱215.00'), findsOneWidget);
      expect(find.text('₱215.00'), findsOneWidget);
      expect(find.text('Repriced total'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('₱675.00'), findsOneWidget);
    });

    testWidgets('does not overflow on a narrow phone', (tester) async {
      await _pumpScreen(tester, _narrowPhone);

      expect(tester.takeException(), isNull);
    });

    testWidgets('got it returns to the new order screen', (tester) async {
      tester.view.physicalSize = _phone;
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

      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: counterTheme, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChannelRepricingScreen), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byType(ChannelRepricingScreen), findsNothing);
    });

    testWidgets('undo restores the previous channel and recalculates prices', (
      tester,
    ) async {
      await _pumpScreen(tester, _phone);

      expect(find.text('GrabFood prices updated'), findsOneWidget);
      expect(find.text('₱675.00'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Undo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Dine-in prices updated'), findsOneWidget);
      expect(find.text('2 × (₱179.00 + ₱25.00)'), findsOneWidget);
      expect(find.text('₱408.00'), findsOneWidget);
      expect(find.text('1 × ₱189.00'), findsOneWidget);
      expect(find.text('₱597.00'), findsOneWidget);
    });
  });
}
