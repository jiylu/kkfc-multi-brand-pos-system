import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/order_entry/data/models/platform_reference_view_data.dart';
import 'package:mobile/features/order_entry/presentation/widgets/platform_reference_card.dart';

void main() {
  testWidgets(
    'IT-MOB-MENU-007 Given King Kungs Kafe on GrabFood When the platform reference card renders Then only the external reference is editable',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final data = PlatformReferenceViewData.sample.withContext(
        brandName: 'King Kungs Kafe',
        channelLabel: 'GrabFood',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: 400,
                child: PlatformReferenceCard(
                  data: data,
                  externalReferenceController: controller,
                  onExternalReferenceChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Store reference'), findsOneWidget);
      expect(find.text('King Kungs Kafe, GrabFood'), findsOneWidget);
      expect(find.text('Select store'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'GF-1001');
      expect(controller.text, 'GF-1001');
    },
  );
}
