import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/status_icons.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/order_status.dart';

void main() {
  test('numbers use IBM Plex with tabular figures', () {
    expect(KkfcTypography.kdsTicket.fontFamily, KkfcFonts.numeric);
    expect(KkfcTypography.kdsTicket.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(KkfcTypography.price.fontFamily, KkfcFonts.numeric);
  });

  test('item text uses Atkinson and references use mono', () {
    expect(KkfcTypography.kdsItem.fontFamily, KkfcFonts.text);
    expect(KkfcTypography.reference.fontFamily, KkfcFonts.mono);
  });

  test('line height matches the token value', () {
    // ty-kds-ticket: 48px / 52px
    expect(KkfcTypography.kdsTicket.height! * 48, closeTo(52, 0.001));
  });

  test('every order status has an icon', () {
    for (final status in OrderStatus.values) {
      expect(statusIcon(status), isA<IconData>());
    }
  });
}