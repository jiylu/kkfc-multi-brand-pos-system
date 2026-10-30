import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/pages/kitchen_tickets_page.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_tablet_header.dart';

void main() {
  Widget buildPanelSubject({
    KitchenBoardItem ticket = KitchenBoardSampleData.t014,
    VoidCallback? onClose,
    VoidCallback? onBack,
    VoidCallback? onAcknowledge,
    String backButtonLabel = 'Back to board',
  }) {
    return MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: KitchenTicketDetailPanel(
          ticket: ticket,
          onClose: onClose,
          onBack: onBack,
          onAcknowledge: onAcknowledge,
          backButtonLabel: backButtonLabel,
        ),
      ),
    );
  }

  Widget buildPageSubject({
    required Size size,
    KitchenBoardItem? selectedTicket,
    VoidCallback? onClosePanel,
  }) {
    return MaterialApp(
      theme: counterTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: KitchenTicketsPage(
          selectedTicket: selectedTicket,
          onClosePanel: onClosePanel,
        ),
      ),
    );
  }

  group('KitchenTicketDetailPanel · Component structure & stateless check', () {
    test('is a StatelessWidget', () {
      const panel = KitchenTicketDetailPanel();
      expect(panel, isA<StatelessWidget>());
    });

    testWidgets('renders all required elements from UI mockup', (tester) async {
      await tester.pumpWidget(buildPanelSubject());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('NEW ORDER · QUEUED'), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);
      expect(find.text('Ready to acknowledge'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('QUEUED'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsOneWidget);
      expect(find.textContaining('Pecho Inasal'), findsOneWidget);

      // Confirmation Checklist
      expect(find.text('CONFIRM THE ORDER'), findsOneWidget);
      expect(find.text('Check all items and modifiers'), findsOneWidget);
      expect(find.text('Verify brand and destination'), findsOneWidget);

      // Permission Note Banner
      expect(
        find.text('Preparer permission requires Backend approval.'),
        findsOneWidget,
      );

      // Bottom Actions
      expect(find.text('Back to board'), findsOneWidget);
      expect(find.text('Acknowledge ticket'), findsOneWidget);
    });

    testWidgets('close icon button triggers onClose callback', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(onClose: () => closed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Back to board button triggers onClose callback', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(onClose: () => closed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Customized "Back to brand" button closes panel when tapped',
        (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(
          backButtonLabel: 'Back to brand',
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to brand'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Acknowledge ticket button triggers onAcknowledge callback',
        (tester) async {
      var acknowledged = false;
      await tester.pumpWidget(
        buildPanelSubject(onAcknowledge: () => acknowledged = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Acknowledge ticket'));
      await tester.pumpAndSettle();

      expect(acknowledged, isTrue);
    });
  });

  group('KitchenTicketsPage integration with right panel', () {
    testWidgets('Tablet renders both board lanes and right panel when ticket selected',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(1280, 1000),
          selectedTicket: KitchenBoardSampleData.t014,
        ),
      );
      await tester.pumpAndSettle();

      // Tablet chrome
      expect(find.byType(KitchenTabletHeader), findsOneWidget);

      // Board is visible
      expect(find.text('Kitchen Board'), findsOneWidget);
      expect(find.text('NEW ORDERS'), findsOneWidget);

      // Right panel is visible
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);
      expect(find.text('CONFIRM THE ORDER'), findsOneWidget);
    });

    testWidgets('Phone renders detail panel in body when ticket selected',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014,
        ),
      );
      await tester.pumpAndSettle();

      // Right/queued ticket panel is shown
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);
      expect(find.text('Back to board'), findsOneWidget);
    });

    testWidgets('Closing panel on tablet triggers onClosePanel', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var panelClosed = false;
      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(1280, 1000),
          selectedTicket: KitchenBoardSampleData.t014,
          onClosePanel: () => panelClosed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      expect(panelClosed, isTrue);
    });

    testWidgets(
        'Tablet opens panel when tapping Acknowledge on ticket card, and closes on Back to board',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(1280, 1000)),
      );
      await tester.pumpAndSettle();

      // Panel is initially closed
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);

      // Tap "Acknowledge" on T-014 (lane 1 has 2 Acknowledge buttons: T-014 enabled, T-018 disabled)
      final acknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      expect(acknowledgeButtons, findsNWidgets(2));
      await tester.tap(acknowledgeButtons.first);
      await tester.pumpAndSettle();

      // Right panel is now open
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);
      expect(find.text('CONFIRM THE ORDER'), findsOneWidget);

      // Tap "Back to board"
      await tester.tap(find.text('Back to board'));
      await tester.pumpAndSettle();

      // Panel is closed
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);
    });

    testWidgets(
        'Phone opens panel when tapping Acknowledge on ticket card, and closes on close button',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(400, 800)),
      );
      await tester.pumpAndSettle();

      // Panel is initially closed
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);

      // Tap Acknowledge on active card
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();

      // Detail panel is now open
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);

      // Tap close button "×"
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Panel is closed
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);
    });
  });
}
