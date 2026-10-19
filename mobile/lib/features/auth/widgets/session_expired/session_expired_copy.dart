/// All user-facing text for the session-expired prompt, in one place.
const String sessionEndedEyebrow = 'SESSION ENDED';
const String sessionExpiredTitle = 'Sign in again';
const String signInAgainLabel = 'Sign in again';

String preservedItemsLabel(int count) =>
    count == 1 ? '1 item' : '$count items';

String sessionExpiredBody(String itemLabel) =>
    'Your current order ($itemLabel) is preserved. '
    'Sign in again to continue without starting over.';

String cartPreservedLabel(String itemLabel) =>
    'Cart preserved · $itemLabel';