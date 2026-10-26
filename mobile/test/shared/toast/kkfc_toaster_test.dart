import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/widgets/toast/kkfc_toasts.dart';

Widget _app(void Function(BuildContext) onTap, {double textScale = 1}) {
  return MaterialApp(
    theme: counterTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows, then auto-dismisses', (tester) async {
    await tester.pumpWidget(
      _app((c) => KkfcToaster.success(c, message: 'Sent')),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KkfcToast), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.byType(KkfcToast), findsNothing);
  });

  testWidgets('action fires and dismisses', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      _app(
        (c) =>
            KkfcToaster.undo(c, message: 'Moved', onUndo: () => undone = true),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.widgetWithText(TextButton, 'Undo'));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
    expect(find.byType(KkfcToast), findsNothing);
  });

  testWidgets('persistent toast stays until dismissed', (tester) async {
    late KkfcToastHandle handle;
    await tester.pumpWidget(
      _app(
        (c) => handle = KkfcToaster.warning(
          c,
          message: 'Offline',
          persistent: true,
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(KkfcToast), findsOneWidget);

    handle.dismiss();
    await tester.pumpAndSettle();
    expect(find.byType(KkfcToast), findsNothing);
  });

  testWidgets('long message at 2x text scale does not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (c) => KkfcToaster.warning(
          c,
          message: 'Offline. You can keep building the order; sending waits for Wi-Fi.',
          actionLabel: 'Retry now',
          onAction: () {},
          persistent: true,
        ),
        textScale: 2,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
