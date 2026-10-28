@mobile @widget @orders @prototype
Feature: Cancel order workflow screens
  The cancellation API is not implemented. These scenarios cover the prototype screens only:
  no request is sent and every ticket value is sample data.

  @IT-MOB-CANCEL-001
  Scenario: Review the cancellation request
    Given the cancel order screen at the review step
    When it is rendered
    Then the reason request and both actions are visible

  @IT-MOB-CANCEL-002
  Scenario: Block cancellation without a reason
    Given the cancel order screen at the review step
    When Cancel order is pressed with an empty reason
    Then the validation step is shown
    And the field reports that a reason is required
    And the order is still marked Not cancelled

  @IT-MOB-CANCEL-003
  Scenario: Move to the pending step with a reason
    Given the cancel order screen at the review step
    When Cancel order is pressed with the sample reason
    Then the pending step is shown
    And no refund or stock reversal is implied

  @IT-MOB-CANCEL-004
  Scenario: Confirm the sample outcome
    Given the cancel order screen at the pending step
    When the sample outcome is confirmed
    Then the cancelled outcome is shown
    And the result is marked as server confirmed

  @IT-MOB-CANCEL-005
  Scenario: Deny the sample outcome
    Given the cancel order screen at the pending step
    When the sample outcome is denied
    Then the denied step is shown
    And the order remains active

  @IT-MOB-CANCEL-006
  Scenario: Require supervisor approval after preparation started
    Given the cancel order screen at the approval step
    Then the restricted action is shown
    And the cancellation action is not available
    And Return to order is the only action

  @IT-MOB-CANCEL-007
  Scenario: Fit the review step on a phone
    Given a 390 by 844 phone viewport
    When the cancel order screen is opened
    Then no layout exception occurs
    And both footer actions remain reachable
