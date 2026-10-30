import 'package:flutter/material.dart';

import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';

/// Maps the workflow tone onto the design-system tone so the cancel screens
/// stay on the shared semantic palette.
KkfcTone cancelTone(BuildContext context, CancelTone tone) => switch (tone) {
  CancelTone.warning => context.semanticColors.warning,
  CancelTone.danger => context.semanticColors.danger,
  CancelTone.info => context.semanticColors.info,
  CancelTone.success => context.semanticColors.success,
};
