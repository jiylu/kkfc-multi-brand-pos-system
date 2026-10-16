import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/session_provider.dart';
import '../features/auth/screens/temp_login_screen.dart';
import '../shared/widgets/placeholder_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider);
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !onLogin) return AppRoutes.login;
      if (loggedIn && onLogin) return AppRoutes.orders;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const PlaceholderScreen(title: 'Orders'),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});