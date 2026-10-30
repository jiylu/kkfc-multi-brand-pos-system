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
                        child: Padding(
                          padding: EdgeInsets.all(MenuSpace.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Orders'),
                              SizedBox(height: MenuSpace.sm),
                              _OrdersUnavailableNote(),
                              SizedBox(height: MenuSpace.md),
                              _CancelOrderEntry(),
                              SizedBox(height: MenuSpace.sm),
                              _CancelLiveOrderEntry(),
                            ],
                          ),
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

/// The order list endpoint does not exist yet, so the screen says so instead of
/// showing rows that cannot be loaded.
class _OrdersUnavailableNote extends StatelessWidget {
  const _OrdersUnavailableNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'There is no order list API yet, so the demo uses sample data. A live '
      'cancellation needs the order UUID.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Prototype entry point into the cancel-order workflow. The order list is not
/// implemented yet, so QA opens the demo screens from here.
class _CancelOrderEntry extends StatelessWidget {
  const _CancelOrderEntry();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(AppRoutes.cancelOrder),
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Open cancel order (demo)'),
    );
  }
}

/// QA bridge to the live cancellation endpoint while the order list is missing.
/// The UUID is supplied by hand; there is no list to pick it from yet.
class _CancelLiveOrderEntry extends StatefulWidget {
  const _CancelLiveOrderEntry();

  @override
  State<_CancelLiveOrderEntry> createState() => _CancelLiveOrderEntryState();
}

class _CancelLiveOrderEntryState extends State<_CancelLiveOrderEntry> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final orderId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel a real order'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Order UUID',
            hintText: '11111111-1111-4111-8111-111111111111',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_controller.text.trim()),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (!mounted || orderId == null || orderId.isEmpty) return;
    context.go('${AppRoutes.cancelOrder}?orderId=$orderId');
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _open,
      child: const Text('Cancel a real order (live API, QA)'),
    );
  }
}
