import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Loads the add-ons assigned to a menu item.
///
/// `GET /menu-item-modifiers/menu-item/:id` returns only the assignment rows
/// (`menu_item_modifier_id`, `modifier_id`, `additional_price`), so each row's
/// display name is resolved with `GET /menu-item-modifiers/:id`.
class MenuItemModifierRepository {
  MenuItemModifierRepository(this._dio);

  final Dio _dio;

  Future<List<ModifierGroup>> getForMenuItem(String menuItemId) async {
    final response = await _dio.get<List<dynamic>>(
      '/menu-item-modifiers/menu-item/$menuItemId',
    );
    final rows = response.data;
    if (rows is! List) {
      throw const FormatException('Invalid menu-item-modifiers response.');
    }

    return Future.wait(
      rows.map((row) async {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Invalid menu item modifier in response.');
        }
        final id = row['menu_item_modifier_id'];
        final price = row['additional_price'];
        if (id is! String || price == null) {
          throw const FormatException('Menu item modifier is missing fields.');
        }
        return ModifierGroup.addOn(
          id: id,
          name: await _nameOf(id),
          priceCentavos: decimalToCentavos(price),
        );
      }),
    );
  }

  Future<String> _nameOf(String menuItemModifierId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/menu-item-modifiers/$menuItemModifierId',
    );
    final details = response.data?['modifierDetails'];
    final name = details is Map<String, dynamic> ? details['name'] : null;
    if (name is! String) {
      throw const FormatException('Modifier details are missing a name.');
    }
    return name;
  }
}

final menuItemModifierRepositoryProvider = Provider<MenuItemModifierRepository>(
  (ref) => MenuItemModifierRepository(ref.watch(dioProvider)),
);
