import 'package:flutter/material.dart';
import 'package:mobile/features/auth/domain/login_status.dart';
import 'package:mobile/features/auth/widgets/login_layout.dart';

/// Banner that grows in and fades between messages.
class LoginNotice extends StatelessWidget {
  const LoginNotice({super.key, required this.status});

  final LoginStatus status;

  @override
  Widget build(BuildContext context) {
    final duration = LoginLayout.motion(context, LoginLayout.base);

    return AnimatedSize(
      duration: duration,
      curve: LoginLayout.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: LoginLayout.curve,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: status.hasNotice
            ? _NoticeBox(key: ValueKey(status), status: status)
            : const SizedBox(key: ValueKey('none'), width: double.infinity),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({super.key, required this.status});

  final LoginStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: LoginLayout.gapMd),
      child: Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LoginLayout.gapMd),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(LoginLayout.radiusSm),
            border: Border.all(
              color: scheme.error,
              width: LoginLayout.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.noticeTitle,
                style: text.titleSmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: LoginLayout.gapXs),
              Text(
                status.noticeMessage,
                style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
