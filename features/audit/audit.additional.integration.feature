@backend @integration @audit
Feature: Additional audit integration coverage
  Feature ID: FEAT-AUDIT-IT-ADDITIONAL
  Requirement ID: FR-AUDIT-001

  As a backend maintainer,
  I want the audit behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-001
  Scenario: Returns an empty paginated list with stable newest-first ordering
    Test Case ID: IT-AUDIT-001
    Given an authorized session and no audit records
    When audit history is listed
    Then an empty paginated response is returned with stable newest-first ordering

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-002
  Scenario: Apply the same audit filters to records and totals
    Test Case ID: IT-AUDIT-002
    Given an authorized session and valid audit filters
    When filtered audit history is requested
    Then records and total count use identical filters in a consistent transaction

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-003
  Scenario: Reject unauthorized audit readers before querying
    Test Case ID: IT-AUDIT-003
    Given a role without audit-history permission
    When audit history is requested
    Then the response is 403 before querying records

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-004
  Scenario: Requires authentication
    Test Case ID: IT-AUDIT-004
    Given no authenticated session
    When audit history is requested
    Then the response is 401

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-005
  Scenario: Rejects expired or invalid sessions
    Test Case ID: IT-AUDIT-005
    Given an expired or invalid bearer session
    When audit history is requested
    Then the response is 401 before querying records

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-006
  Scenario: Reject invalid audit query parameters
    Test Case ID: IT-AUDIT-006
    Given invalid audit filters or pagination
    When audit history is requested
    Then the response is 400 before querying records

  # Jest: server/src/modules/audit/tests/audit.http.spec.ts
  # Context: Audit list HTTP API
  @IT-AUDIT-007
  Scenario: Keep audit history read-only
    Test Case ID: IT-AUDIT-007
    Given an authenticated client attempts to modify audit history
    When a POST, PATCH, PUT, or DELETE endpoint is requested
    Then the route returns 404 because audit history is read-only
