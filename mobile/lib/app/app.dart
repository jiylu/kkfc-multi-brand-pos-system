import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/session_provider.dart';
import 'router.dart';
import './theme/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userRoleInitializerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KKFC POS',
      theme: counterTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
