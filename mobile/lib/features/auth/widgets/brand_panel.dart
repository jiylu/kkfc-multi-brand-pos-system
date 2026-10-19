import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/brand_strip.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One kitchen. Three brands.',
            style: text.headlineSmall?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: LoginLayout.gapXs),
          Text(
            'Sign in to your shared workspace.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: LoginLayout.gapMd),
          const BrandStrip(),
        ],
      );
    }

    final soft = scheme.onPrimary.withValues(alpha: LoginLayout.softAlpha);

    return Container(
      padding: const EdgeInsets.all(LoginLayout.gapXl),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(LoginLayout.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ONE SHARED WORKSPACE',
              style: text.labelSmall?.copyWith(color: soft)),
          const SizedBox(height: LoginLayout.gapMd),
          Text(
            'One kitchen.\nThree brands.\nOne workspace.',
            style: text.displaySmall?.copyWith(color: scheme.onPrimary),
          ),
          const SizedBox(height: LoginLayout.gapMd),
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: LoginLayout.panelCopyMaxWidth),
            child: Text(
              'Confident orders, clear kitchen handoffs, and one connected team.',
              style: text.bodyLarge?.copyWith(color: soft),
            ),
          ),
          const SizedBox(height: LoginLayout.gapXl),
          const _FlowSteps(),
          const Spacer(),
          const SizedBox(height: LoginLayout.gapXl),
          const BrandStrip(),
        ],
      ),
    );
  }
}

class _FlowSteps extends StatelessWidget {
  const _FlowSteps();

  static const _steps = ['ORDER', 'PREPARE', 'CHECK', 'HANDOVER'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final soft = scheme.onPrimary.withValues(alpha: LoginLayout.softAlpha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: LoginLayout.borderWidth,
          color: scheme.onPrimary.withValues(alpha: LoginLayout.lineAlpha),
        ),
        const SizedBox(height: LoginLayout.gapMd),
        Wrap(
          spacing: LoginLayout.gapSm,
          runSpacing: LoginLayout.gapXs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0)
                Icon(Icons.arrow_right_alt, size: LoginLayout.iconSm, color: soft),
              Text(_steps[i],
                  style: theme.textTheme.labelSmall?.copyWith(color: soft)),
            ],
          ],
        ),
      ],
    );
  }
}