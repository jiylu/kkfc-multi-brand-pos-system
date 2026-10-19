import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/widgets/session_expired/session_expired_copy.dart';

void main() {
  test('singular and plural item labels', () {
    expect(preservedItemsLabel(1), '1 item');
    expect(preservedItemsLabel(3), '3 items');
    expect(preservedItemsLabel(0), '0 items');
  });
}