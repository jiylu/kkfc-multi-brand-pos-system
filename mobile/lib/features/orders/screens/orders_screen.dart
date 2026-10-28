import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KkfcScaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          TextButton.icon(
            onPressed: () => _signOut(ref),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= MenuLayout.compactMax;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRail) const MenuRail(),
              Expanded(
                child: Column(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Orders'),
                            SizedBox(height: MenuSpace.md),
                            _CancelOrderEntry(),
                          ],
                        ),
                      ),
                    ),
                    if (!showRail) const MenuBottomNav(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ends the server session in the background, then clears the local session.
  /// The router watches [sessionProvider] and redirects to the login screen.
  void _signOut(WidgetRef ref) {
    final token = ref.read(sessionTokenProvider);
    if (token == null) return;

    unawaited(ref.read(authRepositoryProvider).logout(token));
    ref.read(sessionExpiredProvider.notifier).set(false);
    ref.read(sessionTokenProvider.notifier).setToken(null);
  }
}

/// Prototype entry point into the cancel-order workflow. The order list is not
/// implemented yet, so QA opens the cancel screens from here.
class _CancelOrderEntry extends StatelessWidget {
  const _CancelOrderEntry();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(AppRoutes.cancelOrder),
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Open cancel order (prototype)'),
    );
  }
}
