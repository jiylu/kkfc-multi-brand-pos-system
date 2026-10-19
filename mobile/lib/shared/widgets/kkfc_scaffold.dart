import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Use this instead of Scaffold on every screen.
/// Content draws edge to edge, and SafeArea keeps it clear of system bars.
class KkfcScaffold extends StatelessWidget {
  const KkfcScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        appBar: appBar,
        // The AppBar already clears the status bar, so pad the top only when there isn't one.
        body: SafeArea(
          top: appBar == null,
          bottom: bottomBar == null,
          child: body,
        ),
        bottomNavigationBar: bottomBar == null
            ? null
            : SafeArea(top: false, child: bottomBar!),
      ),
    );
  }
}
