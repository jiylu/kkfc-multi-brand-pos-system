@backend @unit @pin
Feature: Additional pin unit coverage
  Feature ID: FEAT-PIN-UT-ADDITIONAL
  Requirement ID: FR-PIN-001

  As a backend maintainer,
  I want the pin behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-001
  Scenario: Creates a missing PIN and preserves its leading zero
    Test Case ID: UT-PIN-001
    Given an active user without a PIN and the PIN 0123
    When the user configures their PIN
    Then the credential is created with its leading zero preserved

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-002
  Scenario: Rejects setup when the user already has a PIN
    Test Case ID: UT-PIN-002
    Given an existing PIN credential
    When the user attempts PIN setup again
    Then EXISTING_PIN_FOUND is returned without replacing the credential

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-003
  Scenario: Reads safe PIN credentials for an existing active user
    Test Case ID: UT-PIN-003
    Given an active user with safe PIN metadata
    When the PIN status is retrieved
    Then only the safe credential lookup is used

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-004
  Scenario: Rejects a lookup when the active-user query returns no user
    Test Case ID: UT-PIN-004
    Given the active user does not exist
    When the PIN status is retrieved
    Then a not-found error is returned before querying PIN metadata

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-005
  Scenario: Returns null when an existing user has no PIN configured
    Test Case ID: UT-PIN-005
    Given an active user without a configured PIN
    When the PIN status is retrieved
    Then null is returned

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-006
  Scenario: Return each PIN verification state unchanged for the guard
    Test Case ID: UT-PIN-006
    Given a PIN verification result of valid, invalid, not-configured, or locked
    When the service verifies the supplied PIN
    Then the repository result is returned unchanged for the guard to interpret

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-007
  Scenario: Propagates verification errors instead of treating them as a valid PIN
    Test Case ID: UT-PIN-007
    Given PIN verification fails in the repository
    When the PIN is verified
    Then the failure is propagated rather than accepting the PIN

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-008
  Scenario: Updates the PIN after verifying the current account password
    Test Case ID: UT-PIN-008
    Given an active user and their correct account password
    When the PIN is reset
    Then the password hash is verified before updating the credential

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-009
  Scenario: Rejects an incorrect password without changing the PIN
    Test Case ID: UT-PIN-009
    Given an incorrect account password
    When a PIN reset is requested
    Then INVALID_CREDENTIALS is returned without updating the PIN

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-010
  Scenario: Rejects a reset when the active-user credential query returns no user
    Test Case ID: UT-PIN-010
    Given no active credentials exist for the user
    When a PIN reset is requested
    Then a not-found error is returned without password verification or PIN updates

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-011
  Scenario: Allows repeated resets when the account password is correct
    Test Case ID: UT-PIN-011
    Given the correct account password and two new PIN values
    When two PIN resets are requested
    Then both passwords are verified and both updates are persisted in order

  # Jest: server/src/modules/pin/tests/pin.service.spec.ts
  # Context: PinService
  @UT-PIN-012
  Scenario: Propagates password verification errors without changing the PIN
    Test Case ID: UT-PIN-012
    Given password verification raises an error
    When a PIN reset is requested
    Then the error is propagated without changing the PIN
