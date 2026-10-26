import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

void main() {
  test('maps the brand menu response and its channel overrides to a menu card', () {
    final item = MenuItem.fromApiJson({
      'menu_item_id': 'item-1',
      'name': 'Chicken Inasal',
      'description': null,
      'base_price': '189.50',
      'is_available': true,
      'menu_item_channels_menu_item': [
        {'order_channel': 'GRABFOOD', 'price': '219.00', 'is_available': true},
        {'order_channel': 'FOODPANDA', 'price': 225, 'is_available': false},
      ],
    });

    expect(item.id, 'item-1');
    expect(item.description, isEmpty);
    expect(item.priceFor(MenuChannel.dineIn), 18950);
    expect(item.priceFor(MenuChannel.takeaway), 18950);
    expect(item.priceFor(MenuChannel.grabFood), 21900);
    expect(item.priceFor(MenuChannel.foodpanda), 22500);
    expect(item.availabilityFor(MenuChannel.grabFood), MenuAvailability.available);
    expect(item.availabilityFor(MenuChannel.foodpanda), MenuAvailability.manualOff);
  });
}
