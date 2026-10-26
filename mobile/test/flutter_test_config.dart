import 'dart:async';
import 'dart:io' show Platform;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/app/theme/tokens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCi = Platform.environment['CI'] == 'true';

  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: counterTheme,
      goldenTestTheme: GoldenTestTheme.standard().copyWith(
        backgroundColor: counterTheme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(KkfcSpace.s24),
      ),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
    ),
    run: testMain,
  );
}
