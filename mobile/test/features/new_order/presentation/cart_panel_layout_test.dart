import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _meal = MenuItem(
  id: 'meal',
  name: 'Test meal',
  description: '',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);

void main() {
  for (final height in [656.0, 300.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'cart controls and review stay reachable at 380x$height and ${scale}x text',
        (tester) async {
          tester.view.physicalSize = const Size(1000, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.read(cartProvider.notifier).add(_meal);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 380,
                      height: height,
                      child: const CartPanel(),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.orderEntry,
                builder: (_, _) => const Scaffold(body: Text('Review route')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: counterTheme,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final reference = find.descendant(
            of: find.byType(CartPanel),
            matching: find.byType(TextField),
          );
          await tester.ensureVisible(reference);
          await tester.pumpAndSettle();
          await tester.enterText(reference, 'Table 7');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final add = find.byTooltip('Add one');
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(container.read(cartCountProvider), 2);
          expect(container.read(cartTotalProvider), 20000);
          final send = find.text('Check and send');
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          expect(send.hitTestable(), findsOneWidget);
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(find.text('Review route'), findsOneWidget);
          expect(container.read(orderReferenceProvider), 'Table 7');
          expect(container.read(cartCountProvider), 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
