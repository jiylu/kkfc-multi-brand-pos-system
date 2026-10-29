import 'package:flutter/material.dart';
import 'package:mobile/core/models/brand_models.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.brand, this.height = 24});

  final AssignedBrand brand;
  final double height;

  static const _assetsByCode = <String, String>{
    'GC': 'assets/images/gamcheon.png',
    'AI': 'assets/images/aurelia.png',
    'KK': 'assets/images/king_kungs.png',
  };

  /// Asset path for a brand code (GC, AI, KK), or null when unknown.
  static String? assetFor(String code) =>
      _assetsByCode[code.trim().toUpperCase()];

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(brand.code);
    if (asset == null) return Text(brand.name);

    return Image.asset(
      asset,
      key: ValueKey(asset),
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      semanticLabel: brand.name,
      errorBuilder: (_, _, _) => Text(brand.name),
    );
  }
}
