@backend @unit @audit
Feature: Additional audit unit coverage
  Feature ID: FEAT-AUDIT-UT-ADDITIONAL
  Requirement ID: FR-AUDIT-001

  As a backend maintainer,
  I want the audit behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/audit/tests/audit.service.spec.ts
  # Context: AuditService defensive boundaries
  @UT-AUDIT-001
  Scenario: Applies bounded defaults for internal callers
    Test Case ID: UT-AUDIT-001
    Given an internal caller without pagination options
    When audit history is requested
    Then page 1 with limit 10 and zero-page metadata is returned for an empty history

  # Jest: server/src/modules/audit/tests/audit.service.spec.ts
  # Context: AuditService defensive boundaries
  @UT-AUDIT-002
  Scenario: Reject invalid internal audit queries before database access
    Test Case ID: UT-AUDIT-002
    Given an invalid internal query or an overflowing pagination offset
    When audit history is requested
    Then a bad-request error is returned before database access

  # Jest: server/src/modules/audit/tests/audit.service.spec.ts
  # Context: AuditService defensive boundaries
  @UT-AUDIT-003
  Scenario: Does not mutate caller-owned query objects
    Test Case ID: UT-AUDIT-003
    Given a frozen query containing an action filter
    When audit history is requested
    Then the filter is forwarded without modifying the caller's object

  # Jest: server/src/modules/audit/tests/audit.service.spec.ts
  # Context: AuditService defensive boundaries
  @UT-AUDIT-004
  Scenario: Propagates storage failure instead of reporting an empty successful history
    Test Case ID: UT-AUDIT-004
    Given the audit repository fails
    When audit history is requested
    Then the repository error is propagated instead of returning an empty successful history
