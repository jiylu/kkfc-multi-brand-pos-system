@backend @integration @auth
Feature: Additional auth integration coverage
  Feature ID: FEAT-AUTH-IT-ADDITIONAL
  Requirement ID: FR-AUTH-001

  As a backend maintainer,
  I want the auth behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/auth/tests/auth.http.spec.ts
  # Context: 
  @IT-AUTH-014
  Scenario: Allow superadmins to list and look up employees globally
    Test Case ID: IT-AUTH-014
    Given an authenticated superadmin and employee accounts without brand assignments
    When global employee listing and individual lookups are requested
    Then users across the fixture data are accessible without brand scoping
