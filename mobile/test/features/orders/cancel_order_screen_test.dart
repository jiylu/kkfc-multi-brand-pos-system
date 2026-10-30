import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';
import 'package:mobile/features/orders/cancel/presentation/pages/cancel_order_screen.dart';

const _liveOrderId = '11111111-1111-4111-8111-111111111111';

class _FakeCancelRepository implements CancelOrderRepository {
  _FakeCancelRepository(this.result);

  CancelOrderResult result;
  final calls = <({String brandId, String orderId, String reason})>[];

  @override
  Future<CancelOrderResult> cancel({
    required String brandId,
    required String orderId,
    required String reason,
  }) async {
    calls.add((brandId: brandId, orderId: orderId, reason: reason));
    return result;
  }
}

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

  Future<void> pumpLiveCancelOrder(
    WidgetTester tester,
    _FakeCancelRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cancelOrderRepositoryProvider.overrideWithValue(repository),
          authenticatedBrandIdProvider.overrideWith((ref) async => 'brand-1'),
        ],
        child: MaterialApp(
          theme: counterTheme,
          home: const CancelOrderScreen(
            orderId: _liveOrderId,
            orderCode: 'GC-00007',
          ),
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
      expect(find.text('Cancelling…'), findsOneWidget);
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
      expect(find.text('SAMPLE OUTCOME'), findsOneWidget);
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

  testWidgets(
    'IT-MOB-CANCEL-008 Given a live order When the reason is submitted Then the server result is shown',
    (tester) async {
      final repository = _FakeCancelRepository(
        CancelOrderAccepted(
          const CancelOrderOutcome(
            orderId: _liveOrderId,
            status: 'CANCELLED',
            orderCode: 'GC-00007',
            cancellationReason: 'Customer changed their mind.',
          ),
        ),
      );
      await pumpLiveCancelOrder(tester, repository);

      // Live mode never shows the demo outcome controls.
      expect(find.text('Sample: Confirmed'), findsNothing);

      await tester.enterText(
        find.byType(TextField),
        'Customer changed their mind.',
      );
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.text('SERVER CONFIRMED'), findsOneWidget);
      expect(find.text('SAMPLE OUTCOME'), findsNothing);
      expect(find.text('No kitchen ticket'), findsOneWidget);
      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.brandId, 'brand-1');
      expect(repository.calls.single.orderId, _liveOrderId);
      expect(repository.calls.single.reason, 'Customer changed their mind.');
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-009 Given a live order When the server rejects the cancellation Then the denied step shows the message',
    (tester) async {
      final repository = _FakeCancelRepository(
        const CancelOrderDenied(
          'Completed orders or handed-over tickets cannot be cancelled.',
          statusCode: 409,
        ),
      );
      await pumpLiveCancelOrder(tester, repository);

      await tester.enterText(find.byType(TextField), 'Customer request.');
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.text('Cancellation denied'), findsOneWidget);
      expect(find.text('HTTP 409'), findsOneWidget);
      expect(
        find.text(
          'Completed orders or handed-over tickets cannot be cancelled.',
        ),
        findsWidgets,
      );
      expect(find.text('Retry cancellation'), findsNothing);
      expect(find.text('Back to orders'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-010 Given a denied live order When retrying Then the same request is sent again',
    (tester) async {
      final repository = _FakeCancelRepository(
        const CancelOrderDenied('Could not reach the server.', retryable: true),
      );
      await pumpLiveCancelOrder(tester, repository);

      await tester.enterText(find.byType(TextField), 'Customer request.');
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(repository.calls, hasLength(1));

      await tester.tap(find.text('Retry cancellation'));
      await tester.pumpAndSettle();

      expect(repository.calls, hasLength(2));
      expect(repository.calls.last.orderId, _liveOrderId);
      expect(repository.calls.last.reason, 'Customer request.');
    },
  );

  testWidgets(
    'IT-MOB-CANCEL-011 Given a live order with no reason Then nothing is sent to the server',
    (tester) async {
      final repository = _FakeCancelRepository(
        const CancelOrderDenied('Unused.'),
      );
      await pumpLiveCancelOrder(tester, repository);

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();

      expect(find.text('Reason is required'), findsOneWidget);
      expect(repository.calls, isEmpty);
    },
  );
}
