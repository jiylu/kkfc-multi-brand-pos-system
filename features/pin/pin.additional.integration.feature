@backend @integration @pin
Feature: Additional pin integration coverage
  Feature ID: FEAT-PIN-IT-ADDITIONAL
  Requirement ID: FR-PIN-001

  As a backend maintainer,
  I want the pin behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-001
  Scenario: Block protected business writes without an action PIN
    Test Case ID: IT-PIN-001
    Given an authenticated permitted caller without an action PIN
    When a protected business write is requested
    Then the response is 403 before handlers, uploads, or PIN verification run

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-002
  Scenario: Permit protected business writes after PIN verification
    Test Case ID: IT-PIN-002
    Given an authenticated permitted caller with the valid PIN 0123
    When a protected business write is requested
    Then the PIN is verified for the session user and the action runs once

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-003
  Scenario: Keep role restrictions in force even with a valid PIN
    Test Case ID: IT-PIN-003
    Given an authenticated cashier without the required role and with a correct PIN
    When a protected business write is requested
    Then the response is 403 before PIN verification or handler execution

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-004
  Scenario: Block business writes for invalid, missing, or locked PIN credentials
    Test Case ID: IT-PIN-004
    Given PIN verification reports invalid, not-configured, or locked
    When a protected business write is requested
    Then the write is blocked with 403 or 429 and locked responses include Retry-After

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-005
  Scenario: Checks the PIN for actions across brands
    Test Case ID: IT-PIN-005
    Given an authenticated manager and a valid PIN with shared brand access
    When a protected menu write targets another brand
    Then the PIN is verified and the action succeeds

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-006
  Scenario: Rejects multipart writes before uploading a file
    Test Case ID: IT-PIN-006
    Given an authenticated multipart brand creation request lacks a PIN
    When the request includes an image
    Then the response is 403 before uploading or writing

  # Jest: server/src/modules/pin/tests/pin-protected-endpoints.http.spec.ts
  # Context: PIN protection on business endpoints
  @IT-PIN-007
  Scenario: Documents all protected writes and leaves reads and availability without a required PIN
    Test Case ID: IT-PIN-007
    Given the generated business endpoint OpenAPI document
    When protected writes, reads, and availability operations are inspected
    Then only protected writes require X-Action-Pin and document cooldown responses

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-008
  Scenario: Allow authorized roles to manage their own PIN
    Test Case ID: IT-PIN-008
    Given an authenticated role permitted to manage its PIN
    When the user sets up, reads, and password-resets the PIN
    Then the correct credential operations run and responses use Cache-Control no-store

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-009
  Scenario: Deny PIN management to unauthorized roles
    Test Case ID: IT-PIN-009
    Given an authenticated role without PIN management permission
    When PIN setup, lookup, and reset are requested
    Then all responses are 403

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-010
  Scenario: Require valid sessions for PIN management
    Test Case ID: IT-PIN-010
    Given a missing or invalid bearer session
    When PIN setup, lookup, and reset are requested
    Then all responses are 401

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-011
  Scenario: Validate four-digit PIN strings on setup and reset
    Test Case ID: IT-PIN-011
    Given a PIN value outside the four-digit string contract
    When PIN setup or reset is requested
    Then the response is 400

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-012
  Scenario: Rejects a second setup without replacing the existing PIN
    Test Case ID: IT-PIN-012
    Given a user already has a PIN credential
    When PIN setup is requested again
    Then the response is 409 with EXISTING_PIN_FOUND and the credential is not replaced

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-013
  Scenario: Rejects a reset with the wrong account password
    Test Case ID: IT-PIN-013
    Given an incorrect account password
    When the PIN is reset
    Then the response is 401 with INVALID_CREDENTIALS and no PIN update

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-014
  Scenario: Require the account password for PIN reset
    Test Case ID: IT-PIN-014
    Given a reset payload omits a valid account password
    When the PIN is reset
    Then the response is 400

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-015
  Scenario: Allows repeated password-authorized resets without an action PIN
    Test Case ID: IT-PIN-015
    Given the correct account password and no action PIN header
    When two PIN resets are requested
    Then both password-authorized resets succeed

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-016
  Scenario: Rejects a body-supplied user ID
    Test Case ID: IT-PIN-016
    Given a request body attempts to supply another user ID
    When PIN setup or reset is requested
    Then the response is 400 rather than acting on the supplied user

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-017
  Scenario: Permit authorized roles to act with a valid PIN
    Test Case ID: IT-PIN-017
    Given an authenticated allowed role with a valid action PIN
    When a protected action is requested
    Then the response is 201 and the PIN is verified against the session user

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-018
  Scenario: Deny unauthorized roles even with a correct PIN
    Test Case ID: IT-PIN-018
    Given an authenticated disallowed role with a correct PIN
    When a protected action is requested
    Then the response is 403

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-019
  Scenario: Rejects a protected action without authentication
    Test Case ID: IT-PIN-019
    Given no authenticated session
    When a PIN-protected action is requested
    Then the response is 401

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-020
  Scenario: Reject missing or malformed action PIN headers
    Test Case ID: IT-PIN-020
    Given a missing or malformed X-Action-Pin header
    When a protected action is requested
    Then the response is 403 before running the handler

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-021
  Scenario: Block protected actions when PIN verification does not succeed
    Test Case ID: IT-PIN-021
    Given PIN verification reports invalid or not-configured
    When a protected action is requested
    Then the response is 403 without executing the handler

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-022
  Scenario: Blocks the handler when PIN verification fails unexpectedly
    Test Case ID: IT-PIN-022
    Given PIN verification raises an unexpected error
    When a protected action is requested
    Then the response is 500 without executing the handler

  # Jest: server/src/modules/pin/tests/pin.http.spec.ts
  # Context: PIN HTTP endpoints and guard
  @IT-PIN-023
  Scenario: Returns a rounded-up Retry-After during cooldown and blocks the handler
    Test Case ID: IT-PIN-023
    Given PIN verification reports a cooldown ending in less than two seconds
    When a protected action is requested
    Then the response is 429 with PIN_LOCKED and Retry-After rounded up to two seconds
