import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/channel_tabs.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';
import 'package:mobile/features/order_entry/presentation/pages/order_confirmed_screen.dart';
import 'package:mobile/features/order_entry/presentation/pages/order_entry_screen.dart';

import 'support/order_test_driver.dart';

const _payment = {'payment_method': 'CASH', 'payment_status': 'UNPAID'};
String get _orders => '/brands/$orderBrandId/orders';

Map<String, dynamic> _payload({
  String? id,
  String channel = 'DINE_IN',
  String? external,
  int quantity = 2,
  String? item,
}) => {
  'order_id': id ?? generateOrderId(),
  'order_channel': channel,
  if (channel == 'DINE_IN') 'table_reference': 'Integration table',
  if (channel == 'GRABFOOD') ...{
    'merchant_store_reference': 'integration-$orderBrandId',
    'external_order_reference': external ?? generateOrderId(),
  },
  'lines': [
    {'menu_item_id': item ?? orderItemId, 'quantity': quantity},
  ],
};

Future<Map<String, dynamic>> _post(
  Dio api,
  String path,
  Map<String, dynamic> body,
  int status,
) async {
  final response = await api.post<Map<String, dynamic>>(path, data: body);
  expect(response.statusCode, status, reason: '$path: ${response.data}');
  return response.data!;
}

void _assertCode(Map<String, dynamic> order, String brandCode) {
  final number = order['order_number'] as int;
  expect(number, greaterThan(0));
  expect(
    order['order_code'],
    '$brandCode-${number.toString().padLeft(5, '0')}',
  );
  expect(order['order_date'], isNotNull);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(requireOrderFixtures);

  testWidgets(
    'IT-MOB-ORD-001 UI review creates one draft; API verification and confirmation create one real ticket',
    (tester) async {
      final container = await loginForOrders(tester);
      final api = authenticatedOrderApi(container);
      await orderTap(
        tester,
        find.descendant(
          of: find.byType(ChannelTabs),
          matching: find.text('Takeaway'),
        ),
      );
      await orderTap(tester, orderMenuItem(orderItemId));
      await orderTap(tester, orderMenuItem(orderItemId));
      expect(container.read(cartTotalProvider), 25000);
      await fillOrderReference(tester, 'Integration pickup');
      await orderTap(tester, find.text('Check and send'));
      expect(find.byType(OrderEntryScreen), findsOneWidget);
      expect(find.text(formatPeso(25000)), findsWidgets);

      final capture = _observeDrafts(container.read(dioProvider));
      final send = find.text('Confirm & send');
      await tester.ensureVisible(send);
      await tester.tap(send);
      if (send.evaluate().isNotEmpty) {
        await tester.tap(send, warnIfMissed: false);
      }
      await waitForOrderUi(
        tester,
        () =>
            capture.responses.isNotEmpty &&
            find.byType(OrderConfirmedScreen).evaluate().isNotEmpty,
        'UI create response',
      );
      expect(
        capture.requests,
        hasLength(1),
        reason: 'Repeated taps must not create multiple requests.',
      );
      final draft = capture.responses.single.data as Map<String, dynamic>;
      expect(
        draft['status'],
        'DRAFT',
        reason: 'The current UI only calls create; this is not a confirmed kitchen order yet.',
      );
      expect(draft['kitchen_tickets_order'], isNull);
      expect(container.read(cartProvider), isEmpty);
      _assertCode(draft, container.read(activeBrandProvider).code);
      final id = draft['order_id'];
      final verified = await _post(api, '$_orders/$id/verify', _payment, 200);
      expect(verified['valid'], true);
      expect(verified['lines'].single['quantity'], 2);
      expect(decimalToCentavos(verified['lines'].single['unit_price']), 12500);
      final payload = Map<String, dynamic>.from(
        capture.requests.single.data as Map,
      );
      final unchanged = await _post(api, _orders, payload, 201);
      expect(unchanged['status'], 'DRAFT');
      expect(
        unchanged['kitchen_tickets_order'],
        isNull,
        reason: 'Verification must not create a ticket.',
      );
      final confirmed = await _post(api, '$_orders/$id/confirm', _payment, 200);
      expect(confirmed['status'], 'CONFIRMED');
      expect(confirmed['order_code'], draft['order_code']);
      final ticket = confirmed['kitchen_tickets_order'] as Map;
      expect(ticket['order_id'], id);
      expect(ticket['status'], 'QUEUED');
      expect(ticket['ticket_number'], matches(RegExp(r'^T-\d{3,}$')));
      final replay = await _post(api, '$_orders/$id/confirm', {
        'payment_method': 'CARD',
        'payment_status': 'PAID',
      }, 200);
      expect(
        replay['kitchen_tickets_order']['kitchen_ticket_id'],
        ticket['kitchen_ticket_id'],
      );
      expect(replay['payment_method'], 'CASH');
      expect(replay['payment_status'], 'UNPAID');
      expect((await _post(api, _orders, payload, 201))['status'], 'CONFIRMED');
    },
  );

  testWidgets(
    'IT-MOB-ORD-002 Create retries preserve identity and order codes; changed payloads conflict',
    (tester) async {
      final (api, brandCode) = await loginForOrderApi();
      final payload = _payload();
      final original = await _post(api, _orders, payload, 201);
      final replay = await _post(api, _orders, payload, 201);
      expect(replay['order_id'], original['order_id']);
      expect(replay['order_code'], original['order_code']);
      expect(
        replay['order_items_order'].single['order_item_id'],
        original['order_items_order'].single['order_item_id'],
      );
      final conflict = await _post(api, _orders, {
        ...payload,
        'lines': [
          {'menu_item_id': orderItemId, 'quantity': 3},
        ],
      }, 409);
      expect(conflict['code'], 'ORDER_ID_CONFLICT');
      final next = await _post(api, _orders, _payload(), 201);
      _assertCode(original, brandCode);
      _assertCode(next, brandCode);
      expect(next['order_id'], isNot(original['order_id']));
      if (next['order_date'] == original['order_date']) {
        expect(next['order_number'], (original['order_number'] as int) + 1);
        expect(next['order_code'], isNot(original['order_code']));
      } else {
        expect(
          next['order_number'],
          1,
          reason: 'Order numbering resets on the Manila business date.',
        );
      }
    },
  );

  testWidgets(
    'IT-MOB-ORD-003 Duplicate platform references are rejected while identical retries remain safe',
    (tester) async {
      final (api, _) = await loginForOrderApi();
      final payload = _payload(channel: 'GRABFOOD');
      final original = await _post(api, _orders, payload, 201);
      expect(original['payment_method'], 'PLATFORM_SETTLED');
      expect(original['payment_status'], 'PAID');
      expect(
        (await _post(api, _orders, payload, 201))['order_id'],
        original['order_id'],
      );
      final duplicate = await _post(api, _orders, {
        ...payload,
        'order_id': generateOrderId(),
      }, 409);
      expect(duplicate['code'], 'DUPLICATE_PLATFORM_ORDER');
      expect(duplicate['existing_order']['order_id'], original['order_id']);
      final verified = await _post(
        api,
        '$_orders/${original['order_id']}/verify',
        {},
        200,
      );
      expect(verified['valid'], true);
      final confirmed = await _post(
        api,
        '$_orders/${original['order_id']}/confirm',
        {},
        200,
      );
      expect(confirmed['status'], 'CONFIRMED');
      expect(confirmed['payment_method'], 'PLATFORM_SETTLED');
      expect(confirmed['payment_status'], 'PAID');
    },
  );

  testWidgets(
    'IT-MOB-ORD-004 Availability is rechecked by the API and a stale cart remains intact on rejection',
    (tester) async {
      final container = await loginForOrders(tester);
      final api = authenticatedOrderApi(container);
      await orderTap(tester, orderMenuItem(orderItemId));
      final payload = _payload(quantity: 1);
      final draft = await _post(api, _orders, payload, 201);
      final manager = orderApi();
      String? managerToken;
      var availabilityChanged = false;
      try {
        final login = await _post(manager, '/auth/login', {
          'username': const String.fromEnvironment('POS_MANAGER_USERNAME'),
          'password': const String.fromEnvironment('POS_MANAGER_PASSWORD'),
        }, 200);
        managerToken = login['token'] as String;
        manager.options.headers['Authorization'] = 'Bearer $managerToken';
        final changed = await manager.patch(
          '/menu-items/availability/$orderItemId',
          data: {'availability': false},
        );
        expect(changed.statusCode, 200, reason: '${changed.data}');
        availabilityChanged = true;
        final id = draft['order_id'];
        await _post(api, '$_orders/$id/verify', _payment, 400);
        await _post(api, '$_orders/$id/confirm', _payment, 400);
        final replay = await _post(api, _orders, payload, 201);
        expect(replay['status'], 'DRAFT');
        expect(replay['kitchen_tickets_order'], isNull);
        await _post(api, _orders, _payload(item: unavailableOrderItemId), 400);

        await fillOrderReference(tester, 'Availability test table');
        await orderTap(tester, find.text('Check and send'));
        final capture = _observeDrafts(container.read(dioProvider));
        await orderTap(tester, find.text('Confirm & send'));
        await waitForOrderUi(
          tester,
          () => capture.responses.isNotEmpty,
          'server availability rejection',
        );
        expect(capture.responses.single.statusCode, 400);
        expect(find.byType(OrderEntryScreen), findsOneWidget);
        expect(find.byType(OrderConfirmedScreen), findsNothing);
        expect(container.read(cartProvider).single.quantity, 1);
        expect(
          container.read(orderReferenceProvider),
          'Availability test table',
        );
      } finally {
        try {
          if (managerToken != null) {
            try {
              if (availabilityChanged) {
                final restored = await manager.patch(
                  '/menu-items/availability/$orderItemId',
                  data: {'availability': true},
                );
                expect(restored.statusCode, 200, reason: '${restored.data}');
              }
            } finally {
              expect((await manager.post('/auth/logout')).statusCode, 204);
            }
          }
        } finally {
          manager.close(force: true);
        }
      }
    },
  );
}

class _DraftCapture {
  final requests = <RequestOptions>[];
  final responses = <Response<dynamic>>[];
}

// Observe the production Dio traffic without replacing the transport or responses.
_DraftCapture _observeDrafts(Dio dio) {
  final capture = _DraftCapture();
  bool matches(RequestOptions r) => r.method == 'POST' && r.path == _orders;
  final observer = InterceptorsWrapper(
    onRequest: (r, handler) {
      if (matches(r)) capture.requests.add(r);
      handler.next(r);
    },
    onResponse: (r, handler) {
      if (matches(r.requestOptions)) capture.responses.add(r);
      handler.next(r);
    },
    onError: (e, handler) {
      if (matches(e.requestOptions) && e.response != null) {
        capture.responses.add(e.response!);
      }
      handler.next(e);
    },
  );
  dio.interceptors.add(observer);
  addTearDown(() => dio.interceptors.remove(observer));
  return capture;
}
