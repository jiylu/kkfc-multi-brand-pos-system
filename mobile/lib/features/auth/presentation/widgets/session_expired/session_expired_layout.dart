import 'package:mobile/app/theme/tokens.dart';

/// Layout constants for the session-expired prompt, mirroring [LoginLayout].
abstract final class SessionExpiredLayout {
  // Responsive
  static const double compactBreakpoint = 600;
  static const double dialogMaxWidth = 420;

  // Sizing
  static const double minTouchTarget = KkfcSizing.controlMd;

  // Spacing
  static const double gapXs = KkfcSpace.s4;
  static const double gapSm = KkfcSpace.s8;
  static const double gapMd = KkfcSpace.s16;
  static const double gapLg = KkfcSpace.s24;
  static const double gapXl = KkfcSpace.s32;
}
