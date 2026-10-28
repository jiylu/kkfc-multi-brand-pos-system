import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';

/// Prototype fixture for the cancel-order screens.
///
/// Every value here is sample data: `T-014` does not exist in the database and
/// the cancellation endpoint has not been implemented yet.
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
