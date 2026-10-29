import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/cart_panel/cart_panel_header.dart';

const _brand = AssignedBrand(
  id: 'king-kungs-kafe',
  code: 'KK',
  name: 'King Kungs Kafe',
);

Future<void> _pump(
  WidgetTester tester,
  MenuChannel channel,
  TextEditingController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: CartPanelHeader(
            brand: _brand,
            channel: channel,
            referenceController: controller,
            canClear: false,
            onClear: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'IT-MOB-MENU-006 Given King Kungs Kafe on GrabFood When the cart header renders Then Store reference shows the brand and channel',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pump(tester, MenuChannel.grabFood, controller);

      expect(find.text('Store reference'), findsOneWidget);
      expect(find.text('King Kungs Kafe, GrabFood'), findsOneWidget);

      await _pump(tester, MenuChannel.foodpanda, controller);

      expect(find.text('King Kungs Kafe, foodpanda'), findsOneWidget);
      expect(find.text('King Kungs Kafe, GrabFood'), findsNothing);
    },
  );
}
