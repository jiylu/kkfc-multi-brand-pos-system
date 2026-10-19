import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/widgets/session_expired/session_expired_copy.dart';
import 'package:mobile/features/auth/widgets/session_expired/session_expired_dialog.dart';

const _phone = Size(412, 900);

Future<void> _pumpDialog(
  WidgetTester tester, {
  int preservedItemCount = 0,
  VoidCallback? onSignIn,
  Size size = _phone,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: SessionExpiredDialog(
          preservedItemCount: preservedItemCount,
          onSignIn: onSignIn ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(); // let the entrance animation finish
}

Finder get _signInButton => find.byType(FilledButton);

void main() {
  group('SessionExpiredDialog', () {
    testWidgets('shows the eyebrow, title, body and preserved pill', (
      tester,
    ) async {
      await _pumpDialog(tester);

      expect(find.text(sessionEndedEyebrow), findsOneWidget);
      // The title and the CTA deliberately share the same copy.
      expect(find.text(sessionExpiredTitle), findsNWidgets(2));
      expect(
        find.text(sessionExpiredBody(preservedItemsLabel(0))),
        findsOneWidget,
      );
      expect(find.text(cartPreservedLabel('0 items')), findsOneWidget);
      expect(find.byType(SessionExpiredCard), findsOneWidget);
    });

    testWidgets('reflects the preserved item count in body and pill', (
      tester,
    ) async {
      await _pumpDialog(tester, preservedItemCount: 3);

      expect(
        find.text(sessionExpiredBody(preservedItemsLabel(3))),
        findsOneWidget,
      );
      expect(find.text(cartPreservedLabel('3 items')), findsOneWidget);
    });

    testWidgets('the Sign in again button runs the callback once', (
      tester,
    ) async {
      var taps = 0;
      await _pumpDialog(tester, onSignIn: () => taps++);

      await tester.tap(_signInButton);
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('Android back does not dismiss the prompt', (tester) async {
      await _pumpDialog(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredCard), findsOneWidget);
    });

    testWidgets('does not overflow at 2x text scale', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SessionExpiredDialog(preservedItemCount: 5, onSignIn: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('showSessionExpiredDialog', () {
    testWidgets('opens over the current route and ignores barrier taps', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showSessionExpiredDialog(
                    context,
                    preservedItemCount: 2,
                    onSignIn: () {},
                  ),
                  child: const Text('host'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('host'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredCard), findsOneWidget);
      expect(find.text(cartPreservedLabel('2 items')), findsOneWidget);

      // A tap on the scrim must not close a session prompt.
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredCard), findsOneWidget);
    });
  });
}
