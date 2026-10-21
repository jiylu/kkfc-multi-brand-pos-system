import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/menu/data/seed/sample_menu.dart';
import 'package:mobile/features/menu/presentation/pages/menu_screen.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_bar.dart';
import 'package:mobile/features/menu/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/menu/presentation/widgets/channel_tabs.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_header.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_navigation.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

const _phone = Size(412, 1400);
const _narrowPhone = Size(320, 900);
const _desktop = Size(1280, 1000);

Future<void> _pumpMenu(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      // Skip the fake latency of the seed provider.
      overrides: [menuItemsProvider.overrideWith((ref) async => sampleMenu)],
      child: MaterialApp(theme: counterTheme, home: const MenuScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MenuScreen layout', () {
    testWidgets('the menu bar is merged into the header', (tester) async {
      await _pumpMenu(tester, _desktop);

      expect(find.byType(MenuHeader), findsOneWidget);
      expect(find.byType(ChannelTabs), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MenuHeader),
          matching: find.byType(ChannelTabs),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the menu bar shares the header row on a wide screen', (
      tester,
    ) async {
      await _pumpMenu(tester, _desktop);

      expect(find.byType(MenuHeader), findsOneWidget);
      expect(find.byType(ChannelTabs), findsOneWidget);

      final headerTop = tester.getTopLeft(find.byType(MenuHeader)).dy;
      final headerBottom = tester.getBottomLeft(find.byType(MenuHeader)).dy;
      final tabsTop = tester.getTopLeft(find.byType(ChannelTabs)).dy;

      expect(tabsTop, greaterThanOrEqualTo(headerTop));
      expect(tabsTop, lessThan(headerBottom));
    });

    testWidgets('the header content is centered on a wide screen', (
      tester,
    ) async {
      await _pumpMenu(tester, _desktop);

      final logout = find.descendant(
        of: find.byType(MenuHeader),
        matching: find.byType(IconButton),
      );
      final groupLeft = tester.getTopLeft(find.byType(OutlinedButton)).dx;
      final groupRight = tester.getTopRight(logout).dx;
      final headerCenter = tester.getCenter(find.byType(MenuHeader)).dx;

      expect((groupLeft + groupRight) / 2, closeTo(headerCenter, 1));
    });

    testWidgets('the menu bar spans the full width', (tester) async {
      await _pumpMenu(tester, _desktop);

      expect(tester.getSize(find.byType(MenuHeader)).width, _desktop.width);
    });

    testWidgets('the cart panel docks under the header on a wide screen', (
      tester,
    ) async {
      await _pumpMenu(tester, _desktop);

      expect(find.byType(CartPanel), findsOneWidget);

      final headerBottom = tester.getBottomLeft(find.byType(MenuHeader)).dy;
      final panelTop = tester.getTopLeft(find.byType(CartPanel)).dy;

      expect(panelTop, greaterThanOrEqualTo(headerBottom));
    });

    testWidgets(
      'a phone shows the menu bar under the header and the cart bar',
      (tester) async {
        await _pumpMenu(tester, _phone);

        expect(find.byType(MenuHeader), findsOneWidget);
        expect(find.byType(ChannelTabs), findsOneWidget);
        expect(find.byType(CartBar), findsOneWidget);
        expect(find.byType(MenuBottomNav), findsOneWidget);

        // The docked panel is replaced by the bottom summary on a phone.
        expect(find.byType(CartPanel), findsNothing);

        expect(
          find.descendant(
            of: find.byType(MenuHeader),
            matching: find.byType(ChannelTabs),
          ),
          findsOneWidget,
        );

        final accountRowBottom = tester
            .getBottomLeft(find.byTooltip('Logout'))
            .dy;
        final tabsTop = tester.getTopLeft(find.byType(ChannelTabs)).dy;

        expect(tabsTop, greaterThanOrEqualTo(accountRowBottom));
      },
    );

    testWidgets('the header content is centered on a phone', (tester) async {
      await _pumpMenu(tester, _phone);

      final logout = find.descendant(
        of: find.byType(MenuHeader),
        matching: find.byType(IconButton),
      );
      final headerCenter = tester.getCenter(find.byType(MenuHeader)).dx;
      final accountLeft = tester.getTopLeft(find.byType(OutlinedButton)).dx;
      final accountRight = tester.getTopRight(logout).dx;
      final tabsCenter = tester.getCenter(find.byType(ChannelTabs)).dx;

      expect((accountLeft + accountRight) / 2, closeTo(headerCenter, 1));
      expect(tabsCenter, closeTo(headerCenter, 1));
    });

    testWidgets('the header does not overflow on a narrow phone', (
      tester,
    ) async {
      await _pumpMenu(tester, _narrowPhone);

      expect(tester.takeException(), isNull);

      final logout = find.byTooltip('Logout');
      final brand = find.byType(OutlinedButton);

      expect(logout, findsOneWidget);
      expect(brand, findsOneWidget);
      expect(find.text('Ana R.'), findsOneWidget);
      expect(
        tester.getTopRight(logout).dx,
        lessThanOrEqualTo(_narrowPhone.width),
      );
      expect(
        tester.getBottomRight(brand).dx,
        lessThanOrEqualTo(_narrowPhone.width),
      );
      expect(
        tester.getTopRight(find.text('Ana R.')).dx,
        lessThanOrEqualTo(_narrowPhone.width),
      );
    });
  });
}
