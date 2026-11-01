@backend @integration @menu-channels
Feature: Additional menu channels integration coverage
  Feature ID: FEAT-MCH-IT-ADDITIONAL
  Requirement ID: FR-MCH-001

  As a backend maintainer,
  I want the menu channels behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.http.spec.ts
  # Context: Menu channels HTTP endpoints
  @IT-MCH-008
  Scenario: Documents every channel route, query filters, and payload contract
    Test Case ID: IT-MCH-008
    Given the generated menu channel OpenAPI document
    When every channel route is inspected
    Then route descriptions, query filters, and payload contracts are documented

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.http.spec.ts
  # Context: Menu channels HTTP endpoints
  @IT-MCH-009
  Scenario: Forward validated channel arguments through the controller
    Test Case ID: IT-MCH-009
    Given validated route arguments and bypassed authentication guards in the controller fixture
    When a menu channel endpoint is requested
    Then the corresponding service handler receives the expected arguments

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.http.spec.ts
  # Context: Menu channels HTTP endpoints
  @IT-MCH-010
  Scenario: Reject invalid endpoint input before calling the service
    Test Case ID: IT-MCH-010
    Given invalid channel payloads, identifiers, or filters
    When a menu channel endpoint is requested
    Then the response is 400 before calling the service
