@backend @integration @users
Feature: Additional users integration coverage
  Feature ID: FEAT-USER-IT-ADDITIONAL
  Requirement ID: FR-USER-001

  As a backend maintainer,
  I want the users behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-011
  Scenario: Allow managers and superadmins to list users globally
    Test Case ID: IT-USER-011
    Given an authenticated manager or superadmin
    When users are listed with page 2 and limit 5
    Then the response is 200 and global pagination reaches the service

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-012
  Scenario: Removes the brand-specific user listing
    Test Case ID: IT-USER-012
    Given the legacy brand-specific user listing path
    When that path is requested
    Then the response is 404

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-013
  Scenario: Rejects brand assignments on user creation
    Test Case ID: IT-USER-013
    Given a user creation payload contains brand_id
    When the account is created
    Then the response is 400 because brand assignments are not accepted

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-014
  Scenario: Protect superadmin targets through role authorization over HTTP
    Test Case ID: IT-USER-014
    Given a superadmin target and a manager or superadmin caller
    When the target is updated or deactivated over HTTP
    Then only the superadmin caller is permitted to modify it

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-015
  Scenario: Reports current role names when a legacy role is supplied
    Test Case ID: IT-USER-015
    Given a user payload supplies an obsolete role name
    When user creation is requested
    Then the response is 400 and validation names current supported roles

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-016
  Scenario: Allows managers to update and deactivate users across brands
    Test Case ID: IT-USER-016
    Given an authenticated manager and an account formerly associated with another brand
    When the account is updated and deactivated
    Then both operations succeed using the manager's role permissions

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-017
  Scenario: Allow username-only account updates
    Test Case ID: IT-USER-017
    Given a valid username-only update
    When the user is updated over HTTP
    Then the response is 200 without requiring other profile fields

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-018
  Scenario: Preserves the username availability conflict response
    Test Case ID: IT-USER-018
    Given the service reports a username availability conflict
    When a username is updated
    Then the response preserves 409 and USERNAME_ALREADY_EXISTS

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-019
  Scenario: Returns a conflict when a username update violates uniqueness
    Test Case ID: IT-USER-019
    Given a concurrent username update violates the database uniqueness constraint
    When the username is saved
    Then the global filter returns 409 with DUPLICATE_RESOURCE

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-020
  Scenario: Allows username lookups through the GET route
    Test Case ID: IT-USER-020
    Given an authenticated employee and a username identifier
    When the user is requested through GET
    Then the safe username lookup receives activeOnly true

  # Jest: server/src/modules/users/tests/users.http.spec.ts
  # Context: Users HTTP endpoints (IT-USER)
  @IT-USER-021
  Scenario: Delegates superadmin requests to the current service contracts
    Test Case ID: IT-USER-021
    Given an authenticated superadmin
    When user creation, listing, lookup, password update, and deactivation are requested
    Then the current service contracts receive validated inputs and superadmin authority
