import 'package:flutter/material.dart';
import 'package:mobile/features/auth/presentation/widgets/login_layout.dart';

class LoginTopBar extends StatelessWidget {
  const LoginTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final compact = LoginLayout.isCompact(context);

    return Material(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LoginLayout.gapLg,
          vertical: LoginLayout.gapMd,
        ),
        child: Row(
          children: [
            Text(
              'KKFC POS',
              style: text.titleMedium?.copyWith(color: scheme.onPrimary),
            ),
            const Spacer(),
            if (!compact)
              Text(
                'STAFF ACCESS · GC / AI / KK',
                style: text.labelMedium?.copyWith(
                  color: scheme.onPrimary.withValues(
                    alpha: LoginLayout.softAlpha,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
