import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KkfcScaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            ref.read(sessionProvider.notifier).setLoggedIn(true);
            context.go(AppRoutes.orders);
          },
          child: const Text('Sign in (temporary)'),
        ),
      ),
    );
  }
}