import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/features/orders/cancel/presentation/pages/cancel_order_screen.dart';

void main() {
  Future<void> pumpCancelOrder(
    WidgetTester tester, {
    CancelOrderStep step = CancelOrderStep.review,
  }) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: counterTheme,
          home: CancelOrderScreen(initialStep: step),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'IT-MOB-CANCEL-001 Given the review step Then the reason request and both actions are shown',
    (tester) async {
      await pumpCancelOrder(tester);

      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(find.text('REVIEW REQUEST'), findsWidgets);
      expect(find.text('T-014'), findsWidgets);
      expect(find.text('Cancellation reason *'), findsOneWidget);
      expect(find.text('Keep order'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-002 Given an empty reason When Cancel order is pressed Then the validation step is shown',
    (tester) async {
      await pumpCancelOrder(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.text('Reason is required'), findsOneWidget);
      expect(
        find.text('Error: Cancellation reason is required.'),
        findsOneWidget,
      );
      expect(find.text('Not cancelled'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-003 Given a reason When Cancel order is pressed Then the pending step is shown',
    (tester) async {
      await pumpCancelOrder(tester);

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelling order'), findsOneWidget);
      expect(find.text('Checking…'), findsOneWidget);
      expect(find.text('Processing…'), findsOneWidget);
      expect(find.text('Sample: Confirmed'), findsOneWidget);
      expect(find.text('Sample: Denied'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-004 Given the pending step When the sample is confirmed Then the outcome step is shown',
    (tester) async {
      await pumpCancelOrder(tester, step: CancelOrderStep.processing);

      await tester.tap(find.text('Sample: Confirmed'));
      await tester.pumpAndSettle();

      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.text('CANCELLED'), findsWidgets);
      expect(find.text('SERVER CONFIRMED'), findsOneWidget);
      expect(find.text('Back to menu'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-005 Given the pending step When the sample is denied Then the denied step is shown',
    (tester) async {
      await pumpCancelOrder(tester, step: CancelOrderStep.processing);

      await tester.tap(find.text('Sample: Denied'));
      await tester.pumpAndSettle();

      expect(find.text('Cancellation denied'), findsOneWidget);
      expect(find.text('ACTION NOT COMPLETED'), findsWidgets);
      expect(find.text('Refresh order status'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-006 Given the approval step Then the restricted action cannot be confirmed',
    (tester) async {
      await pumpCancelOrder(tester, step: CancelOrderStep.approvalRequired);

      expect(find.text('Approval needed'), findsOneWidget);
      expect(find.text('PREPARING'), findsOneWidget);
      expect(find.text('Not authorized'), findsOneWidget);
      expect(find.text('Return to order'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-007 Given a phone width Then the review step lays out without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: counterTheme,
            home: const CancelOrderScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cancel this order?'), findsOneWidget);
      expect(find.text('Keep order'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);
    },
  );
}
