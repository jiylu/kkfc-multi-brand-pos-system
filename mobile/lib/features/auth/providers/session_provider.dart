import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';

/// Token restored from secure storage before runApp. main.dart overrides it.
final initialTokenProvider = Provider<String?>((ref) => null);

/// Role restored from secure storage before runApp. main.dart overrides it.
final initialRoleProvider = Provider<UserRole?>((ref) => null);

class UserRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => ref.watch(initialRoleProvider);

  void setRole(UserRole? role) {
    state = role;
  }

  void clear() {
    state = null;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole?>(
  UserRoleNotifier.new,
);

class SessionTokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialTokenProvider);

  void setToken(String? token) {
    state = token;
    if (token != null) {
      ref.read(sessionExpiredProvider.notifier).set(false);
    } else {
      ref.read(userRoleProvider.notifier).clear();
    }
  }

  /// Called when the server rejects [rejectedToken].
  /// Does nothing if the session has since changed.
  void expire(String rejectedToken) {
    if (state != rejectedToken) return;

    ref.read(sessionExpiredProvider.notifier).set(true);
    ref.read(userRoleProvider.notifier).clear();
    state = null;
    unawaited(ref.read(tokenStoreProvider).clear().catchError((_) {}));
  }
}

final sessionTokenProvider = NotifierProvider<SessionTokenNotifier, String?>(
  SessionTokenNotifier.new,
);

/// True while a token is held. The router redirect reads this.
final sessionProvider = Provider<bool>(
  (ref) => ref.watch(sessionTokenProvider) != null,
);

/// Asynchronously resolves the user's role from `/auth/me` if not set yet.
final userRoleInitializerProvider = FutureProvider<UserRole?>((ref) async {
  final isLoggedIn = ref.watch(sessionProvider);
  if (!isLoggedIn) return null;

  final currentRole = ref.read(userRoleProvider);
  if (currentRole != null) return currentRole;

  try {
    final role = await ref.read(authRepositoryProvider).getCurrentUserRole();
    if (role != null) {
      ref.read(userRoleProvider.notifier).setRole(role);
    }
    return role;
  } catch (_) {
    return null;
  }
});

/// True after the server rejected the token, so the login screen can say why.
class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(
  SessionExpiredNotifier.new,
);
