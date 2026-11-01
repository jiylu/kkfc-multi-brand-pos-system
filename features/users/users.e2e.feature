@backend @e2e @robot @users
Feature: Manage staff through global employee API contracts
  Every scenario can run independently with the shared isolated E2E fixtures.

  @E2E-USER-001
  Scenario: Manager creates staff without a brand assignment
    Given an authenticated manager
    When a staff account with a unique username of at most 16 characters is created
    Then the response status is 201
    And the account has the requested CASHIER_STAFF role
    And no brand assignment or password hash is exposed

  @E2E-USER-002
  Scenario: Manager lists employees globally
    Given an authenticated manager
    When the global user listing is requested with limit 5
    Then the response status is 200 with data and pagination metadata
    And no returned user exposes a brand assignment
    And no returned user exposes a password hash

  @E2E-USER-003
  Scenario: Manager inspects and deactivates independently created staff
    Given an authenticated manager
    And a new staff account created by this scenario
    When the manager retrieves that account
    Then the response contains no brand assignments
    When the manager deactivates it
    Then the response status is 200
    And the default account read returns 404
    When the account is retrieved with activeOnly false
    Then it is returned with is_active false

  @E2E-USER-004
  Scenario: Cashier cannot list users
    Given an authenticated cashier
    When the cashier requests the global user listing
    Then the response status is 403

  @E2E-USER-005
  Scenario: Require authentication for user administration
    Given no session token
    When the global user listing is requested
    Then the response status is 401
