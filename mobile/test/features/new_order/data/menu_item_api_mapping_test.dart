import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'maps the brand menu response and its channel overrides to a menu card',
    () {
      final item = MenuItem.fromApiJson({
        'menu_item_id': 'item-1',
        'name': 'Chicken Inasal',
        'description': null,
        'base_price': '189.50',
        'is_available': true,
        'menu_item_channels_menu_item': [
          {
            'order_channel': 'GRABFOOD',
            'price': '219.00',
            'is_available': true,
          },
          {'order_channel': 'FOODPANDA', 'price': 225, 'is_available': false},
        ],
      });

      expect(item.id, 'item-1');
      expect(item.description, isEmpty);
      expect(item.priceFor(MenuChannel.dineIn), 18950);
      expect(item.priceFor(MenuChannel.takeaway), 18950);
      expect(item.priceFor(MenuChannel.grabFood), 21900);
      expect(item.priceFor(MenuChannel.foodpanda), 22500);
      expect(
        item.availabilityFor(MenuChannel.grabFood),
        MenuAvailability.available,
      );
      expect(
        item.availabilityFor(MenuChannel.foodpanda),
        MenuAvailability.manualOff,
      );
      expect(item.channels, {
        MenuChannel.dineIn,
        MenuChannel.takeaway,
        MenuChannel.grabFood,
        MenuChannel.foodpanda,
      });
    },
  );

  test('MenuRepository loads per-item channel overrides from /menu-channels/menu-item/:id', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((options) {
      if (options.path == '/menu-items/brand/brand-1') {
        return ResponseBody.fromString(
          '{"data":[{"menu_item_id":"item-1","name":"Paa Inasal","description":"Grilled","base_price":"179.00","is_available":true}],"meta":{"page":1,"limit":100,"total":1,"totalPages":1}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      if (options.path == '/menu-channels/menu-item/item-1' &&
          options.queryParameters['activeOnly'] == false) {
        return ResponseBody.fromString(
          '[{"order_channel":"GRABFOOD","price":"205.00","is_available":true}]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      throw StateError('Unexpected request: ${options.path}');
    });

    final repository = MenuRepository(dio);
    final items = await repository.getByBrand('brand-1');

    expect(items, hasLength(1));
    expect(items.single.priceFor(MenuChannel.dineIn), 17900);
    expect(items.single.priceFor(MenuChannel.takeaway), 17900);
    expect(items.single.priceFor(MenuChannel.grabFood), 20500);
    expect(items.single.channels, {
      MenuChannel.dineIn,
      MenuChannel.takeaway,
      MenuChannel.grabFood,
    });
  });

  test('MenuRepository includes inactive items without loading their channel overrides', () async {
    var channelLoads = 0;
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter((options) {
      if (options.path == '/menu-items/brand/brand-1') {
        expect(options.queryParameters['activeOnly'], false);
        return ResponseBody.fromString(
          '{"data":['
          '{"menu_item_id":"item-active","name":"Paa Inasal","description":"Grilled","base_price":"179.00","is_available":true,"is_active":true},'
          '{"menu_item_id":"item-inactive","name":"Batchoy Special","description":"Noodles","base_price":"149.00","is_available":true,"is_active":false}'
          '],"meta":{"page":1,"limit":100,"total":2,"totalPages":1}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      if (options.path == '/menu-channels/menu-item/item-active') {
        channelLoads++;
        expect(options.queryParameters['activeOnly'], false);
        return ResponseBody.fromString(
          '[{"order_channel":"GRABFOOD","price":"205.00","is_available":true}]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      throw StateError('Unexpected request: ${options.path}');
    });

    final items = await MenuRepository(dio)
        .getByBrand('brand-1', activeOnly: false);

    expect(channelLoads, 1);
    expect(items, hasLength(2));

    final active = items.firstWhere((item) => item.id == 'item-active');
    expect(
      active.availabilityFor(MenuChannel.grabFood),
      MenuAvailability.available,
    );

    final inactive = items.firstWhere((item) => item.id == 'item-inactive');
    for (final channel in MenuChannel.values) {
      expect(inactive.availabilityFor(channel), MenuAvailability.inactive);
    }
  });
}
