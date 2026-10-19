import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/features/auth/domain/login_status.dart';
import 'package:mobile/features/auth/widgets/brand_panel.dart';
import 'package:mobile/features/auth/widgets/fade_slide_in.dart';
import 'package:mobile/features/auth/widgets/login_form_card.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';
import 'package:mobile/features/auth/widgets/login_top_bar.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/app/theme/theme_context.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  LoginStatus _status = LoginStatus.idle;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearNotice() {
    if (_status.hasNotice) setState(() => _status = LoginStatus.idle);
  }

  Future<void> _submit() async {
    if (_status.isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _status = LoginStatus.missingFields);
      return;
    }

    setState(() => _status = LoginStatus.submitting);

    // TODO(backend): replace this fake with the real sign-in call.
    // Preview trick: username "offline" shows the network error,
    // anything else shows the wrong-credentials error.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _status = _username.text.trim().toLowerCase() == 'offline'
          ? LoginStatus.networkError
          : LoginStatus.invalidCredentials;
    });
  }

  Widget _form() => LoginFormCard(
        usernameController: _username,
        passwordController: _password,
        status: _status,
        onSubmit: _submit,
        onEdited: _clearNotice,
      );

  @override
  Widget build(BuildContext context) {
    final compact = LoginLayout.isCompact(context);
    final theme = Theme.of(context);

    final footer = Text(
      'Shared device · Sign out after your shift.',
      textAlign: compact ? TextAlign.center : TextAlign.start,
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );

          return KkfcScaffold(
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: LoginLayout.focusBorderWidth,
                    color: context.semanticColors.highlights,
                  ),
                  const LoginTopBar(),
                  Expanded(child: compact ? _buildCompact(footer) : _buildWide(footer)),
                ],
              ),
            );
          }

          Widget _buildCompact(Widget footer) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FadeSlideIn(child: BrandPanel(compact: true)),
                  Padding(
                    padding: const EdgeInsets.all(LoginLayout.gapMd),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: LoginLayout.formMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(delay: LoginLayout.stagger, child: _form()),
                            const SizedBox(height: LoginLayout.gapLg),
                            FadeSlideIn(delay: LoginLayout.stagger * 2, child: footer),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _buildWide(Widget footer) {
            const padding = EdgeInsets.all(LoginLayout.gapXl);

            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, constraints.maxHeight - padding.vertical),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: LoginLayout.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Expanded(
                                  flex: 6,
                                  child: FadeSlideIn(child: BrandPanel(compact: false)),
                                ),
                                const SizedBox(width: LoginLayout.gapLg),
                                Expanded(
                                  flex: 5,
                                  child: FadeSlideIn(
                                    delay: LoginLayout.stagger,
                                    child: _form(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: LoginLayout.gapLg),
                          FadeSlideIn(delay: LoginLayout.stagger * 2, child: footer),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
}