@backend @e2e @robot
Feature: Catalog and order workflows through a running API
  Executable Given When Then steps are in robot/tests/catalog_orders_e2e.robot.
  Each test uses a unique menu item and real logins for isolated fixture users.

  @E2E-MCH-001
  Scenario: Persist the platform channel lifecycle
    Given a manager has created a unique menu item and GrabFood override
    When the manager changes its price to 150
    Then a subsequent read returns 150
    When the manager deactivates and reactivates the override
    Then a subsequent read returns an available channel

  @E2E-ORD-001
  Scenario: Cashier completes an order
    Given a cashier resolves a menu item code into a unique takeaway order payload
    When the cashier creates verifies and confirms it
    Then the response contains the same order ID in confirmed state
    And a queued ticket with a numeric ticket number is returned
    And the saved line price is 100 without recipe instructions

  @E2E-ORD-002
  Scenario: Safely replay an uncertain submission
    Given an already confirmed order
    When creation and confirmation are replayed unchanged
    Then the same complete order and ticket are returned
    And changing the original create payload under the same UUID returns 409

  @E2E-ORD-003
  Scenario: Reject normalized duplicate platform references
    Given a saved GrabFood draft
    When a different UUID is submitted with whitespace around the same store and external references
    Then the response status is 409

  @E2E-MCH-002
  Scenario: Managers can inspect and update channels across brands
    Given a manager created a GrabFood override at 120 pesos
    When another manager reads and updates it to 999 pesos
    Then both requests return 200
    And the original manager reads an available channel at 999 pesos

  @E2E-ASSET-001 @storage
  Scenario: Persist and download an associated image
    Given a configured test storage bucket and a unique menu item
    When its manager attaches a valid PNG
    Then a subsequent menu read returns the stored object key
    And an owner download URL retrieves a nonempty PNG from storage
