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
    VoidCallback? onPassQC,
    VoidCallback? onFailQC,
    VoidCallback? onContinueToHandover,
    VoidCallback? onAddPhoto,
    VoidCallback? onRetakePhoto,
    VoidCallback? onSubmitPhoto,
    String? backButtonLabel,
    String? acknowledgeButtonLabel,
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
          onPassQC: onPassQC,
          onFailQC: onFailQC,
          onContinueToHandover: onContinueToHandover,
          onAddPhoto: onAddPhoto,
          onRetakePhoto: onRetakePhoto,
          onSubmitPhoto: onSubmitPhoto,
          backButtonLabel: backButtonLabel,
          acknowledgeButtonLabel: acknowledgeButtonLabel,
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
    VoidCallback? onPassQC,
    VoidCallback? onFailQC,
    VoidCallback? onContinueToHandover,
    VoidCallback? onAddPhoto,
    VoidCallback? onRetakePhoto,
    VoidCallback? onSubmitPhoto,
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
          onPassQC: onPassQC,
          onFailQC: onFailQC,
          onContinueToHandover: onContinueToHandover,
          onAddPhoto: onAddPhoto,
          onRetakePhoto: onRetakePhoto,
          onSubmitPhoto: onSubmitPhoto,
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

    testWidgets(
        'renders all required elements for quality check state (05 · Quality Check)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.qualityCheck,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('QC · CHECKER AUTHORIZATION PENDING'), findsOneWidget);
      expect(find.text('Inspect T-014'), findsOneWidget);
      expect(find.text('Verify the prepared order'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('CHECKING'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pecho Inasal'), findsAtLeastNWidgets(1));

      // Quality Checklist
      expect(find.text('QUALITY CHECKLIST'), findsOneWidget);
      expect(find.text('Quantities and modifiers match'), findsOneWidget);
      expect(find.text('Packaging and destination correct'), findsOneWidget);

      // Permission Note Banner
      expect(
        find.text('QC action shown as demo; approved checker rights required.'),
        findsOneWidget,
      );

      // Bottom Actions (Pass QC green button, Fail QC red button)
      expect(find.text('Pass QC'), findsOneWidget);
      expect(find.text('Fail QC'), findsOneWidget);
    });

    testWidgets('Pass QC button triggers onPassQC callback', (tester) async {
      var passedQC = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.qualityCheck,
          onPassQC: () => passedQC = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pass QC'));
      await tester.pumpAndSettle();

      expect(passedQC, isTrue);
    });

    testWidgets('Fail QC button triggers onFailQC callback', (tester) async {
      var failedQC = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.qualityCheck,
          onFailQC: () => failedQC = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fail QC'));
      await tester.pumpAndSettle();

      expect(failedQC, isTrue);
    });

    testWidgets(
        'renders all required elements for ready for dispatch state (09 · Ready for Dispatch)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.readyForDispatch,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('READY · OUTGOING CHECK'), findsOneWidget);
      expect(find.text('Outgoing check'), findsOneWidget);
      expect(find.text('Dispatcher final review'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pecho Inasal'), findsAtLeastNWidgets(1));

      // Dispatcher Checklist
      expect(find.text('DISPATCHER CHECK'), findsOneWidget);
      expect(find.text('Confirm packing and destination'), findsOneWidget);
      expect(find.text('Review photo evidence rule'), findsOneWidget);

      // Permission Note Banner
      expect(
        find.text('Dispatcher authorization and photo policy pending.'),
        findsOneWidget,
      );

      // Bottom Actions (Keep READY outlined, Continue to handover navy filled)
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Continue to handover'), findsOneWidget);
    });

    testWidgets('Keep READY button triggers onClose callback', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.readyForDispatch,
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep READY'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Continue to handover button triggers onContinueToHandover callback',
        (tester) async {
      var continued = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.readyForDispatch,
          onContinueToHandover: () => continued = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to handover'));
      await tester.pumpAndSettle();

      expect(continued, isTrue);
    });

    testWidgets(
        'renders all required elements for photo required state (18 · Photo Missing)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.photoRequired,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('PHOTO MISSING · BLOCKED'), findsOneWidget);
      expect(find.text('Photo required'), findsOneWidget);
      expect(find.text('Handover remains unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pecho Inasal'), findsAtLeastNWidgets(1));

      // Required Evidence Checklist
      expect(find.text('REQUIRED EVIDENCE MISSING'), findsOneWidget);
      expect(find.text('Add an authorized pre-handover photo'), findsOneWidget);
      expect(find.text('Ticket stays READY until verified'), findsOneWidget);

      // Notice that check icons are not shown for missing evidence
      expect(find.byIcon(Icons.check), findsNothing);

      // Permission Note Banner
      expect(
        find.text('No completion is implied by missing evidence.'),
        findsOneWidget,
      );

      // Bottom Actions (Keep READY outlined, Add photo without demo navy filled)
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
    });

    testWidgets('Keep READY button triggers onClose callback in photoRequired state',
        (tester) async {
      var closed = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.photoRequired,
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep READY'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('Add photo button triggers onAddPhoto callback in photoRequired state',
        (tester) async {
      var photoAdded = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.photoRequired,
          onAddPhoto: () => photoAdded = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();

      expect(photoAdded, isTrue);
    });

    testWidgets(
        'renders all required elements for photo preview state (19 · Photo Preview)',
        (tester) async {
      await tester.pumpWidget(buildPanelSubject(
        panelState: KitchenTicketPanelState.photoPreview,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('PHOTO EVIDENCE · PREVIEW'), findsOneWidget);
      expect(find.text('Review attachment'), findsOneWidget);
      expect(
        find.text('Illustrative local preview · not uploaded'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ticket Summary Info
      expect(find.text("T-014 · AURELIA'S INASAL"), findsOneWidget);
      expect(find.text('Dine-in · Table 3 · sample'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('PAYMENT · UNPAID'), findsOneWidget);

      // Items & Modifiers
      expect(find.textContaining('Paa Inasal'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pecho Inasal'), findsAtLeastNWidgets(1));

      // Attachment Preview Checklist
      expect(find.text('ATTACHMENT PREVIEW · SAMPLE'), findsOneWidget);
      expect(find.text('Photo selected for this ticket (demo)'), findsOneWidget);
      expect(find.text('Confirm the correct order and contents'), findsOneWidget);

      // Check icons omitted
      expect(find.byIcon(Icons.check), findsNothing);

      // Permission Note Banner
      expect(
        find.text('Preview alone does not persist evidence.'),
        findsOneWidget,
      );

      // Bottom Actions (Retake photo outlined, Submit photo (demo) navy filled)
      expect(find.text('Retake photo'), findsOneWidget);
      expect(find.text('Submit photo (demo)'), findsOneWidget);
    });

    testWidgets('Retake photo button triggers onRetakePhoto callback in photoPreview state',
        (tester) async {
      var retakeCalled = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.photoPreview,
          onRetakePhoto: () => retakeCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retake photo'));
      await tester.pumpAndSettle();

      expect(retakeCalled, isTrue);
    });

    testWidgets(
        'Submit photo button triggers onSubmitPhoto callback in photoPreview state',
        (tester) async {
      var submitCalled = false;
      await tester.pumpWidget(
        buildPanelSubject(
          panelState: KitchenTicketPanelState.photoPreview,
          onSubmitPhoto: () => submitCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit photo (demo)'));
      await tester.pumpAndSettle();

      expect(submitCalled, isTrue);
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

    testWidgets(
        'Pressing Send to QC on panel transitions panel to Quality Check state and moves ticket to Quality Check lane',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var passQCCalled = false;
      var continueHandoverCalled = false;
      var addPhotoCalled = false;
      var retakePhotoCalled = false;
      var submitPhotoCalled = false;
      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(1280, 1000),
          onPassQC: () => passQCCalled = true,
          onContinueToHandover: () => continueHandoverCalled = true,
          onAddPhoto: () => addPhotoCalled = true,
          onRetakePhoto: () => retakePhotoCalled = true,
          onSubmitPhoto: () => submitPhotoCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Acknowledge" on T-014
      final boardAcknowledgeButtons =
          find.widgetWithText(FilledButton, 'Acknowledge');
      await tester.tap(boardAcknowledgeButtons.first);
      await tester.pumpAndSettle();

      // Tap "Acknowledge ticket" -> leads to Acknowledged state
      await tester.tap(find.text('Acknowledge ticket'));
      await tester.pumpAndSettle();

      // Tap "Begin preparation" -> leads to Preparing state
      await tester.tap(find.byKey(const ValueKey('kitchen_panel_acknowledge_button')));
      await tester.pumpAndSettle();

      // Now tap "Send to QC" on panel -> leads to Quality Check state
      await tester.tap(find.byKey(const ValueKey('kitchen_panel_acknowledge_button')));
      await tester.pumpAndSettle();

      // Panel is now in Quality Check state (05 · Quality Check)
      expect(find.text('QC · CHECKER AUTHORIZATION PENDING'), findsOneWidget);
      expect(find.text('Inspect T-014'), findsOneWidget);
      expect(find.text('Verify the prepared order'), findsOneWidget);
      expect(find.text('QUALITY CHECKLIST'), findsOneWidget);
      expect(find.text('Quantities and modifiers match'), findsOneWidget);
      expect(find.text('Packaging and destination correct'), findsOneWidget);
      expect(
        find.text('QC action shown as demo; approved checker rights required.'),
        findsOneWidget,
      );
      expect(find.text('Pass QC'), findsOneWidget);
      expect(find.text('Fail QC'), findsOneWidget);

      // Header shows QC identity
      expect(find.text('QC checker · demo'), findsOneWidget);
      expect(find.text('Access policy pending'), findsOneWidget);

      // Board lane counts updated:
      // NEW ORDERS: 01
      expect(find.text('01'), findsOneWidget);
      // COOKING: 02 (and READY is also 02)
      expect(find.text('02'), findsNWidgets(2));
      // QUALITY CHECK: 03
      expect(find.text('03'), findsOneWidget);

      // Tap "Pass QC" on panel -> transitions to Ready for Dispatch state (09 · Ready for Dispatch)
      await tester.tap(find.text('Pass QC'));
      await tester.pumpAndSettle();

      expect(passQCCalled, isTrue);

      // Panel is now in Ready for Dispatch state
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('READY · OUTGOING CHECK'), findsOneWidget);
      expect(find.text('Outgoing check'), findsOneWidget);
      expect(find.text('Dispatcher final review'), findsOneWidget);
      expect(find.text('DISPATCHER CHECK'), findsOneWidget);
      expect(find.text('Confirm packing and destination'), findsOneWidget);
      expect(find.text('Review photo evidence rule'), findsOneWidget);
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Continue to handover'), findsOneWidget);

      // Header shows Dispatcher identity
      expect(find.text('Dispatcher · demo'), findsOneWidget);
      expect(find.text('Access policy pending'), findsOneWidget);

      // Board lane counts updated:
      // NEW ORDERS: 01
      expect(find.text('01'), findsOneWidget);
      // COOKING: 02, QUALITY CHECK: 02
      expect(find.text('02'), findsNWidgets(2));
      // READY: 03
      expect(find.text('03'), findsOneWidget);

      // Tap "Continue to handover" on panel -> transitions to Photo required state (18 · Photo Missing)
      await tester.tap(find.text('Continue to handover'));
      await tester.pumpAndSettle();

      expect(continueHandoverCalled, isTrue);

      // Panel is now in Photo required state
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('PHOTO MISSING · BLOCKED'), findsOneWidget);
      expect(find.text('Photo required'), findsOneWidget);
      expect(find.text('Handover remains unavailable'), findsOneWidget);
      expect(find.text('REQUIRED EVIDENCE MISSING'), findsOneWidget);
      expect(find.text('Add an authorized pre-handover photo'), findsOneWidget);
      expect(find.text('Ticket stays READY until verified'), findsOneWidget);
      expect(
        find.text('No completion is implied by missing evidence.'),
        findsOneWidget,
      );
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);

      // Board lane counts remain:
      // NEW ORDERS: 01
      expect(find.text('01'), findsOneWidget);
      // COOKING: 02, QUALITY CHECK: 02
      expect(find.text('02'), findsNWidgets(2));
      // READY: 03
      expect(find.text('03'), findsOneWidget);

      // Header shows Dispatcher identity
      expect(find.text('Dispatcher · demo'), findsOneWidget);
      expect(find.text('Access policy pending'), findsOneWidget);

      // Tap "Add photo" invokes callback and transitions to Photo preview state (19 · Photo Preview)
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      expect(addPhotoCalled, isTrue);

      // Panel is now in Photo preview state
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('PHOTO EVIDENCE · PREVIEW'), findsOneWidget);
      expect(find.text('Review attachment'), findsOneWidget);
      expect(
        find.text('Illustrative local preview · not uploaded'),
        findsOneWidget,
      );
      expect(find.text('ATTACHMENT PREVIEW · SAMPLE'), findsOneWidget);
      expect(find.text('Photo selected for this ticket (demo)'), findsOneWidget);
      expect(find.text('Confirm the correct order and contents'), findsOneWidget);
      expect(
        find.text('Preview alone does not persist evidence.'),
        findsOneWidget,
      );
      expect(find.text('Retake photo'), findsOneWidget);
      expect(find.text('Submit photo (demo)'), findsOneWidget);

      // Board lane counts remain:
      // NEW ORDERS: 01
      expect(find.text('01'), findsOneWidget);
      // COOKING: 02, QUALITY CHECK: 02
      expect(find.text('02'), findsNWidgets(2));
      // READY: 03
      expect(find.text('03'), findsOneWidget);

      // Tap "Submit photo (demo)" invokes callback
      await tester.tap(find.text('Submit photo (demo)'));
      await tester.pumpAndSettle();
      expect(submitPhotoCalled, isTrue);

      // Tap "Retake photo" transitions back to Photo required state
      await tester.tap(find.text('Retake photo'));
      await tester.pumpAndSettle();
      expect(retakePhotoCalled, isTrue);
      expect(find.text('Photo required'), findsOneWidget);

      // Tap "Keep READY" closes the panel
      await tester.tap(find.text('Keep READY'));
      await tester.pumpAndSettle();

      expect(find.byType(KitchenTicketDetailPanel), findsNothing);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsNWidgets(2));
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets(
        'Phone layout displays Quality Check state with QC stage selected and QC identity in header',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014Checking,
          initialPanelState: KitchenTicketPanelState.qualityCheck,
        ),
      );
      await tester.pumpAndSettle();

      // Quality Check detail panel is displayed
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('QC · CHECKER AUTHORIZATION PENDING'), findsOneWidget);
      expect(find.text('Inspect T-014'), findsOneWidget);
      expect(find.text('Verify the prepared order'), findsOneWidget);
      expect(find.text('Pass QC'), findsOneWidget);
      expect(find.text('Fail QC'), findsOneWidget);

      // Phone Header shows QC identity
      expect(find.text('QC scenario'), findsOneWidget);
      expect(find.text('Access TBD'), findsOneWidget);
    });

    testWidgets(
        'Phone layout displays Ready for Dispatch state with READY stage selected and Dispatcher identity in header',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var handoverCalled = false;
      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014Ready,
          initialPanelState: KitchenTicketPanelState.readyForDispatch,
          onContinueToHandover: () => handoverCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Ready for Dispatch detail panel is displayed
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('READY · OUTGOING CHECK'), findsOneWidget);
      expect(find.text('Outgoing check'), findsOneWidget);
      expect(find.text('Dispatcher final review'), findsOneWidget);
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Continue to handover'), findsOneWidget);

      // Phone Header shows Dispatcher identity
      expect(find.text('Dispatcher'), findsOneWidget);
      expect(find.text('Access TBD'), findsOneWidget);

      // Tapping "Continue to handover" invokes callback
      await tester.tap(find.text('Continue to handover'));
      await tester.pumpAndSettle();
      expect(handoverCalled, isTrue);
    });

    testWidgets(
        'Phone layout displays Photo required state with READY stage selected and Dispatcher identity in header',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var photoAdded = false;
      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014Ready,
          initialPanelState: KitchenTicketPanelState.photoRequired,
          onAddPhoto: () => photoAdded = true,
        ),
      );
      await tester.pumpAndSettle();

      // Photo required detail panel is displayed
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('PHOTO MISSING · BLOCKED'), findsOneWidget);
      expect(find.text('Photo required'), findsOneWidget);
      expect(find.text('Handover remains unavailable'), findsOneWidget);
      expect(find.text('REQUIRED EVIDENCE MISSING'), findsOneWidget);
      expect(find.text('Keep READY'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);

      // Phone Header shows Dispatcher identity
      expect(find.text('Dispatcher'), findsOneWidget);
      expect(find.text('Access TBD'), findsOneWidget);

      // Tapping "Add photo" invokes callback
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      expect(photoAdded, isTrue);
    });

    testWidgets(
        'Phone layout displays Photo preview state with READY stage selected and Dispatcher identity in header',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var submitPhotoCalled = false;
      await tester.pumpWidget(
        buildPageSubject(
          size: const Size(400, 800),
          selectedTicket: KitchenBoardSampleData.t014Ready,
          initialPanelState: KitchenTicketPanelState.photoPreview,
          onSubmitPhoto: () => submitPhotoCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Photo preview detail panel is displayed
      expect(find.byType(KitchenTicketDetailPanel), findsOneWidget);
      expect(find.text('PHOTO EVIDENCE · PREVIEW'), findsOneWidget);
      expect(find.text('Review attachment'), findsOneWidget);
      expect(
        find.text('Illustrative local preview · not uploaded'),
        findsOneWidget,
      );
      expect(find.text('ATTACHMENT PREVIEW · SAMPLE'), findsOneWidget);
      expect(find.text('Photo selected for this ticket (demo)'), findsOneWidget);
      expect(find.text('Confirm the correct order and contents'), findsOneWidget);
      expect(find.text('Retake photo'), findsOneWidget);
      expect(find.text('Submit photo (demo)'), findsOneWidget);

      // Phone Header shows Dispatcher identity
      expect(find.text('Dispatcher'), findsOneWidget);
      expect(find.text('Access TBD'), findsOneWidget);

      // Tapping "Submit photo (demo)" invokes callback
      await tester.tap(find.text('Submit photo (demo)'));
      await tester.pumpAndSettle();
      expect(submitPhotoCalled, isTrue);
    });
  });
}
