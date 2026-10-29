import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/login_notice.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_field.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

// These credentials belong to server/prisma/seed-test.ts, never real staff.
const _username = String.fromEnvironment(
  'TEST_USERNAME',
  defaultValue: 'test_order_staff',
);
const _password = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: 'Password123!',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (AppConfig.env != 'test' || AppConfig.rawApiUrl.trim().isEmpty) {
      throw StateError('Run with ENV=test and an explicit test API_URL.');
    }
    if (!const bool.hasEnvironment('API_URL')) {
      throw StateError('API_URL must explicitly point to the test backend.');
    }
  });

  testWidgets('IT-MOB-AUTH-001 valid credentials create a real API session', (
    tester,
  ) async {
    await _launchSignedOut(tester);
    await _signIn(tester, password: _password);
    await _waitUntil(
      tester,
      () => find.byType(MenuScreen).evaluate().isNotEmpty || _hasNotice(tester),
      'a menu screen or a login error',
    );

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    final token = container.read(sessionTokenProvider);
    expect(token, isNotNull);
    expect(token, isNotEmpty);
    expect(await TokenStore().read(), token);

    // Navigation alone is insufficient: the real API must accept this token.
    final client = _api();
    try {
      final response = await client.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(response.statusCode, 200);
      expect(response.data?['username'], _username);
    } finally {
      client.close(force: true);
    }
  });

  testWidgets('IT-MOB-AUTH-002 wrong password shows invalid credentials', (
    tester,
  ) async {
    await _launchSignedOut(tester);
    await _signIn(tester, password: '${_password}wrong');
    await _waitUntil(tester, () => _hasNotice(tester), 'a login error');

    expect(
      tester.widget<LoginNotice>(find.byType(LoginNotice)).status,
      LoginStatus.invalidCredentials,
      reason: 'A network error must fail this test, not count as a rejection.',
    );
    expect(
      find.text(LoginStatus.invalidCredentials.noticeMessage),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MenuScreen), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    expect(container.read(sessionTokenProvider), isNull);
    expect(await TokenStore().read(), isNull);
    expect(
      tester
          .widget<KkfcLoadingButton>(find.byType(KkfcLoadingButton))
          .isLoading,
      isFalse,
    );
  });
}

Dio _api() => Dio(
  BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
  ),
);

Future<void> _launchSignedOut(WidgetTester tester) async {
  final store = TokenStore();
  // Always clean up a session created by this test, including on assertion failure.
  addTearDown(() async {
    final token = await store.read();
    await tester.pumpWidget(const SizedBox.shrink());
    final client = _api();
    try {
      if (token != null) {
        final response = await client.post<void>(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        expect(response.statusCode, 204);
      }
    } finally {
      client.close(force: true);
      await store.clear();
    }
  });
  await store.clear();
  await app.main();
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);
}

Future<void> _signIn(WidgetTester tester, {required String password}) async {
  final usernameField = find.byType(TextField).first;
  final passwordField = find.descendant(
    of: find.byType(LoginPasswordField),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(usernameField);
  await tester.enterText(usernameField, _username);
  await tester.ensureVisible(passwordField);
  await tester.enterText(passwordField, password);
  // Dismiss the keyboard so the submit button remains tappable on phones.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final submit = find.byType(KkfcLoadingButton);
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();
}

bool _hasNotice(WidgetTester tester) =>
    find.byType(LoginNotice).evaluate().isNotEmpty &&
    tester.widget<LoginNotice>(find.byType(LoginNotice)).status.hasNotice;

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  final clock = Stopwatch()..start();
  // Real HTTP continues between frames; pumpAndSettle alone can finish before it.
  while (!condition() && clock.elapsed < const Duration(seconds: 45)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for $description.');
  await tester.pumpAndSettle();
}
