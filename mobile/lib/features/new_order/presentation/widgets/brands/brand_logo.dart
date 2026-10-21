import 'package:flutter/material.dart';
import 'package:mobile/features/new_order/data/models/brand_models.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.brand, this.height = 24});

  final AssignedBrand brand;
  final double height;

  static const _assets = <String, String>{
    'gamcheon': 'assets/images/gamcheon.png',
    'aurelias-inasal': 'assets/images/aurelia.png',
    'king-kungs-kafe': 'assets/images/king_kungs.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assets[brand.id];
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
