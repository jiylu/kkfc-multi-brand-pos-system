import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/brand_models.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';

const _assets = <String, String>{
  'gamcheon': 'assets/images/gamcheon.png',
  'aurelias-inasal': 'assets/images/aurelia.png',
  'king-kungs-kafe': 'assets/images/king_kungs.png',
};

void main() {
  for (final brand in sampleAssignedBrands) {
    testWidgets('renders the ${brand.name} logo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: BrandLogo(brand: brand)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));

      expect((image.image as AssetImage).assetName, _assets[brand.id]);
    });
  }

  testWidgets('falls back to the brand name for an unknown brand', (
    tester,
  ) async {
    const brand = AssignedBrand(id: 'unknown', code: 'XX', name: 'Unknown');

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: BrandLogo(brand: brand)),
      ),
    );

    expect(find.text('Unknown'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
