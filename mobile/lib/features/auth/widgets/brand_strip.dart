import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

/// TODO: Palitan yung text placeholders ng image logo.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key});

  static const _brands = ['Gamcheon', "Aurelia's Inasal", 'King Kungs Kafé'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoginLayout.gapMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(LoginLayout.radiusMd),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: LoginLayout.gapMd,
        runSpacing: LoginLayout.gapSm,
        children: [
          for (final brand in _brands)
            Text(
              brand,
              style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary),
            ),
        ],
      ),
    );
  }
}