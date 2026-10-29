import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Retrieves the complete catalog for one brand.
class MenuRepository {
  MenuRepository(this._dio);

  final Dio _dio;

  static const _pageSize = 100;

  Future<List<MenuItem>> getByBrand(
    String brandId, {
    bool activeOnly = true,
  }) async {
    final items = <MenuItem>[];
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages) {
      final response = await _dio.get<Map<String, dynamic>>(
        '/menu-items/brand/$brandId',
        queryParameters: {
          'page': page,
          'limit': _pageSize,
          'activeOnly': activeOnly,
        },
      );
      final body = response.data;
      final data = body?['data'];
      final meta = body?['meta'];
      if (data is! List || meta is! Map<String, dynamic>) {
        throw const FormatException('Invalid menu-items response.');
      }

      items.addAll(
        await Future.wait(
          data.map((json) async {
            if (json is! Map<String, dynamic>) {
              throw const FormatException('Invalid menu item in response.');
            }
            return _toMenuItem(json);
          }),
        ),
      );

      final parsedTotalPages = meta['totalPages'];
      if (parsedTotalPages is! int || parsedTotalPages < 1) {
        throw const FormatException('Invalid menu-items pagination metadata.');
      }
      totalPages = parsedTotalPages;
      page++;
    }

    return items;
  }

  Future<MenuItem> _toMenuItem(Map<String, dynamic> json) async {
    final id = json['menu_item_id'];
    if (id is! String ||
        json['is_active'] == false ||
        json['menu_item_channels_menu_item'] is List) {
      return MenuItem.fromApiJson(json);
    }

    final channelRows = await _channelsForMenuItem(id);
    return MenuItem.fromApiJson({
      ...json,
      'menu_item_channels_menu_item': channelRows,
    });
  }

  Future<List<dynamic>> _channelsForMenuItem(String menuItemId) async {
    final response = await _dio.get<List<dynamic>>(
      '/menu-channels/menu-item/$menuItemId',
      queryParameters: const {'activeOnly': false},
    );
    final rows = response.data;
    if (rows is! List) {
      throw const FormatException('Invalid menu-channels response.');
    }
    return rows;
  }
}

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(dioProvider)),
);
