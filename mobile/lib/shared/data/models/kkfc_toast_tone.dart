/// Visual intent of a toast. Matches the Figma "Feedback/Message" variants.
enum KkfcToastTone {
  /// Green. "T-014 sent to the kitchen".
  success,

  /// Dark. A reversible action with an Undo, e.g. "T-013 moved to QC".
  inverse,

  /// Amber. Offline, stale board, low portions.
  warning,

  /// Red. Something failed and the user must know.
  danger,
}

enum KkfcToastPosition { top, bottom }
