import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/auth/domain/login_status.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/widgets/brand_panel.dart';
import 'package:mobile/features/auth/widgets/login_form_card.dart';
import 'package:mobile/features/auth/widgets/login_notice.dart';
import 'package:mobile/features/auth/widgets/login_submit_button.dart';
import 'package:mobile/features/auth/widgets/login_text_field.dart';

// Tall surfaces so nothing needs scrolling to be tapped.
const _phone = Size(412, 1400);
const _desktop = Size(1280, 1000);

// Longer than the fake sign-in delay in LoginScreen.
const _fakeSignInWait = Duration(milliseconds: 1500);

Future<void> _pumpLogin(
  WidgetTester tester, {
  Size size = _phone,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: counterTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const LoginScreen(),
    ),
  );
  await tester.pumpAndSettle(); // finishes the entrance animations
}

Finder get _username => find.byType(TextField).first;

Finder get _password => find.descendant(
      of: find.byType(LoginPasswordField),
      matching: find.byType(TextField),
    );

LoginStatus _status(WidgetTester tester) =>
    tester.widget<LoginNotice>(find.byType(LoginNotice)).status;

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.tap(find.byType(LoginSubmitButton));
  await tester.pump();
}

/// Lets the fake sign-in finish and the notice animation play out.
Future<void> _finishSignIn(WidgetTester tester) async {
  await tester.pump(_fakeSignInWait);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('LoginScreen layout', () {
    testWidgets('shows both fields, the form card and the submit button',
        (tester) async {
      await _pumpLogin(tester);

      expect(find.byType(LoginFormCard), findsOneWidget);
      expect(find.byType(BrandPanel), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(LoginPasswordField), findsOneWidget);
      expect(find.byType(LoginSubmitButton), findsOneWidget);
      expect(_status(tester), LoginStatus.idle);
    });

    testWidgets('uses the compact brand panel on a phone', (tester) async {
      await _pumpLogin(tester, size: _phone);

      expect(tester.widget<BrandPanel>(find.byType(BrandPanel)).compact, isTrue);
    });

    testWidgets('uses the full brand panel on a wide screen', (tester) async {
      await _pumpLogin(tester, size: _desktop);

      expect(tester.widget<BrandPanel>(find.byType(BrandPanel)).compact, isFalse);
      expect(find.byType(LoginFormCard), findsOneWidget);
    });

    testWidgets('does not overflow at 2x text scale', (tester) async {
      await _pumpLogin(tester, textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('LoginScreen validation', () {
    testWidgets('empty submit shows the required-fields notice',
        (tester) async {
      await _pumpLogin(tester);

      await _tapSignIn(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(_status(tester), LoginStatus.missingFields);
      expect(
        tester.widget<LoginSubmitButton>(find.byType(LoginSubmitButton)).isLoading,
        isFalse,
      );
    });

    testWidgets('username without a password is still missing fields',
        (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(_username, 'ana.r');
      await _tapSignIn(tester);

      expect(_status(tester), LoginStatus.missingFields);
    });

    testWidgets('typing clears the notice', (tester) async {
      await _pumpLogin(tester);

      await _tapSignIn(tester);
      expect(_status(tester), LoginStatus.missingFields);

      await tester.enterText(_username, 'a');
      await tester.pump();

      expect(_status(tester), LoginStatus.idle);
    });
  });

  group('LoginScreen submit (UI-only fake)', () {
    testWidgets('shows loading, locks the form, then shows wrong credentials',
        (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(_username, 'ana.r');
      await tester.enterText(_password, 'secret');
      await _tapSignIn(tester);

      // While submitting
      expect(_status(tester), LoginStatus.submitting);
      expect(
        tester.widget<LoginSubmitButton>(find.byType(LoginSubmitButton)).isLoading,
        isTrue,
      );
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(tester.widget<TextField>(_username).enabled, isFalse);
      expect(tester.widget<TextField>(_password).enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After the fake call returns
      await _finishSignIn(tester);

      expect(_status(tester), LoginStatus.invalidCredentials);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
      expect(tester.widget<TextField>(_username).enabled, isTrue);
    });

    testWidgets('username "offline" shows the network error', (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(_username, 'offline');
      await tester.enterText(_password, 'secret');
      await _tapSignIn(tester);
      await _finishSignIn(tester);

      expect(_status(tester), LoginStatus.networkError);
    });

    testWidgets('a second tap while submitting is ignored', (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(_username, 'ana.r');
      await tester.enterText(_password, 'secret');
      await _tapSignIn(tester);
      await _tapSignIn(tester);

      expect(_status(tester), LoginStatus.submitting);

      await _finishSignIn(tester);
      expect(_status(tester), LoginStatus.invalidCredentials);
    });
  });

  group('LoginPasswordField', () {
    testWidgets('is obscured by default and toggles with the Show/Hide button',
        (tester) async {
      await _pumpLogin(tester);

      final toggle = find.descendant(
        of: find.byType(LoginPasswordField),
        matching: find.byType(TextButton),
      );

      expect(tester.widget<TextField>(_password).obscureText, isTrue);

      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<TextField>(_password).obscureText, isFalse);

      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<TextField>(_password).obscureText, isTrue);
    });
  });
}