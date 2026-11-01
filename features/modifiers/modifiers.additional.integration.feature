@backend @integration @modifiers
Feature: Additional modifiers integration coverage
  Feature ID: FEAT-MOD-IT-ADDITIONAL
  Requirement ID: FR-MOD-001

  As a backend maintainer,
  I want the modifiers behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-001
  Scenario: Documents every guarded route, payload, and query
    Test Case ID: IT-MOD-001
    Given the generated modifier OpenAPI document
    When guarded routes, payloads, and queries are inspected
    Then security, response contracts, and request schemas are documented

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-002
  Scenario: Delegate permitted modifier requests with validated arguments
    Test Case ID: IT-MOD-002
    Given an authenticated allowed role and valid modifier request
    When a modifier endpoint is requested
    Then the expected status is returned and the corresponding handler receives validated arguments

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-003
  Scenario: Require authentication on modifier endpoints
    Test Case ID: IT-MOD-003
    Given no authenticated session
    When a modifier endpoint is requested
    Then the response is 401 before session validation or service calls

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-004
  Scenario: Reject invalid sessions on modifier endpoints
    Test Case ID: IT-MOD-004
    Given an invalid bearer session
    When a modifier endpoint is requested
    Then the response is 401 before service calls

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-005
  Scenario: Allow permitted roles on modifier endpoints
    Test Case ID: IT-MOD-005
    Given a role permitted to manage modifiers
    When each protected modifier endpoint is requested
    Then every operation returns its expected success status

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-006
  Scenario: Deny unauthorized roles on modifier endpoints
    Test Case ID: IT-MOD-006
    Given a role without modifier management permission
    When each protected modifier endpoint is requested
    Then every operation returns ACCESS_DENIED without calling its handler

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-007
  Scenario: Reject invalid endpoint input before calling the service
    Test Case ID: IT-MOD-007
    Given invalid modifier request input
    When a modifier endpoint is requested
    Then the response is 400 before calling the service

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-008
  Scenario: Preserves not-found errors from the service
    Test Case ID: IT-MOD-008
    Given the service reports MODIFIER_NOT_FOUND
    When a modifier is retrieved
    Then the response preserves the 404 and error code

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.http.spec.ts
  # Context: Modifiers HTTP endpoints
  @IT-MOD-009
  Scenario: Preserves reactivation conflicts from the service
    Test Case ID: IT-MOD-009
    Given the service reports an already active modifier
    When reactivation is requested
    Then the response is 409 with MODIFIER_ALREADY_ACTIVE
