@backend @e2e @robot @users
Feature: Manage staff through current brand-scoped API contracts
  Every scenario can run independently with the shared isolated E2E fixtures.

  @E2E-USER-001
  Scenario: Manager creates staff in their own brand
    Given an authenticated manager
    When a staff account with a unique username of at most 16 characters is created
    Then the response status is 201
    And the account has the requested CASHIER_STAFF role and the manager's brand

  @E2E-USER-002
  Scenario: Manager lists staff within their brand
    Given an authenticated manager
    When the brand user listing is requested with limit 5
    Then the response status is 200 with data and pagination metadata
    And every returned user belongs to the session brand
    And no returned user exposes a password hash

  @E2E-USER-003
  Scenario: Manager inspects and deactivates independently created staff
    Given an authenticated manager
    And a new staff account created by this scenario
    When the manager retrieves that account
    Then its brand matches the session brand
    When the manager deactivates it
    Then the response status is 200
    And the default account read returns 404
    When the account is retrieved with activeOnly false
    Then it is returned with is_active false

  @E2E-USER-004
  Scenario: Cashier cannot list brand users
    Given an authenticated cashier
    When the cashier requests their brand's user listing
    Then the response status is 403

  @E2E-USER-005
  Scenario: Require authentication for user administration
    Given no session token
    When the global user listing is requested
    Then the response status is 401
