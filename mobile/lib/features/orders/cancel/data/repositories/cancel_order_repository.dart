import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';

/// Sends cancellation requests to
/// `POST /brands/:brandId/orders/:orderId/cancel`.
///
/// The endpoint requires a nonblank `cancellation_reason` (max 1000
/// characters), derives the actor from the session, and returns the saved order.
/// Retrying an already-cancelled order returns its original cancellation.
class CancelOrderRepository {
  CancelOrderRepository(this._dio);

  final Dio _dio;

  Future<CancelOrderResult> cancel({
    required String brandId,
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/brands/$brandId/orders/$orderId/cancel',
        data: {'cancellation_reason': reason.trim()},
      );

      final body = response.data;
      if (body == null) {
        return const CancelOrderDenied(
          'The server returned an empty cancellation response.',
          retryable: true,
        );
      }

      return CancelOrderAccepted(CancelOrderOutcome.fromJson(body));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      return CancelOrderDenied(
        _message(error),
        statusCode: statusCode,
        // No response, or a server-side failure: the cancellation may or may
        // not have committed, so retrying with the same reason is safe.
        retryable: statusCode == null || statusCode >= 500,
      );
    } on FormatException catch (error) {
      return CancelOrderDenied(error.message, retryable: true);
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }

    if (error.response == null) {
      return 'Could not reach the server. Recheck the order status before '
          'trying again.';
    }

    return switch (error.response?.statusCode) {
      401 => 'Your session expired. Sign in again.',
      403 => 'Your role cannot cancel this order.',
      404 => 'Order not found for this brand.',
      409 => 'Completed orders or handed-over tickets cannot be cancelled.',
      _ => 'The server rejected the cancellation.',
    };
  }
}

final cancelOrderRepositoryProvider = Provider<CancelOrderRepository>(
  (ref) => CancelOrderRepository(ref.watch(dioProvider)),
);
