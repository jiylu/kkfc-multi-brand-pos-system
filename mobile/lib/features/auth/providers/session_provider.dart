import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionNotifier extends Notifier<bool> {
  @override
  bool build() => false; // logged out by default

  void setLoggedIn(bool value) => state = value;
}

final sessionProvider = NotifierProvider<SessionNotifier, bool>(
  SessionNotifier.new,
);