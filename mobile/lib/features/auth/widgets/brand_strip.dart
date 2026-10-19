import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key});

  static const _assets = <({String path, double height})>[
    (path: 'assets/images/gamcheon.png', height: LoginLayout.iconXl),
    (path: 'assets/images/king_kungs.png', height: LoginLayout.iconLg),
    (path: 'assets/images/aurelia.png', height: LoginLayout.iconXl),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: LoginLayout.gapSm,
        vertical: LoginLayout.gapMd,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(LoginLayout.radiusMd),
      ),
      child: Row(
        children: [
          for (final brand in _assets)
            Expanded(
              child: Image.asset(
                brand.path,
                height: brand.height,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}