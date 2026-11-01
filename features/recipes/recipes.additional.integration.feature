@backend @integration @recipes
Feature: Additional recipes integration coverage
  Feature ID: FEAT-RCP-IT-ADDITIONAL
  Requirement ID: FR-RCP-001

  As a backend maintainer,
  I want the recipes behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-001
  Scenario: Deny unapproved recipe reads and writes with safe audit records
    Test Case ID: IT-RCP-001
    Given an authenticated role without an approved recipe grant and forged authority headers
    When recipe reads and writes are requested
    Then access is denied before recipe queries and safe denial audit entries are recorded

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-002
  Scenario: Allow recipe reads and writes under approved grants
    Test Case ID: IT-RCP-002
    Given an authenticated role with an approved recipe grant
    When recipe read and write operations are requested
    Then the recipe can be read and updated without denial audit entries

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-003
  Scenario: Reject invalid or revoked recipe delegation
    Test Case ID: IT-RCP-003
    Given an invalid or revoked recipe delegation
    When recipe reads and writes are requested
    Then access is denied without writing recipes or recording attempted secret content in audit

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-004
  Scenario: Reject recipe grants whose approver authority has been revoked
    Test Case ID: IT-RCP-004
    Given the grant approver no longer has valid authority
    When recipe reads and writes are requested
    Then access is denied without recipe writes

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-005
  Scenario: Keeps read and write capabilities independent
    Test Case ID: IT-RCP-005
    Given a grant allows only one of read and write
    When recipe read and write operations are requested
    Then each capability is authorized independently

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-006
  Scenario: Looks up the requested recipe scope, ignoring forged scope in the body
    Test Case ID: IT-RCP-006
    Given a request body forges role, brand, department, or write permission
    When a recipe update is requested
    Then authorization uses the requested recipe scope and denies the forged authority

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-007
  Scenario: Denies malformed IDs before validation and does not audit untrusted ID text
    Test Case ID: IT-RCP-007
    Given a recipe identifier is malformed and contains untrusted text
    When the recipe is requested
    Then access is denied and the audit entity ID is null instead of the untrusted value

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-008
  Scenario: Rejects expired or inactive authority
    Test Case ID: IT-RCP-008
    Given the authenticated authority is expired or inactive
    When the recipe is requested
    Then access is denied

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-009
  Scenario: Still denies when audit storage fails
    Test Case ID: IT-RCP-009
    Given denial audit persistence fails
    When an unauthorized recipe read is requested
    Then the response remains a sanitized RECIPE_ACCESS_DENIED

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-010
  Scenario: Requires authentication
    Test Case ID: IT-RCP-010
    Given no authenticated session
    When a recipe is requested
    Then the response is 401

  # Jest: server/src/modules/recipe/recipes/tests/recipes.http.spec.ts
  # Context: Confidential recipes HTTP authorization
  @IT-RCP-011
  Scenario: Checks service callers as well as HTTP callers
    Test Case ID: IT-RCP-011
    Given an unapproved user calls the recipe service directly
    When read and update methods are invoked without HTTP guards
    Then the service independently denies both operations
