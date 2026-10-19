import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(LoginLayout.minControlHeight),
        // Keep the navy look while loading, like the design.
        disabledBackgroundColor: scheme.primary,
        disabledForegroundColor: scheme.onPrimary,
      ),
      child: AnimatedSwitcher(
        duration: LoginLayout.motion(context, LoginLayout.fast),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: LoginLayout.spinnerSize,
                    height: LoginLayout.spinnerSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: LoginLayout.gapSm),
                  const Text('Signing in…'),
                ],
              )
            : const Text('Sign in', key: ValueKey('idle')),
      ),
    );
  }
}