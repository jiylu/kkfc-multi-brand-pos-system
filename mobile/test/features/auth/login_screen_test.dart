import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/brand_panel.dart';
import 'package:mobile/features/auth/presentation/widgets/login_form_card.dart';
import 'package:mobile/features/auth/presentation/widgets/login_notice.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_field.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'package:mobile/features/auth/presentation/widgets/session_expired/session_expired_copy.dart';
import 'package:mobile/features/auth/presentation/widgets/session_expired/session_expired_dialog.dart';

// Tall surfaces so nothing needs scrolling to be tapped.
const _phone = Size(412, 1400);
const _desktop = Size(1280, 1000);

/// Stands in for the real repository so widget tests never hit the network.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.onLogin) : super(Dio(), TokenStore());

  final Future<String> Function(String username, String password) onLogin;
  int callCount = 0;

  @override
  Future<String> login({required String username, required String password}) {
    callCount++;
    return onLogin(username, password);
  }
}

Future<ProviderContainer> _pumpLogin(
  WidgetTester tester, {
  Size size = _phone,
  double textScale = 1,
  AuthRepository? authRepository,
  bool sessionExpired = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
  );
  addTearDown(container.dispose);

  // The 401 interceptor flags the expiry before the router lands here.
  if (sessionExpired) {
    container.read(sessionExpiredProvider.notifier).set(true);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: counterTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle(); // finishes the entrance animations
  return container;
}

Finder get _username => find.byType(TextField).first;

Finder get _password => find.descendant(
  of: find.byType(LoginPasswordField),
  matching: find.byType(TextField),
);

LoginStatus _status(WidgetTester tester) =>
    tester.widget<LoginNotice>(find.byType(LoginNotice)).status;

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.tap(find.byType(KkfcLoadingButton));
  await tester.pump();
}

/// Lets the in-flight sign-in future resolve and the notice animate in.
Future<void> _finishSignIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The dialog's CTA, distinguished from the login form's submit button.
Finder get _dialogSignIn => find.descendant(
  of: find.byType(SessionExpiredCard),
  matching: find.byType(FilledButton),
);

void main() {
  group('LoginScreen layout', () {
    testWidgets('shows both fields, the form card and the submit button', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(find.byType(LoginFormCard), findsOneWidget);
      expect(find.byType(BrandPanel), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(LoginPasswordField), findsOneWidget);
      expect(find.byType(KkfcLoadingButton), findsOneWidget);
      expect(_status(tester), LoginStatus.idle);
    });

    testWidgets('uses the compact brand panel on a phone', (tester) async {
      await _pumpLogin(tester, size: _phone);

      expect(
        tester.widget<BrandPanel>(find.byType(BrandPanel)).compact,
        isTrue,
      );
    });

    testWidgets('uses the full brand panel on a wide screen', (tester) async {
      await _pumpLogin(tester, size: _desktop);

      expect(
        tester.widget<BrandPanel>(find.byType(BrandPanel)).compact,
        isFalse,
      );
      expect(find.byType(LoginFormCard), findsOneWidget);
    });

    testWidgets('does not overflow at 2x text scale', (tester) async {
      await _pumpLogin(tester, textScale: 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('LoginScreen validation', () {
    testWidgets('empty submit shows the required-fields notice', (
      tester,
    ) async {
      await _pumpLogin(tester);

      await _tapSignIn(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(_status(tester), LoginStatus.missingFields);
      expect(
        tester
            .widget<KkfcLoadingButton>(find.byType(KkfcLoadingButton))
            .isLoading,
        isFalse,
      );
    });

    testWidgets('username without a password is still missing fields', (
      tester,
    ) async {
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

  group('LoginScreen submit', () {
    testWidgets('a successful sign-in stores the session token', (
      tester,
    ) async {
      final completer = Completer<String>();
      final repo = _FakeAuthRepository((_, _) => completer.future);
      final container = await _pumpLogin(tester, authRepository: repo);

      await tester.enterText(_username, 'test_owner');
      await tester.enterText(_password, 'Password123!');
      await _tapSignIn(tester);

      // While submitting
      expect(_status(tester), LoginStatus.submitting);
      expect(
        tester
            .widget<KkfcLoadingButton>(find.byType(KkfcLoadingButton))
            .isLoading,
        isTrue,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(_username).enabled, isFalse);
      expect(tester.widget<TextField>(_password).enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete('token-abc');
      await _finishSignIn(tester);

      // Holding the token is what makes the router navigate to /orders.
      expect(container.read(sessionTokenProvider), 'token-abc');
      expect(repo.callCount, 1);
    });

    testWidgets('rejected credentials show the invalid-credentials notice', (
      tester,
    ) async {
      final repo = _FakeAuthRepository(
        (_, _) async => throw const AuthException(
          'Invalid username or password.',
          kind: AuthFailure.invalidCredentials,
        ),
      );
      await _pumpLogin(tester, authRepository: repo);

      await tester.enterText(_username, 'ana.r');
      await tester.enterText(_password, 'wrong');
      await _tapSignIn(tester);
      await _finishSignIn(tester);

      expect(_status(tester), LoginStatus.invalidCredentials);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(tester.widget<TextField>(_username).enabled, isTrue);
    });

    testWidgets('a network failure shows the network-error notice', (
      tester,
    ) async {
      final repo = _FakeAuthRepository(
        (_, _) async => throw const AuthException(
          'Unable to reach the server.',
          kind: AuthFailure.network,
        ),
      );
      await _pumpLogin(tester, authRepository: repo);

      await tester.enterText(_username, 'test_owner');
      await tester.enterText(_password, 'Password123!');
      await _tapSignIn(tester);
      await _finishSignIn(tester);

      expect(_status(tester), LoginStatus.networkError);
    });

    testWidgets('a second tap while submitting is ignored', (tester) async {
      final completer = Completer<String>();
      final repo = _FakeAuthRepository((_, _) => completer.future);
      await _pumpLogin(tester, authRepository: repo);

      await tester.enterText(_username, 'test_owner');
      await tester.enterText(_password, 'Password123!');
      await _tapSignIn(tester);
      await _tapSignIn(tester);

      expect(_status(tester), LoginStatus.submitting);
      expect(repo.callCount, 1);

      completer.complete('token-abc');
      await _finishSignIn(tester);
    });
  });

  group('LoginPasswordField', () {
    testWidgets(
      'is obscured by default and toggles with the Show/Hide button',
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
      },
    );
  });

  group('LoginScreen session expired', () {
    testWidgets('no prompt while the session is still valid', (tester) async {
      await _pumpLogin(tester);

      expect(find.byType(SessionExpiredCard), findsNothing);
    });

    testWidgets('prompts when the session was rejected', (tester) async {
      final container = await _pumpLogin(tester, sessionExpired: true);

      expect(find.byType(SessionExpiredCard), findsOneWidget);
      // Title and CTA share the same copy.
      expect(find.text(sessionExpiredTitle), findsNWidgets(2));
      expect(container.read(sessionExpiredProvider), isTrue);
    });

    testWidgets('the CTA closes the prompt and clears the flag', (
      tester,
    ) async {
      final container = await _pumpLogin(tester, sessionExpired: true);

      await tester.tap(_dialogSignIn);
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredCard), findsNothing);
      expect(container.read(sessionExpiredProvider), isFalse);
    });
  });
}
