import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

import '../../support/golden_harness.dart';

void main() {
  for (final viewport in goldenViewports) {
    for (final textScale in goldenTextScales) {
      for (final isLoading in [false, true]) {
        final state = isLoading ? 'loading' : 'idle';

        goldenTest(
          '$state at ${viewport.name} and ${textScale}x text',
          fileName: goldenFileName(
            'kkfc_loading_button',
            state,
            viewport,
            textScale,
          ),
          textScaleFactor: textScale,
          constraints: goldenViewportConstraints(viewport),
          pumpBeforeTest: pumpOnce,
          builder: () => withDisabledAnimations(
            SizedBox(
              width: double.infinity,
              child: KkfcLoadingButton(
                label: 'Sign in',
                loadingLabel: 'Signing in…',
                isLoading: isLoading,
                onPressed: _noop,
              ),
            ),
          ),
        );
      }
    }
  }
}

void _noop() {}
