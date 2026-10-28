import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/order_entry/data/models/duplicate_platform_order_view_data.dart';
import 'package:mobile/features/order_entry/presentation/pages/duplicate_platform_order_screen.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

void main() {
  Widget buildScreen({
    DuplicatePlatformOrderViewData data = DuplicatePlatformOrderViewData.sample,
    VoidCallback? onBackToOrder,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: counterTheme,
        home: DuplicatePlatformOrderScreen(
          data: data,
          onBackToOrder: onBackToOrder,
        ),
      ),
    );
  }

  group('DuplicatePlatformOrderScreen Tablet layout', () {
    testWidgets('renders all tablet components including rail, cards and single action button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool backPressed = false;

      await tester.pumpWidget(
        buildScreen(onBackToOrder: () => backPressed = true),
      );
      await tester.pumpAndSettle();

      // Navigation rail is shown on tablet
      expect(find.byType(MenuRail), findsOneWidget);
      expect(find.byType(MenuBottomNav), findsNothing);

      // Header components
      expect(find.text('DUPLICATE FOUND'), findsWidgets);
      expect(find.text('Already sent as T-025'), findsOneWidget);
      expect(
        find.text('GrabFood · Existing order located'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Matched reference card
      expect(find.text('MATCHED REFERENCE'), findsOneWidget);
      expect(find.text('Order / ticket'), findsOneWidget);
      expect(find.text('T-025'), findsOneWidget);
      expect(find.text('Store'), findsOneWidget);
      expect(find.text('Sample store'), findsOneWidget);
      expect(find.text('External #'), findsOneWidget);
      expect(find.text('GF-1001'), findsOneWidget);

      // Order context card
      expect(find.text('ORDER CONTEXT'), findsOneWidget);
      expect(
        find.text(
          'Same channel + store + external reference. No second kitchen ticket was created.',
        ),
        findsOneWidget,
      );
      expect(find.text('DESIGN REVIEW STATE'), findsOneWidget);
      expect(find.text("Aurelia's Inasal · example only"), findsOneWidget);

      // Single action button: Back to order
      expect(find.text('Back to order'), findsOneWidget);

      // Tap action button
      await tester.tap(find.text('Back to order'));
      await tester.pump();
      expect(backPressed, isTrue);
    });
  });

  group('DuplicatePlatformOrderScreen Phone layout', () {
    testWidgets('renders compact phone layout with bottom nav and tone notice', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Bottom nav is shown on phone, rail is hidden
      expect(find.byType(MenuBottomNav), findsOneWidget);
      expect(find.byType(MenuRail), findsNothing);

      // Header components on phone (no trailing warning icon)
      expect(find.text('DUPLICATE FOUND'), findsWidgets);
      expect(find.text('Already sent as T-025'), findsOneWidget);
      expect(
        find.text('GrabFood · Existing order located'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      // Matched reference card is displayed
      expect(find.text('MATCHED REFERENCE'), findsOneWidget);
      expect(find.text('Order / ticket'), findsOneWidget);
      expect(find.text('T-025'), findsOneWidget);
      expect(find.text('Store'), findsOneWidget);
      expect(find.text('Sample store'), findsOneWidget);
      expect(find.text('External #'), findsOneWidget);
      expect(find.text('GF-1001'), findsOneWidget);

      // Context card eyebrow is not shown in compact view
      expect(find.text('ORDER CONTEXT'), findsNothing);

      // Notice message is displayed
      expect(
        find.text(
          'Same channel + store + external reference. No second kitchen ticket was created.',
        ),
        findsOneWidget,
      );

      // Single action button is visible
      expect(find.text('Back to order'), findsOneWidget);
    });
  });
}
