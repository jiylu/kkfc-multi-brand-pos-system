import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';

OrderEntryViewData _platformData({String? reference}) {
  return OrderEntryViewData.checkBeforeSending.withOrderDetails(
    brandName: 'King Kungs Kafe',
    channel: 'GrabFood',
    reference: reference,
    storeReference: 'King Kungs Kafe, GrabFood',
    isPlatform: true,
  );
}

void main() {
  group('IT-MOB-MENU-008 platform order summary', () {
    test('shows only brand and channel before the external reference', () {
      final data = _platformData();

      expect(data.rows.where((row) => row.label == 'Store'), isEmpty);
      expect(data.channelLine, 'GrabFood');
      expect(data.brandName, 'King Kungs Kafe');
    });

    test('adds the external reference to the channel in parentheses', () {
      final data = _platformData(reference: 'GF-1001');

      expect(data.rows.where((row) => row.label == 'Store'), isEmpty);
      expect(data.channelLine, 'GrabFood (#GF-1001)');
    });

    test('does not duplicate a leading hash on the reference', () {
      final data = _platformData(reference: '#GF-1001');

      expect(data.channelLine, 'GrabFood (#GF-1001)');
    });

    test('keeps the store row and separator format for other channels', () {
      final data = OrderEntryViewData.checkBeforeSending.withOrderDetails(
        brandName: 'King Kungs Kafe',
        channel: 'Dine-in',
        reference: 'Table 3',
        storeReference: 'King Kungs Kafe, Dine-in',
      );

      expect(
        data.rows.firstWhere((row) => row.label == 'Store').value,
        'King Kungs Kafe, Dine-in',
      );
      expect(data.channelLine, 'Dine-in · King Kungs Kafe, Dine-in · Table 3');
    });
  });
}
