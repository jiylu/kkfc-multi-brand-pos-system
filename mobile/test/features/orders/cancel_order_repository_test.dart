import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';

/// Captures the outgoing request and hands the encoded body to [respond].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(String? body) respond;
  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? body;
    if (requestStream != null) {
      final buffer = <int>[];
      await for (final chunk in requestStream) {
        buffer.addAll(chunk);
      }
      body = utf8.decode(buffer);
    }

    lastRequest = options;
    lastBody = body;
    return respond(body);
  }

  @override
  void close({bool force = false}) {}
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

CancelOrderRepository _repo(HttpClientAdapter adapter) => CancelOrderRepository(
  Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))..httpClientAdapter = adapter,
);

const _uuid = '11111111-1111-4111-8111-111111111111';

void main() {
  test('posts the trimmed reason and parses the cancelled order', () async {
    final adapter = _FakeAdapter(
      (_) async => _json({
        'order_id': _uuid,
        'order_code': 'GC-00007',
        'status': 'CANCELLED',
        'cancellation_reason': 'Customer changed their mind.',
        'cancelled_at': '2026-10-30T02:05:00.000Z',
        'kitchen_tickets_order': {'status': 'CANCELLED'},
      }),
    );

    final result = await _repo(adapter).cancel(
      brandId: 'brand-1',
      orderId: _uuid,
      reason: '  Customer changed their mind.  ',
    );

    expect(result, isA<CancelOrderAccepted>());
    final outcome = (result as CancelOrderAccepted).outcome;
    expect(outcome.orderId, _uuid);
    expect(outcome.orderCode, 'GC-00007');
    expect(outcome.isCancelled, isTrue);
    expect(outcome.cancellationReason, 'Customer changed their mind.');
    expect(outcome.cancelledAt, DateTime.parse('2026-10-30T02:05:00.000Z'));
    expect(outcome.ticketLabel, 'Ticket CANCELLED');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(
      request.uri.toString(),
      'http://localhost:3000/api/brands/brand-1/orders/$_uuid/cancel',
    );
    expect(jsonDecode(adapter.lastBody!), {
      'cancellation_reason': 'Customer changed their mind.',
    });
  });

  test('an unpaid draft reports that no kitchen ticket existed', () async {
    final adapter = _FakeAdapter(
      (_) async => _json({
        'order_id': _uuid,
        'status': 'CANCELLED',
        'cancelled_at': null,
        'kitchen_tickets_order': null,
      }),
    );

    final result = await _repo(adapter)
        .cancel(brandId: 'brand-1', orderId: _uuid, reason: 'Duplicate order.');

    final outcome = (result as CancelOrderAccepted).outcome;
    expect(outcome.ticketStatus, isNull);
    expect(outcome.ticketLabel, 'No kitchen ticket');
    expect(outcome.cancelledAt, isNull);
  });

  test('a 409 keeps the server message and is not retryable', () async {
    final adapter = _FakeAdapter(
      (_) async => _json({
        'statusCode': 409,
        'message':
            'Completed orders or handed-over tickets cannot be cancelled.',
        'error': 'Conflict',
      }, status: 409),
    );

    final result = await _repo(adapter).cancel(
      brandId: 'brand-1',
      orderId: _uuid,
      reason: 'Customer changed their mind.',
    );

    expect(result, isA<CancelOrderDenied>());
    final denied = result as CancelOrderDenied;
    expect(denied.statusCode, 409);
    expect(denied.retryable, isFalse);
    expect(
      denied.message,
      'Completed orders or handed-over tickets cannot be cancelled.',
    );
  });

  test('validation messages arrive as a string array', () async {
    final adapter = _FakeAdapter(
      (_) async => _json({
        'statusCode': 400,
        'message': ['cancellation_reason must be shorter than 1000 characters'],
        'error': 'Bad Request',
      }, status: 400),
    );

    final result = await _repo(adapter).cancel(
      brandId: 'brand-1',
      orderId: _uuid,
      reason: List.filled(999, 'x').join(),
    );

    final denied = result as CancelOrderDenied;
    expect(denied.statusCode, 400);
    expect(
      denied.message,
      'cancellation_reason must be shorter than 1000 characters',
    );
  });

  test(
    'a missing response is retryable because the write may have landed',
    () async {
      final result = await _repo(_OfflineAdapter()).cancel(
        brandId: 'brand-1',
        orderId: _uuid,
        reason: 'Customer changed their mind.',
      );

      expect(result, isA<CancelOrderDenied>());
      final denied = result as CancelOrderDenied;
      expect(denied.statusCode, isNull);
      expect(denied.retryable, isTrue);
      expect(denied.message, contains('Could not reach the server'));
    },
  );
}
