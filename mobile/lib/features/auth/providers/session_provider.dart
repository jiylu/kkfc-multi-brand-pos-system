import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Token restored from secure storage before runApp. main.dart overrides it.
final initialTokenProvider = Provider<String?>((ref) => null);

class SessionTokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialTokenProvider);

  void setToken(String? token) => state = token;
}

final sessionTokenProvider =
    NotifierProvider<SessionTokenNotifier, String?>(SessionTokenNotifier.new);

/// True while a token is held. The router redirect reads this.
final sessionProvider =
    Provider<bool>((ref) => ref.watch(sessionTokenProvider) != null);