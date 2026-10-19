import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/screens/temp_login_screen.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

Widget _harness(
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: counterTheme,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: textScaler, padding: padding),
          child: child!,
        );
      },
      home: home,
    ),
  );
}

void main() {
  testWidgets('login screen lays out at 2.5x text scale', (tester) async {
    await tester.pumpWidget(
      _harness(const LoginScreen(), textScaler: const TextScaler.linear(2.5)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('body clears the top system inset when there is no app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const KkfcScaffold(body: Text('Body')),
        padding: const EdgeInsets.only(top: 40),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Body')).dy, greaterThanOrEqualTo(40));
  });
}
