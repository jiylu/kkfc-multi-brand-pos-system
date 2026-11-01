@backend @unit @recipes
Feature: Additional recipes unit coverage
  Feature ID: FEAT-RCP-UT-ADDITIONAL
  Requirement ID: FR-RCP-001

  As a backend maintainer,
  I want the recipes behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/recipe/recipes/tests/recipe-grants.service.spec.ts
  # Context: Recipe delegation configuration
  @UT-RCP-001
  Scenario: Defaults to no delegation and matches only exact user and recipe
    Test Case ID: UT-RCP-001
    Given no grants or a grant scoped to one exact user and recipe
    When delegation is checked
    Then access defaults to denied and only the exact user and recipe match

  # Jest: server/src/modules/recipe/recipes/tests/recipe-grants.service.spec.ts
  # Context: Recipe delegation configuration
  @UT-RCP-002
  Scenario: Deny delegation on invalid configuration without exposing its contents
    Test Case ID: UT-RCP-002
    Given invalid recipe delegation configuration
    When delegation is loaded
    Then access is denied without echoing the invalid configuration
