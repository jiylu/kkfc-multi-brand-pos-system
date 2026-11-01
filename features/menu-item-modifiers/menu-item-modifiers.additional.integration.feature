@backend @integration @menu-item-modifiers
Feature: Additional menu item modifiers integration coverage
  Feature ID: FEAT-MIM-IT-ADDITIONAL
  Requirement ID: FR-MIM-001

  As a backend maintainer,
  I want the menu item modifiers behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-001
  Scenario: Attaches authentication before the role guard at controller level
    Test Case ID: IT-MIM-001
    Given the modifier assignment controller metadata
    When its guard order is inspected
    Then authentication precedes role authorization

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-002
  Scenario: Documents every guarded route and preserves the create/update contracts
    Test Case ID: IT-MIM-002
    Given the generated assignment OpenAPI document
    When guarded routes and request schemas are inspected
    Then security, response schemas, and create and update contracts are documented

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-003
  Scenario: Returns assignment and modifier details while excluding confidential nested fields
    Test Case ID: IT-MIM-003
    Given the service returns assignment details with confidential nested fields
    When an authenticated client reads the assignment
    Then safe assignment and modifier details are returned while confidential fields are removed

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-004
  Scenario: Allow managers to access modifier assignments
    Test Case ID: IT-MIM-004
    Given an authenticated manager and an assignment under a fixture brand
    When the assignment endpoint is requested
    Then the response is 200 and the service handler runs once

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-005
  Scenario: Allow managers to access assignments across brands
    Test Case ID: IT-MIM-005
    Given an authenticated manager with another legacy fixture brand value
    When an assignment endpoint is requested
    Then shared brand access permits the operation

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-006
  Scenario: Allow managers to access assignments across brands
    Test Case ID: IT-MIM-006
    Given an authenticated manager without relying on a fixture brand assignment
    When an assignment endpoint is requested
    Then shared brand access permits the operation

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-007
  Scenario: Allow superadmin assignment access across brands
    Test Case ID: IT-MIM-007
    Given an authenticated superadmin and an assignment under another brand
    When an assignment endpoint is requested
    Then the response is 200 and the handler runs once

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-008
  Scenario: Preserve missing-assignment service responses
    Test Case ID: IT-MIM-008
    Given the assignment service reports a missing record
    When a guarded assignment endpoint is requested
    Then the response is 404 with MENU_ITEM_MODIFIER_NOT_FOUND

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-009
  Scenario: Reject malformed assignment UUIDs before querying
    Test Case ID: IT-MIM-009
    Given an invalid assignment UUID
    When a guarded assignment endpoint is requested
    Then the response is 400 before persistence or service calls

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-010
  Scenario: Preserve assignment lookup failures
    Test Case ID: IT-MIM-010
    Given the assignment service raises a lookup error
    When a guarded assignment endpoint is requested
    Then the response is 500 rather than a successful result

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-011
  Scenario: Resolves unavailable assignments so their owner can reactivate them
    Test Case ID: IT-MIM-011
    Given an unavailable modifier assignment
    When an authorized manager requests reactivation
    Then the assignment remains resolvable and reactivation returns 200

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-012
  Scenario: Rejects a spoofed body brand that conflicts with the stored assignment brand
    Test Case ID: IT-MIM-012
    Given an update body attempts to supply a brand_id
    When an assignment update is requested
    Then the response is 400 without updating the assignment

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-013
  Scenario: Rejects changing the parent menu item in the update body
    Test Case ID: IT-MIM-013
    Given an update body attempts to change menu_item_id
    When an assignment update is requested
    Then the response is 400 without moving the assignment

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-014
  Scenario: Delegate authenticated assignment requests with validated arguments
    Test Case ID: IT-MIM-014
    Given a valid authenticated session and a valid assignment request
    When an assignment endpoint is requested
    Then the session is validated and the handler receives the expected arguments and returns the documented status

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-015
  Scenario: Reject assignment requests without a session token
    Test Case ID: IT-MIM-015
    Given no bearer token
    When an assignment endpoint is requested
    Then the response is 401 before session validation or service calls

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-016
  Scenario: Reject assignment requests with an invalid session
    Test Case ID: IT-MIM-016
    Given the bearer session is invalid
    When an assignment endpoint is requested
    Then the response is 401 without calling the service

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-017
  Scenario: Transform assignment listing query filters
    Test Case ID: IT-MIM-017
    Given valid assignment query filters
    When an assignment listing is requested
    Then the response is 200 and transformed filters reach the appropriate handler

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-018
  Scenario: Reject invalid endpoint input before calling the service
    Test Case ID: IT-MIM-018
    Given invalid assignment input
    When an assignment endpoint is requested
    Then the response is 400 before calling any handler

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-019
  Scenario: Preserves missing-assignment errors
    Test Case ID: IT-MIM-019
    Given the service reports MENU_ITEM_MODIFIER_NOT_FOUND
    When an assignment is read
    Then the response preserves the 404 and error code

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.http.spec.ts
  # Context: Menu item modifiers HTTP endpoints
  @IT-MIM-020
  Scenario: Preserves reactivation conflicts
    Test Case ID: IT-MIM-020
    Given the service reports an already-available assignment
    When reactivation is requested
    Then the response is 409 with MENU_ITEM_MODIFIER_ALREADY_ACTIVE
