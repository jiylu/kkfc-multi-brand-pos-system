import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Retrieves the complete active catalog for one brand.
class MenuRepository {
  MenuRepository(this._dio);

  final Dio _dio;

  static const _pageSize = 100;

  Future<List<MenuItem>> getByBrand(String brandId) async {
    final items = <MenuItem>[];
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages) {
      final response = await _dio.get<Map<String, dynamic>>(
        '/menu-items/brand/$brandId',
        queryParameters: {'page': page, 'limit': _pageSize},
      );
      final body = response.data;
      final data = body?['data'];
      final meta = body?['meta'];
      if (data is! List || meta is! Map<String, dynamic>) {
        throw const FormatException('Invalid menu-items response.');
      }

      items.addAll(
        data.map((json) {
          if (json is! Map<String, dynamic>) {
            throw const FormatException('Invalid menu item in response.');
          }
          return MenuItem.fromApiJson(json);
        }),
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
}

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(dioProvider)),
);
