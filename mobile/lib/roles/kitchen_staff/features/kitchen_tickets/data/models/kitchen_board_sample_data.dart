import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

class KitchenBoardItem {
  const KitchenBoardItem({
    required this.ticket,
    this.actionLabel,
    this.isActionEnabled = false,
  });

  final KitchenTicketData ticket;
  final String? actionLabel;
  final bool isActionEnabled;
}

abstract final class KitchenBoardSampleData {
  static const aurelias = AssignedBrand(
    id: 'brand-ai',
    code: 'AI',
    name: "Aurelia's Inasal",
  );

  static const brandB = AssignedBrand(
    id: 'brand-bb',
    code: 'BB',
    name: 'Brand B · sample',
  );

  // --- Lane 1: NEW ORDERS ---
  static const t014 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.queued,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(quantity: 2, name: 'Paa Inasal'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['Extra rice', 'No onions'],
        ),
      ],
    ),
    actionLabel: 'Acknowledge',
    isActionEnabled: true,
  );

  static const t014Acknowledged = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.acknowledged,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(quantity: 2, name: 'Paa Inasal'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['Extra rice', 'No onions'],
        ),
      ],
    ),
    actionLabel: 'Begin preparation',
    isActionEnabled: true,
  );

  static const t014Preparing = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.preparing,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Paa Inasal',
          modifiers: ['extra rice'],
        ),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['no onions'],
        ),
      ],
    ),
    actionLabel: 'Send to QC',
    isActionEnabled: true,
  );

  static const t014Checking = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.checking,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Paa Inasal',
          modifiers: ['extra rice'],
        ),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['no onions'],
        ),
      ],
    ),
    actionLabel: 'Review QC',
    isActionEnabled: true,
  );

  static const t014Ready = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.ready,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Paa Inasal',
          modifiers: ['extra rice'],
        ),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['no onions'],
        ),
      ],
    ),
    actionLabel: 'Outbound check',
    isActionEnabled: true,
  );

  static const t014HandedOver = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 6, seconds: 20),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.handedOver,
      channel: 'Dine-in',
      reference: 'Table 3',
      brand: aurelias,
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Paa Inasal',
          modifiers: ['extra rice'],
        ),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['no onions'],
        ),
      ],
    ),
    actionLabel: 'Complete',
    isActionEnabled: true,
  );

  static const t018 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-018',
      elapsed: Duration(minutes: 1, seconds: 35),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.queued,
      channel: 'Takeaway',
      reference: 'Phone pickup',
      brand: brandB,
      items: [
        KitchenTicketItem(quantity: 1, name: 'Rice bowl'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Side order',
          modifiers: ['No sauce'],
        ),
      ],
    ),
    actionLabel: 'Acknowledge',
    isActionEnabled: false,
  );

  // --- Lane 2: COOKING ---
  static const t015 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-015',
      elapsed: Duration(minutes: 10, seconds: 5),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.preparing,
      channel: 'Takeaway',
      reference: 'Phone pickup',
      brand: brandB,
      items: [
        KitchenTicketItem(quantity: 1, name: 'Rice bowl'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Side order',
          modifiers: ['No sauce'],
        ),
      ],
    ),
    actionLabel: 'Send to QC',
    isActionEnabled: false,
  );

  static const t019 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-019',
      elapsed: Duration(minutes: 15, seconds: 21),
      age: KitchenTicketAge.late,
      status: KkfcStatus.preparing,
      channel: 'Dine-In',
      reference: 'Table 5',
      brand: aurelias,
      items: [
        KitchenTicketItem(quantity: 2, name: 'Paa Inasal'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Extra rice',
          modifiers: ['No onions', 'Late at 15 min'],
        ),
      ],
    ),
    actionLabel: 'Review late ticket',
    isActionEnabled: true,
  );

  // --- Lane 3: QUALITY CHECK ---
  static const t016 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-016',
      elapsed: Duration(minutes: 8, seconds: 2),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.checking,
      channel: 'GrabFood',
      reference: 'Store GF-1001',
      brand: aurelias,
      items: [
        KitchenTicketItem(quantity: 2, name: 'Paa Inasal'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['Extra rice'],
        ),
      ],
    ),
    actionLabel: 'Review QC',
    isActionEnabled: false,
  );

  static const t020 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-020',
      elapsed: Duration(minutes: 12, seconds: 32),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.reworking,
      channel: 'foodpanda',
      reference: 'Store FP-1902',
      brand: brandB,
      items: [
        KitchenTicketItem(quantity: 1, name: 'Rice bowl'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Side order',
          modifiers: ['Less sauce'],
        ),
      ],
    ),
    actionLabel: 'View rework',
    isActionEnabled: true,
  );

  // --- Lane 4: READY ---
  static const t017 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-017',
      elapsed: Duration(minutes: 14, seconds: 10),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.ready,
      channel: 'Dine-In',
      reference: 'Table 2',
      brand: aurelias,
      items: [
        KitchenTicketItem(quantity: 2, name: 'Paa Inasal'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Pecho Inasal',
          modifiers: ['Runner pickup'],
        ),
      ],
    ),
    actionLabel: 'Outbound check',
    isActionEnabled: false,
  );

  static const t021 = KitchenBoardItem(
    ticket: KitchenTicketData(
      ticketNumber: 'T-021',
      elapsed: Duration(minutes: 5, seconds: 40),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.ready,
      channel: 'GrabFood',
      reference: 'Store GF-1903',
      brand: brandB,
      items: [
        KitchenTicketItem(quantity: 1, name: 'Rice bowl'),
        KitchenTicketItem(
          quantity: 1,
          name: 'Side order',
          modifiers: ['Pack separately'],
        ),
      ],
    ),
    actionLabel: 'Outbound check',
    isActionEnabled: false,
  );

  static const List<KitchenBoardItem> newOrders = [t014, t018];
  static const List<KitchenBoardItem> cooking = [t015, t019];
  static const List<KitchenBoardItem> qualityCheck = [t016, t020];
  static const List<KitchenBoardItem> ready = [t017, t021];
}
