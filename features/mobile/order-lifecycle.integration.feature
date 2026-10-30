@mobile @integration @real_api @orders
Feature: Current mobile order review and real API order lifecycle

  @IT-MOB-ORD-001
  Scenario: Review in the UI and verify and confirm the resulting draft through the API
    Given a staff member logs in and builds a Takeaway cart with two meals
    When the staff member reviews the cart and repeatedly taps Confirm and send
    Then the current mobile flow creates one draft request and clears the cart
    And the API draft has an order code and no kitchen ticket
    When the test calls the real verification endpoint
    Then verification returns current prices without creating a ticket
    When the test calls the real confirmation endpoint and retries confirmation
    Then the API returns one confirmed order with the same code and one queued ticket
    And repeated confirmation preserves the original payment state

  @IT-MOB-ORD-002
  Scenario: Safe create retries and daily order codes
    Given a logged in staff member and a new order request
    When the same order UUID and payload are submitted twice to the API
    Then the same order and line identities and order code are returned
    When the same UUID is submitted with changed quantities
    Then the API rejects the conflicting request
    When a second order is created
    Then its brand code and daily order number are correct
    And retries and conflicts have not consumed another daily order number

  @IT-MOB-ORD-003
  Scenario: Prevent duplicate platform orders
    Given a logged in staff member creates a GrabFood draft through the API
    When the same request is retried with its original UUID
    Then the existing order is returned
    When a new UUID reuses the same platform store and external reference
    Then the API rejects the duplicate and identifies the existing order
    When the original draft is verified and confirmed through the API
    Then its platform payment state remains settled and paid

  @IT-MOB-ORD-004
  Scenario: Recheck catalog availability and preserve a rejected mobile draft
    Given a staff member has an available meal in the cart and a saved API draft
    When the fixture manager marks that meal unavailable through the real API
    Then verification and confirmation reject the stale API draft without a ticket
    And a new API order containing an unavailable meal is rejected
    When the staff member attempts to send the stale mobile cart
    Then the mobile review remains open with the cart and reference preserved
    And the test restores the fixture availability afterward
