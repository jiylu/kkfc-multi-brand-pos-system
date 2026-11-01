import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_tickets_view_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/pages/kitchen_tickets_page.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/kitchen_board_phone_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/kitchen_board_tablet_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/up_next_ticket_card.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_stage_tabs.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_bottom_nav.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_side_nav.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_tablet_header.dart';

void main() {
  Widget buildSubject({
    required Size size,
    KitchenTicketsViewState viewState = KitchenTicketsViewState.active,
  }) {
    return MaterialApp(
      theme: counterTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: KitchenTicketsPage(viewState: viewState),
      ),
    );
  }

  group('Kitchen Board · Tablet', () {
    testWidgets('renders 4 lanes with sample tickets and headers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject(size: const Size(1280, 1000)));
      await tester.pumpAndSettle();

      // Tablet chrome & navigation
      expect(find.byType(KitchenTabletHeader), findsOneWidget);
      expect(find.byType(KitchenSideNav), findsOneWidget);

      // Heading & filter bar
      expect(find.text('Kitchen Board'), findsOneWidget);
      expect(
        find.text('All permitted brands · live ticket workflow (sample data)'),
        findsOneWidget,
      );
      expect(find.text('KITCHEN STAFF'), findsWidgets);
      expect(find.text('DESIGN SAMPLE · NOT LIVE'), findsOneWidget);
      expect(
        find.textContaining('FIGMA QA · T-014 / T-019 / T-020 interactive'),
        findsOneWidget,
      );

      // Tablet View
      expect(find.byType(KitchenBoardTabletView), findsOneWidget);

      // 4 lanes
      expect(find.text('NEW ORDERS'), findsOneWidget);
      expect(find.text('COOKING'), findsOneWidget);
      expect(find.text('QUALITY CHECK'), findsOneWidget);
      expect(find.text('READY'), findsNWidgets(3));

      // Ticket cards present
      expect(find.text('T-014'), findsOneWidget);
      expect(find.text('T-018'), findsOneWidget);
      expect(find.text('T-015'), findsOneWidget);
      expect(find.text('T-019'), findsOneWidget);
      expect(find.text('T-016'), findsOneWidget);
      expect(find.text('T-020'), findsOneWidget);
      expect(find.text('T-017'), findsOneWidget);
      expect(find.text('T-021'), findsOneWidget);

      // Action buttons
      expect(find.text('Acknowledge'), findsNWidgets(2));
      expect(find.text('Send to QC'), findsOneWidget);
      expect(find.text('Review late ticket'), findsOneWidget);
      expect(find.text('Review QC'), findsOneWidget);
      expect(find.text('View rework'), findsOneWidget);
      expect(find.text('Outbound check'), findsNWidgets(2));
    });
  });

  group('Kitchen Board · Phone', () {
    testWidgets('renders stage queue with active card and up next card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject(size: const Size(400, 800)));
      await tester.pumpAndSettle();

      // Phone chrome & navigation
      expect(find.byType(KitchenStageTabs), findsOneWidget);
      expect(find.byType(KitchenBottomNav), findsOneWidget);

      // Heading
      expect(find.text('Ticket queue'), findsOneWidget);
      expect(find.text('Shared kitchen · permitted brands'), findsOneWidget);

      // Phone View
      expect(find.byType(KitchenBoardPhoneView), findsOneWidget);
      expect(find.text('NEW ORDERS'), findsOneWidget);

      // Active ticket T-014
      expect(find.text('T-014'), findsOneWidget);
      expect(find.text("Aurelia's Inasal"), findsOneWidget);
      expect(find.text('Dine-in · Table 3'), findsOneWidget);
      expect(find.text('2 × Paa Inasal'), findsOneWidget);
      expect(find.text('1 × Pecho Inasal'), findsOneWidget);
      expect(find.text('Acknowledge'), findsOneWidget);

      // Up Next ticket T-018
      expect(find.byType(UpNextTicketCard), findsOneWidget);
      expect(find.text('UP NEXT · T-018'), findsOneWidget);
      expect(find.text('1 × Rice bowl'), findsOneWidget);
      expect(find.text('1 × Side order'), findsOneWidget);
    });
  });
}
