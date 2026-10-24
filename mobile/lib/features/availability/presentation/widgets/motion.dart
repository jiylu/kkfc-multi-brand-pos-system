import 'package:flutter/widgets.dart';

/// Returns zero when the OS asks for reduced motion.
Duration motionOf(BuildContext context, Duration normal) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;