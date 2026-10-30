import 'package:flutter/foundation.dart';

/// The saved order returned by
/// `POST /brands/:brandId/orders/:orderId/cancel`.
///
/// Only the fields the cancel screens display are parsed; the API returns the
/// full order, including items and the kitchen ticket.
@immutable
class CancelOrderOutcome {
  const CancelOrderOutcome({
    required this.orderId,
    required this.status,
    this.orderCode,
    this.cancellationReason,
    this.cancelledAt,
    this.ticketStatus,
  });

  factory CancelOrderOutcome.fromJson(Map<String, dynamic> json) {
    final orderId = json['order_id'];
    if (orderId is! String || orderId.isEmpty) {
      throw const FormatException(
        'The cancellation response is missing order_id.',
      );
    }

    final ticket = json['kitchen_tickets_order'];
    final cancelledAt = json['cancelled_at'];

    return CancelOrderOutcome(
      orderId: orderId,
      status: json['status'] as String? ?? 'UNKNOWN',
      orderCode: json['order_code'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: cancelledAt is String
          ? DateTime.tryParse(cancelledAt)
          : null,
      ticketStatus: ticket is Map ? ticket['status'] as String? : null,
    );
  }

  final String orderId;

  /// Order status reported by the server; `CANCELLED` on success.
  final String status;

  /// Server-generated display code, for example `GC-00001`.
  final String? orderCode;

  final String? cancellationReason;
  final DateTime? cancelledAt;

  /// Kitchen ticket status after cancellation, or null when the order had no
  /// ticket yet (an unpaid draft).
  final String? ticketStatus;

  bool get isCancelled => status == 'CANCELLED';

  /// Server state shown on the outcome screen.
  String get ticketLabel =>
      ticketStatus == null ? 'No kitchen ticket' : 'Ticket $ticketStatus';
}

/// Result of one cancellation attempt.
///
/// [CancelOrderAccepted] maps to the cancelled step, [CancelOrderDenied] to the
/// denied step. A denial can be retried: the API returns the original saved
/// cancellation for an already-cancelled order.
sealed class CancelOrderResult {
  const CancelOrderResult();
}

final class CancelOrderAccepted extends CancelOrderResult {
  const CancelOrderAccepted(this.outcome);

  final CancelOrderOutcome outcome;
}

final class CancelOrderDenied extends CancelOrderResult {
  const CancelOrderDenied(
    this.message, {
    this.statusCode,
    this.retryable = false,
  });

  /// Server message when one was returned, otherwise a client-side fallback.
  final String message;

  final int? statusCode;

  /// True when no response arrived or the server failed, so retrying the same
  /// reason may still succeed.
  final bool retryable;
}
