@backend @unit @menu
Feature: Additional menu unit coverage
  Feature ID: FEAT-SAFE-UT-ADDITIONAL
  Requirement ID: FR-SAFE-001

  As a backend maintainer,
  I want the menu behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/safe-menu.interceptor.spec.ts
  # Context: Safe MENU projection
  @UT-SAFE-001
  Scenario: Drops entire confidential relations and unknown fields at every nesting level
    Test Case ID: UT-SAFE-001
    Given a menu response containing confidential relations and unknown nested fields
    When the safe menu interceptor maps the response
    Then confidential relations and unknown fields are removed recursively

  # Jest: server/src/modules/menu/safe-menu.interceptor.spec.ts
  # Context: Safe MENU projection
  @UT-SAFE-002
  Scenario: Preserves prices, timestamps, nulls and availability
    Test Case ID: UT-SAFE-002
    Given a menu response containing prices, timestamps, nulls, and availability
    When the safe menu interceptor maps the response
    Then safe values are preserved
