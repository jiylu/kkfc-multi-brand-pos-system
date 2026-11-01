import 'package:flutter/widgets.dart';

import 'kitchen_metrics.dart';

extension KitchenBreakpoints on BuildContext {
  bool get isKitchenTablet =>
      MediaQuery.sizeOf(this).width >= KitchenMetrics.tabletBreakpoint;
}
