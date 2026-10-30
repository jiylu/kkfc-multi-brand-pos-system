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
    KitchenTicketPanelState panelState = KitchenTicketPanelState.queued,
    VoidCallback? onClose,
    VoidCallback? onBack,
    VoidCallback? onAcknowledge,
    VoidCallback? onBeginPreparation,
    VoidCallback? onSendToQC,
    String? backButtonLabel,
  }) {
    return MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: KitchenTicketDetailPanel(
          ticket: ticket,
          panelState: panelState,
          onClose: onClose,
          onBack: onBack,
          onAcknowledge: onAcknowledge,
          onBeginPreparation: onBeginPreparation,
          onSendToQC: onSendToQC,
          backButtonLabel: backButtonLabel,
        ),
      ),
    );
  }

  Widget buildPageSubject({
    required Size size,
    KitchenBoardItem? selectedTicket,
    KitchenTicketPanelState initialPanelState = KitchenTicketPanelState.queued,
    VoidCallback? onClosePanel,
    VoidCallback? onBeginPreparation,
    VoidCallback? onSendToQC,
  }) {
    return MaterialApp(
      theme: counterTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: KitchenTicketsPage(
          selectedTicket: selectedTicket,
          initialPanelState: initialPanelState,
          onClosePanel: onClosePanel,
          onBeginPreparation: onBeginPreparation,
          onSendToQC: onSendToQC,
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

    testWidgets(
        'renders all required elements for acknowledged state (03 · Acknowledge Ticket)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.acknowledged,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('ACKNOWLEDGED'), findsNWidgets(2)); // Header & Badge
      expect(find.text('Begin preparation'), findsNWidgets(2)); // Title & Button
      expect(find.text('Ticket claimed by kitchen staff'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Confirmation Checklist
      expect(find.text('START COOKING'), findsOneWidget);
      expect(find.text('Review quantities and modifiers'), findsOneWidget);
      expect(find.text('Begin preparation when ready'), findsOneWidget);

      // Permission Note Banner
      expect(
        find.text('Server must confirm the next status.'),
        findsOneWidget,
      );

      // Bottom Actions
      expect(find.text('Stay acknowledged'), findsOneWidget);
      expect(find.text('Stay here'), findsOneWidget);
    });

    testWidgets(
        'renders all required elements for preparation state (04 · Preparation)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.preparing,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('COOKING · PREPARING'), findsOneWidget);
      expect(find.text('Prepare T-014'), findsOneWidget);
      expect(find.text('Cooking in progress'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('PREPARING'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pecho Inasal'), findsAtLeastNWidgets(1));

      // Preparation Checklist
      expect(find.text('PREPARATION CHECK'), findsOneWidget);
      expect(find.text('2 × Paa Inasal · extra rice'), findsOneWidget);
      expect(find.text('1 × Pecho Inasal · no onions'), findsOneWidget);

      // Permission Note Banner
      expect(
        find.text('Next approved transition is CHECKING.'),
        findsOneWidget,
      );

      // Bottom Actions
      expect(find.text('Keep preparing'), findsOneWidget);
      expect(find.text('Send to QC'), findsOneWidget);
    });

    testWidgets('Keep preparing button triggers onClose callback',
        (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.preparing,
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep preparing'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Send to QC button triggers onSendToQC callback',
        (tester) async {
      var sentToQC = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.preparing,
          onSendToQC: () => sentToQC = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send to QC'));
      await tester.pumpAndSettle();

      expect(sentToQC, isTrue);
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

      // Scrim is visible behind the panel
      expect(find.byKey(const ValueKey('kitchen_panel_scrim')), findsOneWidget);

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
        'Tablet slides panel in from right when opening',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(1280, 1000)),
      );
      await tester.pumpAndSettle();

      final acknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      await tester.tap(acknowledgeButtons.first);
      await tester.pump(); // Starts opening animation

      // At start or mid-flight of animation, SlideTransition exists
      final slideFinder =
          find.byKey(const ValueKey('kitchen_panel_slide_transition'));
      expect(slideFinder, findsOneWidget);

      final initialSlide = tester.widget<SlideTransition>(slideFinder);
      expect(initialSlide.position.value.dx, greaterThan(0.0));

      // After settling, it reaches Offset.zero (dx == 0)
      await tester.pumpAndSettle();
      final settledSlide = tester.widget<SlideTransition>(slideFinder);
      expect(settledSlide.position.value, equals(Offset.zero));
    });

    testWidgets(
        'Tablet tapping darkened background scrim closes the panel',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(1280, 1000)),
      );
      await tester.pumpAndSettle();

      // Open panel
      final acknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      await tester.tap(acknowledgeButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.byKey(const ValueKey('kitchen_panel_scrim')), findsOneWidget);

      // Tap on the darkened background scrim
      await tester.tap(find.byKey(const ValueKey('kitchen_panel_scrim')));
      await tester.pumpAndSettle();

      // Panel is closed
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);
      expect(find.byKey(const ValueKey('kitchen_panel_scrim')), findsNothing);
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

    testWidgets(
        'Pressing Acknowledge ticket on panel transitions panel to Acknowledged state and updates board',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(1280, 1000)),
      );
      await tester.pumpAndSettle();

      // Tap "Acknowledge" on T-014 to open queued panel
      final boardAcknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      await tester.tap(boardAcknowledgeButtons.first);
      await tester.pumpAndSettle();

      // Panel is in queued state
      expect(find.text('NEW ORDER · QUEUED'), findsOneWidget);
      expect(find.text('Ticket T-014'), findsOneWidget);
      expect(find.text('CONFIRM THE ORDER'), findsOneWidget);

      // Tap "Acknowledge ticket" on panel
      await tester.tap(find.text('Acknowledge ticket'));
      await tester.pumpAndSettle();

      // Panel transitions to Acknowledged state
      expect(find.text('Begin preparation'), findsNWidgets(3)); // Panel Title, Panel Button, Board Card Button
      expect(find.text('Ticket claimed by kitchen staff'), findsOneWidget);
      expect(find.text('START COOKING'), findsOneWidget);
      expect(find.text('Review quantities and modifiers'), findsOneWidget);
      expect(find.text('Server must confirm the next status.'), findsOneWidget);
      expect(find.text('Stay acknowledged'), findsOneWidget);

      // Board in background also updated to show ACKNOWLEDGED for T-014
      expect(find.text('ACKNOWLEDGED'), findsNWidgets(3)); // Panel header, Panel badge, Board card badge
    });

    testWidgets(
        'Pressing Begin preparation transitions panel to Preparing state and moves ticket to Cooking lane',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(size: const Size(1280, 1000)),
      );
      await tester.pumpAndSettle();

      // Tap "Acknowledge" on T-014
      final boardAcknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      await tester.tap(boardAcknowledgeButtons.first);
      await tester.pumpAndSettle();

      // Tap "Acknowledge ticket" on panel -> leads to Acknowledged state
      await tester.tap(find.text('Acknowledge ticket'));
      await tester.pumpAndSettle();

      // Tap "Begin preparation" on panel -> leads to Preparing state
      final beginPrepButtons = find.text('Begin preparation');
      expect(beginPrepButtons, findsNWidgets(3)); // title, panel button, board button
      // Tap the action button on the panel
      await tester.tap(find.byKey(const ValueKey('kitchen_panel_acknowledge_button')));
      await tester.pumpAndSettle();

      // Panel is now in Preparing state (04 · Preparation)
      expect(find.text('COOKING · PREPARING'), findsOneWidget);
      expect(find.text('Prepare T-014'), findsOneWidget);
      expect(find.text('Cooking in progress'), findsOneWidget);
      expect(find.text('PREPARATION CHECK'), findsOneWidget);
      expect(find.text('2 × Paa Inasal · extra rice'), findsAtLeastNWidgets(1));
      expect(find.text('1 × Pecho Inasal · no onions'), findsAtLeastNWidgets(1));
      expect(
        find.text('Next approved transition is CHECKING.'),
        findsOneWidget,
      );
      expect(find.text('Keep preparing'), findsOneWidget);
      expect(find.text('Send to QC'), findsAtLeastNWidgets(1));

      // Board lane counts updated:
      // NEW ORDERS: 01
      expect(find.text('01'), findsOneWidget);
      // COOKING: 03
      expect(find.text('03'), findsOneWidget);

      // Close panel via "Keep preparing"
      await tester.tap(find.text('Keep preparing'));
      await tester.pumpAndSettle();

      // Panel is closed, board remains in updated state
      expect(find.byType(KitchenTicketDetailPanel), findsNothing);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets(
        'Phone layout displays preparing state with COOK stage selected',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014Preparing,
          initialPanelState: KitchenTicketPanelState.preparing,
        ),
      );
      await tester.pumpAndSettle();

      // Preparing detail panel is displayed
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('COOKING · PREPARING'), findsOneWidget);
      expect(find.text('Prepare T-014'), findsOneWidget);
      expect(find.text('Keep preparing'), findsOneWidget);
      expect(find.text('Send to QC'), findsAtLeastNWidgets(1));
    });
  });
}
