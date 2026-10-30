import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/user_role.dart';
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
import '../roles/kitchen_staff/features/kitchen_tickets/presentation/pages/kitchen_tickets_page.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_tickets_view_state.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<bool>(sessionProvider, (_, __) => refresh.value++);
  ref.listen<UserRole?>(userRoleProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = ref.read(sessionProvider);
      final role = ref.read(userRoleProvider);
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !onLogin) {
        return AppRoutes.login;
      }

      final isKitchenRole = role?.isKitchen ?? false;
      final onKitchenPage = state.matchedLocation == AppRoutes.kitchenTickets;

      if (isLoggedIn && onLogin) {
        return isKitchenRole ? AppRoutes.kitchenTickets : AppRoutes.menu;
      }

      if (isLoggedIn) {
        // Kitchen staff / kitchen head can only see the kitchen tickets page.
        if (isKitchenRole && !onKitchenPage) {
          return AppRoutes.kitchenTickets;
        }

        // Users without kitchen role must never see the kitchen tickets page.
        if (!isKitchenRole && onKitchenPage) {
          return AppRoutes.menu;
        }
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
      GoRoute(
        path: AppRoutes.kitchenTickets,
        builder: (context, state) => const KitchenTicketsPage(viewState: KitchenTicketsViewState.active),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
