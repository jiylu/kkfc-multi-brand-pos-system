import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';

/// Demo fixture for the cancel-order screens.
///
/// Every value here is sample data: `T-014` does not exist in the database.
/// Live screens (opened with `?orderId=`) do not use it for requests.
const sampleCancelOrder = CancelOrderTicket(
  number: 'T-014',
  brandName: "Aurelia's Inasal",
  staffName: 'Ana R.',
  staffRole: 'Order staff',
  currentStage: 'Check with server',
  kitchenStage: 'PREPARING',
  maxReasonLength: 280,
);

/// Prefilled reason from design frame 10 (57 of 280 characters).
const sampleCancellationReason =
    'Customer requested cancellation before preparation began.';
