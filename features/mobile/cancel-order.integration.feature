@mobile @widget @orders @cancel
Feature: Cancel order workflow screens
  Design frames 10-15. The demo screens run on sample data and send nothing.
  A live screen (opened with an order UUID) calls
  POST /brands/:brandId/orders/:orderId/cancel and lets the server response
  select the cancelled or denied step.

  The repository itself is covered by mobile/test/features/orders/cancel_order_repository_test.dart
  through a fake HTTP adapter; the scenarios below drive the screen with a
  stubbed repository, so they do not prove a running API.

  @demo @IT-MOB-CANCEL-001
  Scenario: Review the cancellation request
    Given the cancel order screen at the review step
    When it is rendered
    Then the reason request and both actions are visible

  @demo @IT-MOB-CANCEL-002
  Scenario: Block cancellation without a reason
    Given the cancel order screen at the review step
    When Cancel order is pressed with an empty reason
    Then the validation step is shown
    And the field reports that a reason is required
    And the order is still marked Not cancelled

  @demo @IT-MOB-CANCEL-003
  Scenario: Move to the pending step with a reason
    Given the cancel order screen at the review step
    When Cancel order is pressed with the sample reason
    Then the pending step is shown
    And no refund or stock reversal is implied
    And no request is sent

  @demo @IT-MOB-CANCEL-004
  Scenario: Confirm the sample outcome
    Given the cancel order screen at the pending step
    When the sample outcome is confirmed
    Then the cancelled outcome is shown
    And the result is marked as a sample outcome

  @demo @IT-MOB-CANCEL-005
  Scenario: Deny the sample outcome
    Given the cancel order screen at the pending step
    When the sample outcome is denied
    Then the denied step is shown
    And the order remains active

  @demo @IT-MOB-CANCEL-006
  Scenario: Require supervisor approval after preparation started
    Given the cancel order screen at the approval step
    Then the restricted action is shown
    And the cancellation action is not available
    And Return to order is the only action

  @demo @IT-MOB-CANCEL-007
  Scenario: Fit the review step on a phone
    Given a 390 by 844 phone viewport
    When the cancel order screen is opened
    Then no layout exception occurs
    And both footer actions remain reachable

  @live @IT-MOB-CANCEL-008
  Scenario: Show the server-confirmed cancellation
    Given the cancel order screen opened with a real order UUID
    When a reason is submitted and the server accepts the cancellation
    Then the server-confirmed outcome is shown
    And the sample outcome controls are hidden
    And no kitchen ticket is reported for an unpaid draft

  @live @IT-MOB-CANCEL-009
  Scenario: Show the server rejection
    Given the cancel order screen opened with a real order UUID
    When the server rejects the cancellation
    Then the denied step is shown
    And the server message and status are displayed
    And a rejection the server would repeat offers leaving the screen

  @live @IT-MOB-CANCEL-010
  Scenario: Retry an uncertain cancellation
    Given a live cancellation that failed without a server response
    When the retry action is pressed
    Then the same order and reason are sent again

  @live @IT-MOB-CANCEL-011
  Scenario: Never send a blank reason
    Given the cancel order screen opened with a real order UUID
    When Cancel order is pressed with an empty reason
    Then the validation step is shown
    And no request is sent
