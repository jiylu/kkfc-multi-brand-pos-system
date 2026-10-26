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

  @override
  Widget build(BuildContext context) {
    final asset = _assetsByCode[brand.code.toUpperCase()];
    if (asset == null) return Text(brand.name);

    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: brand.name,
      errorBuilder: (_, _, _) => Text(brand.name),
    );
  }
}
