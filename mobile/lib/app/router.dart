import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/session_provider.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/new_order/presentation/pages/channel_repricing_screen.dart';
import '../features/new_order/presentation/pages/menu_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/cancel/presentation/pages/cancel_order_screen.dart';
import '../features/availability/presentation/pages/availability_management_screen.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ValueNotifier<bool>(ref.read(sessionProvider));
  ref.listen<bool>(sessionProvider, (_, next) => loggedIn.value = next);
  ref.onDispose(loggedIn.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: loggedIn,
    redirect: (context, state) {
      final isLoggedIn = ref.read(sessionProvider);
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !onLogin) {
        return AppRoutes.login;
      }
      if (isLoggedIn && onLogin) {
        return AppRoutes.menu;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.channelChange,
        builder: (context, state) => const ChannelRepricingScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.cancelOrder,
        builder: (context, state) => const CancelOrderScreen(),
      ),
      GoRoute(
        path: AppRoutes.availability,
        builder: (context, state) => const AvailabilityManagementScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
