import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/auth/token_store.dart';
import 'features/auth/providers/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final savedToken = await _readSavedToken();

  runApp(
    ProviderScope(
      overrides: [initialTokenProvider.overrideWithValue(savedToken)],
      child: const App(),
    ),
  );
}

Future<String?> _readSavedToken() async {
  try {
    return await TokenStore().read();
  } catch (_) {
    // Unreadable storage shouldn't block launch. The user signs in again.
    return null;
  }
}