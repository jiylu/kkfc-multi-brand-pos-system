class OrderConfirmedViewData {
  const OrderConfirmedViewData({
    required this.tag,
    required this.title,
    required this.compactTitle,
    required this.subtitle,
    required this.eyebrow,
    required this.compactEyebrow,
    required this.ticketNumber,
    required this.sentLabel,
    required this.chips,
    required this.description,
    required this.compactDescription,
    required this.brand,
    required this.channelLine,
    required this.orderStatus,
    required this.paymentStatus,
    required this.contextNote,
    required this.noticeTitle,
    required this.noticeBody,
    required this.secondaryLabel,
    required this.primaryLabel,
  });

  final String tag;
  final String title; // tablet
  final String compactTitle; // phone
  final String subtitle;
  final String eyebrow; // tablet: Kitchen handoff
  final String compactEyebrow; // phone: Kitchen ticket
  final String ticketNumber;
  final String sentLabel;
  final List<String> chips;
  final String description;
  final String compactDescription;
  final String brand;
  final String channelLine;
  final String orderStatus;
  final String paymentStatus;
  final String contextNote;
  final String noticeTitle;
  final String noticeBody;
  final String secondaryLabel;
  final String primaryLabel;

  // Static placeholder until the backend data is mapped in.
  static const sample = OrderConfirmedViewData(
    tag: 'Order confirmed',
    title: 'Order confirmed',
    compactTitle: 'Order sent!',
    subtitle: 'T-014 is ready for the kitchen team.',
    eyebrow: 'KITCHEN HANDOFF',
    compactEyebrow: 'KITCHEN TICKET',
    ticketNumber: 'T-014',
    sentLabel: 'Sent to kitchen',
    chips: ['Confirmed', 'Dine-in', 'Table 3'],
    description: 'One server-confirmed order → one kitchen ticket.',
    compactDescription: 'One order linked to one kitchen ticket.',
    brand: 'Aurelia’s Inasal',
    channelLine: 'Dine-in  ·  Table 3',
    orderStatus: 'Confirmed',
    paymentStatus: 'Unpaid',
    contextNote: 'Payment and inventory posting are separate outcomes.',
    noticeTitle: 'Order confirmed  ·  Payment unpaid',
    noticeBody:
        'Payment can be collected after dining. No refund or stock posting is implied.',
    secondaryLabel: 'New order',
    primaryLabel: 'Cancel if permitted',
  );
}