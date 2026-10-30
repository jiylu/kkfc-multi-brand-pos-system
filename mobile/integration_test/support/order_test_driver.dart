import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/login_notice.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

const orderUsername = String.fromEnvironment('TEST_USERNAME');
const orderPassword = String.fromEnvironment('TEST_PASSWORD');
const orderBrandId = String.fromEnvironment('POS_BRAND_ID');
const orderItemId = String.fromEnvironment('POS_MENU_ITEM_ID');
const unavailableOrderItemId = String.fromEnvironment(
  'POS_UNAVAILABLE_ITEM_ID',
);

void requireOrderFixtures() {
  if (AppConfig.env != 'test' ||
      !const bool.hasEnvironment('API_URL') ||
      [
        orderUsername,
        orderPassword,
        orderBrandId,
        orderItemId,
        const String.fromEnvironment('POS_MANAGER_USERNAME'),
      ].any((s) => s.isEmpty)) {
    throw StateError(
      'Prepare mobile-pos-fixtures.ts prepare --orders and use .fixtures/order-flow.json with ENV=test.',
    );
  }
}

Dio orderApi([String? token]) => Dio(
  BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: {if (token != null) 'Authorization': 'Bearer $token'},
    validateStatus: (_) => true,
  ),
);

Finder orderMenuItem(String id) =>
    find.byWidgetPredicate((w) => w is MenuItemCard && w.item.id == id);

Future<void> waitForOrderUi(
  WidgetTester tester,
  bool Function() ready,
  String reason,
) async {
  final watch = Stopwatch()..start();
  while (!ready() && watch.elapsed < const Duration(seconds: 45)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue, reason: 'Timed out waiting for $reason.');
  await tester.pumpAndSettle();
}

Future<void> orderTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> loginForOrders(WidgetTester tester) async {
  final store = TokenStore();
  addTearDown(() async {
    final token = await store.read();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    final api = orderApi(token);
    try {
      if (token != null) {
        expect((await api.post<void>('/auth/logout')).statusCode, 204);
      }
    } finally {
      api.close(force: true);
      await store.clear();
    }
  });
  await store.clear();
  await app.main();
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
  final username = find.byType(TextField).first;
  final password = find.byType(TextField).last;
  await tester.ensureVisible(username);
  await tester.enterText(username, orderUsername);
  await tester.ensureVisible(password);
  await tester.enterText(password, orderPassword);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await orderTap(tester, find.byType(KkfcLoadingButton));
  await waitForOrderUi(
    tester,
    () =>
        find.byType(MenuScreen).evaluate().isNotEmpty ||
        find
            .byType(LoginNotice)
            .evaluate()
            .any((e) => (e.widget as LoginNotice).status.hasNotice),
    'login',
  );
  expect(find.byType(MenuScreen), findsOneWidget);
  final container = ProviderScope.containerOf(tester.element(find.byType(App)));
  await waitForOrderUi(
    tester,
    () =>
        orderMenuItem(orderItemId).evaluate().isNotEmpty &&
        find
            .byWidgetPredicate(
              (w) => w is BrandLogo && w.brand.id == orderBrandId,
            )
            .evaluate()
            .isNotEmpty,
    'real API brand and menu',
  );
  expect(container.read(activeBrandProvider).id, orderBrandId);
  expect(container.read(cartProvider), isEmpty);
  return container;
}

/// Backend-only scenarios authenticate directly, without rendering unrelated UI.
Future<(Dio, String)> loginForOrderApi() async {
  final api = orderApi();
  String? token;
  addTearDown(() async {
    try {
      if (token != null) {
        expect((await api.post('/auth/logout')).statusCode, 204);
      }
    } finally {
      api.close(force: true);
    }
  });
  final response = await api.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'username': orderUsername, 'password': orderPassword},
  );
  expect(response.statusCode, 200, reason: '${response.data}');
  token = response.data!['token'] as String;
  api.options.headers['Authorization'] = 'Bearer $token';
  final brand = await api.get<Map<String, dynamic>>('/brands/$orderBrandId');
  expect(brand.statusCode, 200, reason: '${brand.data}');
  expect(brand.data!['brand_id'], orderBrandId);
  return (api, (brand.data!['code'] as String).trim());
}

Dio authenticatedOrderApi(ProviderContainer container) {
  final api = orderApi(container.read(sessionTokenProvider));
  addTearDown(() => api.close(force: true));
  return api;
}

Future<void> openOrderCart(WidgetTester tester) async {
  if (find.byType(CartPanel).evaluate().isEmpty) {
    await orderTap(tester, find.text('View cart'));
  }
  expect(find.byType(CartPanel), findsOneWidget);
}

Future<void> fillOrderReference(WidgetTester tester, String reference) async {
  await openOrderCart(tester);
  final field = find.descendant(
    of: find.byType(CartPanel),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, reference);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}
