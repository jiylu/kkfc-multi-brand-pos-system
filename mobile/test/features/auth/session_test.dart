import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';

class _FakeTokenStore extends TokenStore {
  bool cleared = false;

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

ProviderContainer _container(String token, _FakeTokenStore store) {
  final container = ProviderContainer(
    overrides: [
      initialTokenProvider.overrideWithValue(token),
      tokenStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('401 for the current token signs out and flags the expiry', () {
    final store = _FakeTokenStore();
    final container = _container('abc', store);

    container.read(sessionTokenProvider.notifier).expire('abc');

    expect(container.read(sessionProvider), isFalse);
    expect(container.read(sessionExpiredProvider), isTrue);
    expect(store.cleared, isTrue);
  });

  test('a late 401 for an older token does not sign out the new session', () {
    final store = _FakeTokenStore();
    final container = _container('new-token', store);

    container.read(sessionTokenProvider.notifier).expire('old-token');

    expect(container.read(sessionProvider), isTrue);
    expect(container.read(sessionExpiredProvider), isFalse);
    expect(store.cleared, isFalse);
  });

  test('signing in again clears the expired flag', () {
    final store = _FakeTokenStore();
    final container = _container('abc', store);
    final notifier = container.read(sessionTokenProvider.notifier);

    notifier.expire('abc');
    notifier.setToken('def');

    expect(container.read(sessionProvider), isTrue);
    expect(container.read(sessionExpiredProvider), isFalse);
  });
}
