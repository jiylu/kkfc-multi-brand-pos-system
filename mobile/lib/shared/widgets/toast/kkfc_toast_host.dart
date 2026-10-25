import 'dart:async';

import 'package:flutter/material.dart';

import 'kkfc_toast.dart';

import 'package:mobile/shared/data/models/kkfc_toast_metrics.dart';
import 'package:mobile/shared/data/models/kkfc_toast_tone.dart';

class KkfcToastHost extends StatefulWidget {
  const KkfcToastHost({
    super.key,
    required this.message,
    required this.tone,
    required this.position,
    required this.duration,
    required this.dismissOnAction,
    required this.onRemoved,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final KkfcToastTone tone;
  final KkfcToastPosition position;
  final Duration? duration; // null = stays until dismissed
  final bool dismissOnAction;
  final VoidCallback onRemoved;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<KkfcToastHost> createState() => KkfcToastHostState();
}

class KkfcToastHostState extends State<KkfcToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KkfcToastMetrics.enter,
      reverseDuration: KkfcToastMetrics.exit,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.forward();
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    final duration = widget.duration;
    if (duration == null || _closing) return;
    _timer = Timer(duration, dismiss);
  }

  void _pauseTimer() => _timer?.cancel();

  /// Animates out, then removes the overlay entry.
  Future<void> dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onRemoved();
  }

  void _handleAction() {
    widget.onAction?.call();
    if (widget.dismissOnAction) dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final compact = size.width < KkfcToastMetrics.compactBreakpoint;
    final atBottom = widget.position == KkfcToastPosition.bottom;

    Widget toast = KkfcToast(
      message: widget.message,
      tone: widget.tone,
      icon: widget.icon,
      actionLabel: widget.actionLabel,
      onAction: widget.onAction == null ? null : _handleAction,
      expand: compact,
      elevated: true,
      entrance: reduceMotion ? null : _controller,
    );

    toast = Dismissible(
      key: const ValueKey('kkfc-toast'),
      direction: atBottom ? DismissDirection.down : DismissDirection.up,
      onDismissed: (_) {
        _timer?.cancel();
        widget.onRemoved();
      },
      child: toast,
    );

    if (!reduceMotion) {
      toast = SlideTransition(
        position: _curve.drive(
          Tween<Offset>(
            begin: Offset(
              0,
              atBottom
                  ? KkfcToastMetrics.slideFraction
                  : -KkfcToastMetrics.slideFraction,
            ),
            end: Offset.zero,
          ),
        ),
        child: ScaleTransition(
          scale: _curve.drive(
            Tween<double>(begin: KkfcToastMetrics.scaleFrom, end: 1),
          ),
          alignment: atBottom ? Alignment.bottomCenter : Alignment.topCenter,
          child: toast,
        ),
      );
    }
    toast = FadeTransition(opacity: _curve, child: toast);

    // Pause the countdown while the pointer is over or on the toast.
    toast = MouseRegion(
      onEnter: (_) => _pauseTimer(),
      onExit: (_) => _armTimer(),
      child: Listener(
        onPointerDown: (_) => _pauseTimer(),
        onPointerUp: (_) => _armTimer(),
        onPointerCancel: (_) => _armTimer(),
        child: toast,
      ),
    );

    final gap = KkfcToastMetrics.screenGap;
    return SafeArea(
      child: AnimatedPadding(
        duration: KkfcToastMetrics.exit,
        curve: Curves.easeOut,
        // Lift above the keyboard when it is open.
        padding: EdgeInsets.fromLTRB(
          gap,
          gap,
          gap,
          gap + (atBottom ? insets.bottom : 0),
        ),
        child: Align(
          alignment: atBottom ? Alignment.bottomCenter : Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? double.infinity : KkfcToastMetrics.maxWidth,
            ),
            child: toast,
          ),
        ),
      ),
    );
  }
}
