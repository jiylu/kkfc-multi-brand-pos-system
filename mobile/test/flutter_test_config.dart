import 'dart:async';
import 'dart:io' show Platform;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/app/theme/tokens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isCi = Platform.environment['CI'] == 'true';
  final standardGoldenTheme = GoldenTestTheme.standard();

  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: counterTheme,
      goldenTestTheme: GoldenTestTheme(
        backgroundColor: counterTheme.scaffoldBackgroundColor,
        borderColor: standardGoldenTheme.borderColor,
        nameTextStyle: standardGoldenTheme.nameTextStyle,
        padding: const EdgeInsets.all(KkfcSpace.s24),
      ),
      ciGoldensConfig: CiGoldensConfig(enabled: isCi && Platform.isLinux),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi),
    ),
    run: testMain,
  );
}
