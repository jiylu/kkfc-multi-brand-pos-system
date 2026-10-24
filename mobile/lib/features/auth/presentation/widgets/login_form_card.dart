import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/presentation/widgets/login_layout.dart';
import 'package:mobile/features/auth/presentation/widgets/login_notice.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'package:mobile/features/auth/presentation/widgets/login_text_field.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.status,
    required this.onSubmit,
    required this.onEdited,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final LoginStatus status;
  final VoidCallback onSubmit;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final compact = LoginLayout.isCompact(context);
    final enabled = !status.isSubmitting;
    final pad = compact ? LoginLayout.gapLg : LoginLayout.gapXl;
    final accent = context.semanticColors.highlights;

    return Container(
      padding: EdgeInsets.all(compact ? LoginLayout.gapLg : LoginLayout.gapXl),
      decoration: BoxDecoration(
        color: scheme.onPrimary,
        borderRadius: BorderRadius.circular(LoginLayout.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant,
          width: LoginLayout.borderWidth,
        ),
      ),
      child: AutofillGroup(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STAFF SIGN IN',
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: LoginLayout.gapXs),
                Text('Welcome back', style: text.headlineMedium),
                const SizedBox(height: LoginLayout.gapXs),
                Text(
                  'Sign in with your own staff account.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LoginLayout.gapLg),
                LoginTextField(
                  label: 'Username',
                  hint: 'Enter username',
                  controller: usernameController,
                  enabled: enabled,
                  hasError: status.fieldsInError,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  onChanged: (_) => onEdited(),
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: LoginLayout.gapMd),
                LoginPasswordField(
                  controller: passwordController,
                  enabled: enabled,
                  hasError: status.fieldsInError,
                  onChanged: (_) => onEdited(),
                  onSubmitted: (_) => onSubmit(),
                ),
                LoginNotice(status: status),
                const SizedBox(height: LoginLayout.gapLg),
                KkfcLoadingButton(
                  label: 'Sign in',
                  loadingLabel: 'Signing in…',
                  isLoading: status.isSubmitting,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: LoginLayout.gapMd),
                Center(
                  child: Text(
                    'Your actions are recorded under your account.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: LoginLayout.gapLg),
                Divider(
                  height: LoginLayout.borderWidth,
                  color: scheme.outlineVariant,
                ),
                const SizedBox(height: LoginLayout.gapMd),
                Text(
                  'SECURE STAFF WORKSPACE',
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: LoginLayout.gapXs),
                Text(
                  'One account per person · Sign out before switching staff.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Positioned(
              left: -pad,
              top: 0,
              child: _AccentBar(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  const _AccentBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: LoginLayout.accentBarHeight),
      duration: LoginLayout.motion(context, LoginLayout.slow),
      curve: LoginLayout.curve,
      builder: (context, height, _) => Container(
        width: LoginLayout.accentBarWidth,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(LoginLayout.accentBarWidth),
          ),
        ),
      ),
    );
  }
}
