@backend @e2e @robot @brands
Feature: Brand administration and scoped access
  These scenarios use current role names and real sessions from shared E2E fixtures.

  @E2E-BRND-001
  Scenario: Manager retrieves a fixture brand
    Given an authenticated manager
    When a fixture brand is retrieved
    Then the response status is 200 and the brand ID matches the fixture brand

  @E2E-BRND-002
  Scenario: Superadmin updates a brand name
    Given an authenticated superadmin
    When a fixture brand name is updated
    Then the update returns 200 with the supplied name
    And a subsequent read returns the same saved name

  @E2E-BRND-003
  Scenario: Superadmin creates a brand without assigning users
    Given an authenticated superadmin
    When a brand with a unique four-character code is created
    Then the response status is 201 with a brand ID and that code
    And retrieving the new brand returns the same ID
    And the new brand ID is tracked for fixture cleanup

  @E2E-BRND-004
  Scenario: Manager can list all brands
    Given an authenticated manager
    When the global brand listing is requested with limit 100
    Then the response status is 200
    And both fixture brands are included

  @E2E-BRND-005
  Scenario: Manager cannot edit a brand configuration
    Given an authenticated manager and the current brand name
    When the manager attempts to update that name
    Then the response status is 403
    And a subsequent read preserves the original name

  @E2E-BRND-006
  Scenario: Manager cannot create a brand
    Given an authenticated manager
    When a new brand is submitted
    Then the response status is 403
