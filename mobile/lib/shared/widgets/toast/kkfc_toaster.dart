import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'kkfc_toast_host.dart';

import 'package:mobile/shared/data/models/kkfc_toast_metrics.dart';
import 'package:mobile/shared/data/models/kkfc_toast_tone.dart';

/// Lets you dismiss a toast early, e.g. when the connection returns.
class KkfcToastHandle {
  KkfcToastHandle._(this._entry, this._key);

  final OverlayEntry _entry;
  final GlobalKey<KkfcToastHostState> _key;
  bool _removed = false;

  bool get isShowing => !_removed;

  void dismiss() {
    final state = _key.currentState;
    if (state != null) {
      state.dismiss();
    } else {
      _remove();
    }
  }

  void _remove() {
    if (_removed) return;
    _removed = true;
    _entry.remove();
    _entry.dispose();
    if (identical(KkfcToaster._active, this)) KkfcToaster._active = null;
  }
}

abstract final class KkfcToaster {
  static KkfcToastHandle? _active;

  /// Shows one toast at a time. A new toast replaces the current one.
  ///
  /// [persistent] keeps it until dismissed (offline, stale data).
  /// Otherwise it lasts [duration], or a default (longer when it has an action).
  static KkfcToastHandle show(
    BuildContext context, {
    required String message,
    KkfcToastTone tone = KkfcToastTone.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    bool dismissOnAction = true,
    bool persistent = false,
    Duration? duration,
    KkfcToastPosition position = KkfcToastPosition.bottom,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    // Carry the caller's Theme (kitchen vs counter) into the root overlay.
    final themes = InheritedTheme.capture(from: context, to: overlay.context);

    _active?._remove();

    final resolved = persistent
        ? null
        : (duration ??
              (actionLabel != null
                  ? KkfcToastMetrics.actionDuration
                  : KkfcToastMetrics.defaultDuration));

    final key = GlobalKey<KkfcToastHostState>();
    late final KkfcToastHandle handle;
    final entry = OverlayEntry(
      builder: (_) => themes.wrap(
        KkfcToastHost(
          key: key,
          message: message,
          tone: tone,
          icon: icon,
          actionLabel: actionLabel,
          onAction: onAction,
          dismissOnAction: dismissOnAction,
          duration: resolved,
          position: position,
          onRemoved: () => handle._remove(),
        ),
      ),
    );
    handle = KkfcToastHandle._(entry, key);
    _active = handle;
    overlay.insert(entry);
    return handle;
  }

  static void dismissCurrent() => _active?.dismiss();

  // Presets that match the design.

  static KkfcToastHandle success(
    BuildContext context, {
    required String message,
    IconData? icon,
  }) => show(context, message: message, icon: icon);

  static KkfcToastHandle undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String undoLabel = 'Undo',
  }) => show(
    context,
    message: message,
    tone: KkfcToastTone.inverse,
    icon: Symbols.undo,
    actionLabel: undoLabel,
    onAction: onUndo,
  );

  static KkfcToastHandle warning(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    bool dismissOnAction = true,
    bool persistent = false,
  }) => show(
    context,
    message: message,
    tone: KkfcToastTone.warning,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    dismissOnAction: dismissOnAction,
    persistent: persistent,
  );

  static KkfcToastHandle error(
    BuildContext context, {
    required String message,
    bool persistent = false,
  }) => show(
    context,
    message: message,
    tone: KkfcToastTone.danger,
    persistent: persistent,
  );
}
