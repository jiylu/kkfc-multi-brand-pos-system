import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_brand_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_phone_header.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_staff_identity.dart';
import 'package:mobile/roles/kitchen_staff/shared/widgets/kitchen_tablet_header.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

void main() {
  testWidgets('KitchenTabletHeader centers all header contents', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: KitchenTabletHeader())),
      ),
    );

    final rowFinder = find.descendant(
      of: find.byType(KitchenTabletHeader),
      matching: find.byType(Row),
    );
    final row = tester.widget<Row>(rowFinder.first);
    expect(row.mainAxisAlignment, MainAxisAlignment.center);
    expect(row.crossAxisAlignment, CrossAxisAlignment.center);

    expect(find.byType(KitchenBrandCard), findsOneWidget);
    expect(find.byType(KitchenStaffIdentity), findsOneWidget);
    expect(find.byType(LogoutButton), findsOneWidget);
  });

  testWidgets('KitchenPhoneHeader centers all header contents', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: KitchenPhoneHeader())),
      ),
    );

    final rowFinder = find.descendant(
      of: find.byType(KitchenPhoneHeader),
      matching: find.byType(Row),
    );
    final row = tester.widget<Row>(rowFinder.first);
    expect(row.mainAxisAlignment, MainAxisAlignment.center);
    expect(row.crossAxisAlignment, CrossAxisAlignment.center);

    expect(find.byType(KitchenBrandCard), findsOneWidget);
    expect(find.byType(KitchenStaffIdentity), findsOneWidget);
    expect(find.byType(LogoutButton), findsOneWidget);
  });
}
