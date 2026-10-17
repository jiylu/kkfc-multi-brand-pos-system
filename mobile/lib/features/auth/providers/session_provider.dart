import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/auth/token_store.dart';

/// Token restored from secure storage before runApp. main.dart overrides it.
final initialTokenProvider = Provider<String?>((ref) => null);

class SessionTokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialTokenProvider);

  void setToken(String? token) {
    state = token;
    if (token != null) {
      ref.read(sessionExpiredProvider.notifier).set(false);
    }
  }

  /// Called when the server rejects [rejectedToken].
  /// Does nothing if the session has since changed.
  void expire(String rejectedToken) {
    if (state != rejectedToken) return;

    ref.read(sessionExpiredProvider.notifier).set(true);
    state = null;
    unawaited(ref.read(tokenStoreProvider).clear().catchError((_) {}));
  }
}

final sessionTokenProvider =
    NotifierProvider<SessionTokenNotifier, String?>(SessionTokenNotifier.new);

/// True while a token is held. The router redirect reads this.
final sessionProvider =
    Provider<bool>((ref) => ref.watch(sessionTokenProvider) != null);

/// True after the server rejected the token, so the login screen can say why.
class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, bool>(SessionExpiredNotifier.new);