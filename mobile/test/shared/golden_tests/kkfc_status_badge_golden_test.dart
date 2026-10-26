import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge.dart';

import '../../support/golden_harness.dart';

void main() {
  for (final viewport in goldenViewports) {
    for (final textScale in goldenTextScales) {
      goldenTest(
        'gallery at ${viewport.name} and ${textScale}x text',
        fileName: goldenFileName(
          'kkfc_status_badge',
          'gallery',
          viewport,
          textScale,
        ),
        textScaleFactor: textScale,
        constraints: goldenSheetConstraints(viewport),
        pumpBeforeTest: pumpOnce,
        builder: () => withDisabledAnimations(
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: KkfcSpace.s8,
              runSpacing: KkfcSpace.s8,
              children: [
                for (final status in KkfcStatus.values)
                  KkfcStatusBadge(status: status),
              ],
            ),
          ),
        ),
      );
    }
  }
}
