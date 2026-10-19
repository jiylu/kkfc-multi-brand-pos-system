import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/orders/screens/orders_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio(), TokenStore());

  final logoutTokens = <String>[];

  @override
  Future<void> logout(String token) async {
    logoutTokens.add(token);
  }
}

Future<ProviderContainer> _pumpOrders(
  WidgetTester tester,
  _FakeAuthRepository repo, {
  String? token,
  bool expired = false,
}) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);

  if (token != null) {
    container.read(sessionTokenProvider.notifier).setToken(token);
  }
  if (expired) {
    container.read(sessionExpiredProvider.notifier).set(true);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: counterTheme, home: const OrdersScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('logout ends the server session and clears the local session', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    final container = await _pumpOrders(
      tester,
      repo,
      token: 'tok-abc',
      expired: true,
    );

    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(container.read(sessionTokenProvider), isNull);
    expect(container.read(sessionProvider), isFalse);
    expect(container.read(sessionExpiredProvider), isFalse);
    expect(repo.logoutTokens, ['tok-abc']);
  });

  testWidgets('logout does nothing when already signed out', (tester) async {
    final repo = _FakeAuthRepository();
    final container = await _pumpOrders(tester, repo);

    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(container.read(sessionTokenProvider), isNull);
    expect(repo.logoutTokens, isEmpty);
  });
}
