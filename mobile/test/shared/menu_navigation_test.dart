import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

class _NavHost extends StatelessWidget {
  const _NavHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Expanded(child: SizedBox()),
          MenuBottomNav(),
        ],
      ),
    );
  }
}

class _RailHost extends StatelessWidget {
  const _RailHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MenuRail(),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final path in [
        AppRoutes.menu,
        AppRoutes.orders,
        AppRoutes.availability,
        AppRoutes.channelChange,
      ])
        GoRoute(path: path, builder: (context, state) => const _NavHost()),
    ],
  );
}

bool _isSelected(WidgetTester tester, String label) {
  final finder = find.descendant(
    of: find.byType(MenuBottomNav),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.label == label,
    ),
  );

  return tester.widget<Semantics>(finder).properties.selected ?? false;
}

Future<void> _tapDestination(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(MenuBottomNav), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('highlights the destination for the current route', (
    tester,
  ) async {
    final router = _buildRouter(AppRoutes.menu);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: counterTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'New order'), isTrue);
    expect(_isSelected(tester, 'Orders'), isFalse);
    expect(_isSelected(tester, 'Menu'), isFalse);

    await _tapDestination(tester, 'Orders');

    expect(_isSelected(tester, 'Orders'), isTrue);
    expect(_isSelected(tester, 'New order'), isFalse);

    await _tapDestination(tester, 'Menu');

    expect(_isSelected(tester, 'Menu'), isTrue);
    expect(_isSelected(tester, 'Orders'), isFalse);

    await _tapDestination(tester, 'New order');

    expect(_isSelected(tester, 'New order'), isTrue);
    expect(_isSelected(tester, 'Menu'), isFalse);
  });

  testWidgets('keeps New order selected on the channel change route', (
    tester,
  ) async {
    final router = _buildRouter(AppRoutes.channelChange);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: counterTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'New order'), isTrue);
  });

  testWidgets('rail items share the full rail width', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.menu,
      routes: [
        GoRoute(
          path: AppRoutes.menu,
          builder: (context, state) => const _RailHost(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: counterTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    final items = find.descendant(
      of: find.byType(MenuRail),
      matching: find.byType(AnimatedContainer),
    );

    expect(items, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      expect(tester.getSize(items.at(i)).width, MenuLayout.railWidth);
    }
  });
}
