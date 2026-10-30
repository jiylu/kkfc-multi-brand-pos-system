import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/session_provider.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/new_order/presentation/pages/channel_repricing_screen.dart';
import '../features/new_order/presentation/pages/menu_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/availability/presentation/pages/availability_read_only_screen.dart';
import '../features/order_entry/data/models/order_confirmed_view_data.dart';
import '../features/order_entry/data/models/order_not_sent_view_data.dart';
import '../features/order_entry/data/models/duplicate_platform_order_view_data.dart';
import '../features/order_entry/data/models/order_entry_view_data.dart';
import '../features/order_entry/presentation/pages/order_confirmed_screen.dart';
import '../features/order_entry/presentation/pages/order_not_sent_screen.dart';
import '../features/order_entry/presentation/pages/duplicate_platform_order_screen.dart';
import '../features/order_entry/presentation/pages/order_entry_screen.dart';
import '../features/order_entry/presentation/pages/platform_reference_screen.dart';
import '../features/orders/cancel/presentation/pages/cancel_order_screen.dart';
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
        builder: (context, state) {
          // Live mode is opt-in: /orders/cancel?orderId=<uuid>[&orderCode=GC-00001]
          // Without orderId the screen runs the demo states with sample data.
          final query = state.uri.queryParameters;
          return CancelOrderScreen(
            orderId: query['orderId'],
            orderCode: query['orderCode'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.availability,
        builder: (context, state) => const AvailabilityReadOnlyScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderEntry,
        builder: (context, state) {
          final data = state.extra;
          return data is OrderEntryViewData
              ? OrderEntryScreen(data: data)
              : const OrderEntryScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.orderConfirmed,
        builder: (context, state) {
          final data = state.extra;
          return OrderConfirmedScreen(
            data: data is OrderConfirmedViewData
                ? data
                : OrderConfirmedViewData.sample,
            onNewOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderNotSent,
        builder: (context, state) {
          final data = state.extra;
          return OrderNotSentScreen(
            data: data is OrderNotSentViewData
                ? data
                : OrderNotSentViewData.sample,
            onEditOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.duplicatePlatformOrder,
        builder: (context, state) {
          final data = state.extra;
          return DuplicatePlatformOrderScreen(
            data: data is DuplicatePlatformOrderViewData
                ? data
                : DuplicatePlatformOrderViewData.sample,
            onBackToOrder: () => context.go(AppRoutes.menu),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.platformReference,
        builder: (context, state) => const PlatformReferenceScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
