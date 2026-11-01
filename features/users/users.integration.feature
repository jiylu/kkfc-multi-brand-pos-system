@backend @integration @users
Feature: Users HTTP Integration Endpoints
  Feature ID: FEAT-USER-INT
  Requirement ID: FR-USER-001

  As an API client with SUPERADMIN privileges,
  I want to perform CRUD requests on /api/users,
  So that user accounts are managed with strict validation, role enforcement, and pagination.

  @IT-USER-001
  Scenario: Create a user via POST /api/users
    Given an authenticated SUPERADMIN session and valid CreateUserDTO
    When the client sends POST to "/api/users"
    Then the status code should be 201

  @IT-USER-002
  Scenario: Reject invalid CreateUserDTO payloads
    Given an authenticated SUPERADMIN session and invalid or unwhitelisted payload
    When the client sends POST to "/api/users"
    Then the status code should be 400

  @IT-USER-003
  Scenario: List users with default and custom pagination
    Given an authenticated SUPERADMIN session
    When the client sends GET to "/api/users" with query parameters
    Then the status code should be 200 and return data and meta pagination

  @IT-USER-004
  Scenario: Reject invalid query parameters on list users
    Given an authenticated SUPERADMIN session and invalid query values
    When the client sends GET to "/api/users"
    Then the status code should be 400

  @IT-USER-005
  Scenario: Get single user by UUID and respect activeOnly filter
    Given an authenticated SUPERADMIN session and valid user UUID
    When the client sends GET to "/api/users/:id"
    Then the status code should be 200

  @IT-USER-006
  Scenario: Update existing user with valid fields
    Given an authenticated SUPERADMIN session and valid UpdateUserDTO
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 200

  @IT-USER-007
  Scenario: Reject invalid or non-whitelisted update fields
    Given an authenticated SUPERADMIN session and invalid update payload
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 400

  @IT-USER-008
  Scenario: Deactivate user via DELETE /api/users/:id
    Given an authenticated SUPERADMIN session and valid user UUID
    When the client sends DELETE to "/api/users/:id"
    Then the status code should be 200

  @IT-USER-009
  Scenario: Reject malformed UUID path parameters
    Given an authenticated SUPERADMIN session and non-UUID path string
    When the client sends PATCH or DELETE
    Then the status code should be 400

  @IT-USER-010
  Scenario: Restrict administration while allowing employee lookups
    Given an authenticated staff session without a management role
    When requesting GET /api/users or modifying an account
    Then the status code should be 403
    But retrieving a single user by username should return 200
