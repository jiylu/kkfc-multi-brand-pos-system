import 'package:flutter/material.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.hasError = false,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final bool hasError;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginLayout.radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );

    final idle = hasError ? scheme.error : scheme.outlineVariant;
    final focused = hasError ? scheme.error : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: LoginLayout.gapXs),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            suffixIcon: suffix,
            border: border(idle, LoginLayout.borderWidth),
            enabledBorder: border(idle, LoginLayout.borderWidth),
            disabledBorder: border(
              scheme.outlineVariant,
              LoginLayout.borderWidth,
            ),
            focusedBorder: border(focused, LoginLayout.focusBorderWidth),
          ),
        ),
      ],
    );
  }
}

class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return LoginTextField(
      label: 'Password',
      hint: 'Enter password',
      controller: widget.controller,
      obscureText: !_visible,
      enabled: widget.enabled,
      hasError: widget.hasError,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.only(right: LoginLayout.gapXs),
          child: TextButton(
            onPressed: widget.enabled
                ? () => setState(() => _visible = !_visible)
                : null,
            child: Text(_visible ? 'Hide' : 'Show'),
          ),
        ),
      ),
    );
  }
}
