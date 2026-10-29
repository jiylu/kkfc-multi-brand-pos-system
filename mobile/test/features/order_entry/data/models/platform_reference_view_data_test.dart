import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/order_entry/data/models/platform_reference_view_data.dart';

void main() {
  test('IT-MOB-MENU-007 Given King Kungs Kafe on GrabFood When context is applied Then Store reference is read-only brand and channel', () {
    final data = PlatformReferenceViewData.sample.withContext(
      brandName: 'King Kungs Kafe',
      channelLabel: 'GrabFood',
      externalReferenceErrorText: 'External reference required',
    );

    expect(data.fields, hasLength(2));

    final store = data.fields.first;
    expect(store.label, 'Store reference');
    expect(store.value, 'King Kungs Kafe, GrabFood');
    expect(store.readOnly, isTrue);
    expect(store.required, isFalse);
    expect(store.errorText, isNull);

    final external = data.fields.last;
    expect(external.label, 'External order reference');
    expect(external.readOnly, isFalse);
    expect(external.required, isTrue);
    expect(external.errorText, 'External reference required');
  });
}
