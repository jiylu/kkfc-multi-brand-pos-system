import 'order_entry_view_data.dart';

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

  /// Kitchen ticket number is intentionally static until the backend issues
  /// one for the draft order (e.g. `T-014`); everything else is derived.
  static const placeholderTicketNumber = 'T-014';

  /// Builds the confirmation copy from the real order details.
  /// [orderStatus] and [paymentStatus] are raw API values such as
  /// `CONFIRMED` / `DRAFT` and `UNPAID` / `PAID`.
  factory OrderConfirmedViewData.fromOrder({
    required String brand,
    required String channel,
    required bool isPlatform,
    String? reference,
    String? orderStatus,
    String? paymentStatus,
    String ticketNumber = placeholderTicketNumber,
  }) {
    final ref = reference?.trim() ?? '';
    final order = _titleCase(orderStatus, fallback: 'Confirmed');
    final payment = _titleCase(
      paymentStatus,
      fallback: isPlatform ? 'Paid' : 'Unpaid',
    );
    final isPaid = payment.toLowerCase() == 'paid';
    final channelLine = OrderEntryViewData.formatChannelLine(
      channel,
      ref,
      null,
      isPlatform,
    );

    return OrderConfirmedViewData(
      tag: 'Order confirmed',
      title: 'Order confirmed',
      compactTitle: 'Order sent!',
      subtitle: '$ticketNumber is ready for the kitchen team.',
      eyebrow: 'KITCHEN HANDOFF',
      compactEyebrow: 'KITCHEN TICKET',
      ticketNumber: ticketNumber,
      sentLabel: 'Sent to kitchen',
      chips: isPlatform
          ? [order, channelLine]
          : [order, channel, if (ref.isNotEmpty) ref],
      description: 'One server-confirmed order → one kitchen ticket.',
      compactDescription: 'One order linked to one kitchen ticket.',
      brand: brand,
      channelLine: channelLine,
      orderStatus: order,
      paymentStatus: payment,
      contextNote: 'Payment and inventory posting are separate outcomes.',
      noticeTitle:
          'Order ${order.toLowerCase()}  ·  Payment ${payment.toLowerCase()}',
      noticeBody: isPaid
          ? (isPlatform
                ? 'Payment is settled by the platform. No stock posting is implied.'
                : 'Payment has been received. No stock posting is implied.')
          : 'Payment can be collected after dining. No refund or stock posting is implied.',
      secondaryLabel: 'New order',
      primaryLabel: 'Cancel if permitted',
    );
  }

  static String _titleCase(String? value, {required String fallback}) {
    final text = value?.trim().replaceAll('_', ' ') ?? '';
    if (text.isEmpty) return fallback;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Static placeholder used only for previews and tests.
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
    noticeBody: 'Payment can be collected after dining. No refund or stock posting is implied.',
    secondaryLabel: 'New order',
    primaryLabel: 'Cancel if permitted',
  );
}
