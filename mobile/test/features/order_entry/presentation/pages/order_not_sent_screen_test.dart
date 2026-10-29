import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/order_entry/data/models/order_not_sent_view_data.dart';
import 'package:mobile/features/order_entry/presentation/pages/order_not_sent_screen.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

void main() {
  Widget buildScreen({
    OrderNotSentViewData data = OrderNotSentViewData.sample,
    VoidCallback? onEditOrder,
    VoidCallback? onRetrySafely,
    bool isRetrying = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: counterTheme,
        home: OrderNotSentScreen(
          data: data,
          onEditOrder: onEditOrder,
          onRetrySafely: onRetrySafely,
          isRetrying: isRetrying,
        ),
      ),
    );
  }

  group('OrderNotSentScreen Tablet layout', () {
    testWidgets(
      'renders all tablet components including rail, cards and actions',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool editPressed = false;
        bool retryPressed = false;

        await tester.pumpWidget(
          buildScreen(
            onEditOrder: () => editPressed = true,
            onRetrySafely: () => retryPressed = true,
          ),
        );
        await tester.pumpAndSettle();

        // Navigation rail is shown on tablet
        expect(find.byType(MenuRail), findsOneWidget);
        expect(find.byType(MenuBottomNav), findsNothing);

        // Header components
        expect(find.text('NOT SENT'), findsWidgets);
        expect(find.text('Order not sent'), findsOneWidget);
        expect(
          find.text('A definite server rejection was received'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

        // Draft safe card
        expect(find.text('YOUR DRAFT IS SAFE'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Not created'), findsOneWidget);
        expect(find.text('Cart'), findsOneWidget);
        expect(find.text('3 items preserved'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('₱597.00'), findsOneWidget);

        // Order context card
        expect(find.text('ORDER CONTEXT'), findsOneWidget);
        expect(
          find.text(
            'Fix the reported error. Retry only through the agreed safe submission path.',
          ),
          findsOneWidget,
        );
        expect(find.text('DESIGN REVIEW STATE'), findsOneWidget);
        expect(find.text("Aurelia's Inasal · example only"), findsOneWidget);

        // Action buttons
        expect(find.text('Edit order'), findsOneWidget);
        expect(find.text('Retry safely'), findsOneWidget);

        // Action button interactions
        await tester.tap(find.text('Edit order'));
        await tester.pump();
        expect(editPressed, isTrue);

        await tester.tap(find.text('Retry safely'));
        await tester.pump();
        expect(retryPressed, isTrue);
      },
    );
  });

  group('OrderNotSentScreen Phone layout', () {
    testWidgets(
      'renders compact phone layout with bottom nav and tone notice',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Bottom nav is shown on phone, rail is hidden
        expect(find.byType(MenuBottomNav), findsOneWidget);
        expect(find.byType(MenuRail), findsNothing);

        // Header components on phone (no trailing cancel icon on header)
        expect(find.text('NOT SENT'), findsWidgets);
        expect(find.text('Order not sent'), findsOneWidget);
        expect(
          find.text('A definite server rejection was received'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cancel_outlined), findsNothing);

        // Draft safe card is displayed
        expect(find.text('YOUR DRAFT IS SAFE'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Not created'), findsOneWidget);
        expect(find.text('Cart'), findsOneWidget);
        expect(find.text('3 items preserved'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('₱597.00'), findsOneWidget);

        // Context card eyebrow is not shown in compact view
        expect(find.text('ORDER CONTEXT'), findsNothing);

        // Notice message is displayed
        expect(
          find.text(
            'Fix the reported error. Retry only through the agreed safe submission path.',
          ),
          findsOneWidget,
        );

        // Both buttons are visible
        expect(find.text('Edit order'), findsOneWidget);
        expect(find.text('Retry safely'), findsOneWidget);
      },
    );
  });
}
