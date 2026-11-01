@backend @unit @orders
Feature: Additional orders unit coverage
  Feature ID: FEAT-ORD-UT-ADDITIONAL
  Requirement ID: FR-ORD-001

  As a backend maintainer,
  I want the orders behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/orders/orders/orders.repository.spec.ts
  # Context: Order transaction conflict recovery
  @UT-ORD-007
  Scenario: Retry the full order transaction after retryable commit conflicts
    Test Case ID: UT-ORD-007
    Given a retryable serialization or deadlock failure at transaction commit
    When the serializable order operation is executed
    Then the entire transaction is retried

  # Jest: server/src/modules/orders/orders/orders.repository.spec.ts
  # Context: Order transaction conflict recovery
  @UT-ORD-008
  Scenario: Bound transaction conflict retries and return a stable recovery error
    Test Case ID: UT-ORD-008
    Given every transaction attempt fails with a retryable conflict
    When the serializable order operation is executed
    Then retries are bounded and the stable recovery error is returned

  # Jest: server/src/modules/orders/orders/orders.repository.spec.ts
  # Context: Order transaction conflict recovery
  @UT-ORD-009
  Scenario: Propagate non-retryable transaction errors without replaying work
    Test Case ID: UT-ORD-009
    Given a non-retryable database error
    When the serializable order operation is executed
    Then the original error is propagated without replaying work

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-010
  Scenario: Creates a draft without a ticket, final recipe or stock writes
    Test Case ID: UT-ORD-010
    Given a valid order creation payload
    When a draft is created
    Then the draft is saved without a ticket, final recipe snapshot, or stock writes

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-011
  Scenario: Verifies without persisting any effects or exposing recipe instructions
    Test Case ID: UT-ORD-011
    Given an existing draft with valid catalog and payment data
    When the draft is verified
    Then verification has no persistence effects and does not expose recipe instructions

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-012
  Scenario: Format allocated daily numbers as saved brand order codes
    Test Case ID: UT-ORD-012
    Given a daily order number allocated by the repository
    When a draft is created
    Then the brand prefix and allocated number are formatted as the saved order code

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-013
  Scenario: Uses the database Manila date to start a new counter after midnight
    Test Case ID: UT-ORD-013
    Given the database Manila date has advanced past midnight
    When a new draft is created
    Then a new daily counter starts for that database date

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-014
  Scenario: Preserves the original code on a UUID replay across midnight and a brand code change
    Test Case ID: UT-ORD-014
    Given an original order replayed after midnight and a brand code change
    When creation is retried with the same UUID and payload
    Then the original saved order code is preserved

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-015
  Scenario: Retries a counter serialization conflict before saving an order
    Test Case ID: UT-ORD-015
    Given a counter allocation encounters a serialization conflict
    When a draft is created
    Then the transaction retries before saving the order

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-016
  Scenario: Reject unavailable modifiers before order writes
    Test Case ID: UT-ORD-016
    Given an unavailable modifier assigned to a menu item
    When verification or confirmation is requested
    Then the order is rejected before writing snapshots or tickets

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-017
  Scenario: Reject unavailable menu items before order writes
    Test Case ID: UT-ORD-017
    Given an unavailable menu item
    When verification or confirmation is requested
    Then the order is rejected before writing snapshots or tickets

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-018
  Scenario: Confirms with channel price, modifier and full recipe snapshots, with no stock effects
    Test Case ID: UT-ORD-018
    Given a valid draft with channel pricing, modifiers, and recipe components
    When confirmation is requested
    Then prices and complete recipe snapshots are saved with a ticket and no stock effects

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-019
  Scenario: Returns the original ticket on retries without refreshing snapshots
    Test Case ID: UT-ORD-019
    Given an already confirmed order with saved snapshots and ticket
    When confirmation is retried
    Then the original ticket is returned without refreshing snapshots

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-020
  Scenario: Retries a serialization conflict and observes the winning confirmation
    Test Case ID: UT-ORD-020
    Given a concurrent confirmation wins after a serialization conflict
    When confirmation is retried
    Then the saved winning confirmation is returned

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-021
  Scenario: Does not mark an order confirmed when ticket insertion fails
    Test Case ID: UT-ORD-021
    Given ticket insertion fails during confirmation
    When the draft is confirmed
    Then the order is not marked confirmed

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-022
  Scenario: Format ticket sequences without truncation or precision loss
    Test Case ID: UT-ORD-022
    Given a valid ticket sequence value including large numeric values
    When a ticket number is generated
    Then the number is formatted without truncation or precision loss

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-023
  Scenario: Reject invalid ticket sequence results before issuing tickets
    Test Case ID: UT-ORD-023
    Given an invalid ticket sequence result
    When confirmation requests a ticket
    Then the invalid sequence is rejected without issuing a ticket

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-024
  Scenario: Reject corrupted saved order quantities before writing
    Test Case ID: UT-ORD-024
    Given a saved draft with a corrupted quantity
    When confirmation is requested
    Then the invalid quantity is rejected before writing

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-025
  Scenario: Reject invalid catalog prices during confirmation
    Test Case ID: UT-ORD-025
    Given an invalid catalog price
    When an order is confirmed
    Then the invalid price is rejected

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-026
  Scenario: Reject inconsistent or cancelled saved order states
    Test Case ID: UT-ORD-026
    Given an order in an inconsistent or cancelled state
    When confirmation is requested
    Then the invalid saved state is rejected

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-027
  Scenario: Bounds conflict retries without creating a ticket
    Test Case ID: UT-ORD-027
    Given serialization conflicts persist through every allowed attempt
    When confirmation is requested
    Then conflict retries are bounded without creating a ticket

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-028
  Scenario: Normalizes platform references before duplicate lookup
    Test Case ID: UT-ORD-028
    Given platform references include surrounding whitespace
    When an order is created
    Then references are normalized before duplicate detection

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-029
  Scenario: Rejects duplicate modifier IDs even when invoked outside the HTTP validator
    Test Case ID: UT-ORD-029
    Given a direct service payload repeats a modifier ID
    When an order is created
    Then duplicate modifiers are rejected even without HTTP validation

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-030
  Scenario: Reject invalid payment or missing menu entries before writing
    Test Case ID: UT-ORD-030
    Given an invalid payment or missing menu item
    When confirmation is requested
    Then the request is rejected before writing

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-031
  Scenario: Does not expose orders outside the requested brand
    Test Case ID: UT-ORD-031
    Given an order belongs to a different brand than the requested scope
    When confirmation is requested
    Then the service does not expose the out-of-scope order

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-032
  Scenario: Enforce platform settlement for GrabFood and Foodpanda orders
    Test Case ID: UT-ORD-032
    Given a GrabFood or Foodpanda order
    When confirmation is requested
    Then platform-settled payment semantics are enforced

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-033
  Scenario: Rejects duplicate platform references even with a different order ID
    Test Case ID: UT-ORD-033
    Given the same platform store and external references exist under another order UUID
    When another order is created
    Then the duplicate platform order is rejected

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-034
  Scenario: Limit duplicate order details to the requested brand
    Test Case ID: UT-ORD-034
    Given duplicate platform references resolve to an order within or outside the requested brand
    When creation detects the duplicate
    Then duplicate details are disclosed only within the requested brand

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle
  @UT-ORD-035
  Scenario: Returns an opaque conflict when an order UUID belongs to another brand
    Test Case ID: UT-ORD-035
    Given an order UUID already belongs to another brand
    When creation reuses that UUID
    Then an opaque conflict is returned without disclosing the other brand's order

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-036
  Scenario: Cancels a draft, records actor/reason/time and redacts private fields
    Test Case ID: UT-ORD-036
    Given a draft and a valid cancellation reason and actor
    When the order is cancelled
    Then actor, reason, and time are saved while private fields are redacted

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-037
  Scenario: Cancel the order and kitchen ticket in one serializable transaction
    Test Case ID: UT-ORD-037
    Given a confirmed order with a cancellable kitchen ticket
    When the order is cancelled
    Then the order and ticket are cancelled in the same serializable transaction

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-038
  Scenario: Returns the original cancellation on retries without writing
    Test Case ID: UT-ORD-038
    Given an order has already been cancelled
    When cancellation is retried
    Then the original cancellation is returned without additional writes

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-039
  Scenario: Reject non-cancellable order and ticket states before writing
    Test Case ID: UT-ORD-039
    Given an order or ticket is in a non-cancellable state
    When cancellation is requested
    Then the invalid state is rejected before writing

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-040
  Scenario: Reject invalid cancellation reasons
    Test Case ID: UT-ORD-040
    Given a missing, blank, or invalid cancellation reason
    When cancellation is requested
    Then the reason is rejected before writing

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-041
  Scenario: Rejects a missing order or order outside the requested brand
    Test Case ID: UT-ORD-041
    Given a missing order or an order outside the requested brand
    When cancellation is requested
    Then a not-found error is returned

  # Jest: server/src/modules/orders/orders/orders.service.spec.ts
  # Context: Order lifecycle / cancellation
  @UT-ORD-042
  Scenario: Does not update the order if the ticket update fails
    Test Case ID: UT-ORD-042
    Given the kitchen ticket cancellation write fails
    When the order is cancelled
    Then the order cancellation is not persisted
