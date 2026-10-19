import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

/// TODO: Palitan yung text placeholders ng image logo.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key});

  static const _brands = ['Gamcheon', "Aurelia's Inasal", 'King Kungs Kafé']; // Palitan to ng image
  static const _assetImages = [
    'assets/images/gamcheon.png',
    'assets/images/king_kungs.png',
    'assets/images/aurelia.png',
  ];

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
          for (final asset in _assetImages)
            Image.asset(asset, height: 40, fit: BoxFit.contain),
        ],
      ),
    );
  }
}