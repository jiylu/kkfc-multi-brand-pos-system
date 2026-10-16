Feature: Users HTTP Integration Endpoints
  Feature ID: FEAT-USER-INT
  Requirement ID: FR-USER-001

  As an API client with OWNER privileges,
  I want to perform CRUD requests on /api/users,
  So that user accounts are managed with strict validation, role enforcement, and pagination.

  Scenario: Create a user via POST /api/users
    Test Case ID: IT-USER-001
    Given an authenticated OWNER session and valid CreateUserDTO
    When the client sends POST to "/api/users"
    Then the status code should be 201

  Scenario: Reject invalid CreateUserDTO payloads
    Test Case ID: IT-USER-002
    Given an authenticated OWNER session and invalid or unwhitelisted payload
    When the client sends POST to "/api/users"
    Then the status code should be 400

  Scenario: List users with default and custom pagination
    Test Case ID: IT-USER-003
    Given an authenticated OWNER session
    When the client sends GET to "/api/users" with query parameters
    Then the status code should be 200 and return data and meta pagination

  Scenario: Reject invalid query parameters on list users
    Test Case ID: IT-USER-004
    Given an authenticated OWNER session and invalid query values
    When the client sends GET to "/api/users"
    Then the status code should be 400

  Scenario: Get single user by UUID and respect activeOnly filter
    Test Case ID: IT-USER-005
    Given an authenticated OWNER session and valid user UUID
    When the client sends GET to "/api/users/:id"
    Then the status code should be 200

  Scenario: Update existing user with valid fields
    Test Case ID: IT-USER-006
    Given an authenticated OWNER session and valid UpdateUserDTO
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 200

  Scenario: Reject invalid or non-whitelisted update fields
    Test Case ID: IT-USER-007
    Given an authenticated OWNER session and invalid update payload
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 400

  Scenario: Deactivate user via DELETE /api/users/:id
    Test Case ID: IT-USER-008
    Given an authenticated OWNER session and valid user UUID
    When the client sends DELETE to "/api/users/:id"
    Then the status code should be 200

  Scenario: Reject malformed UUID path parameters
    Test Case ID: IT-USER-009
    Given an authenticated OWNER session and non-UUID path string
    When the client sends GET, PATCH, or DELETE
    Then the status code should be 400

  Scenario: Deny non-OWNER roles across all user endpoints
    Test Case ID: IT-USER-010
    Given a non-OWNER authenticated session
    When accessing any /api/users endpoint
    Then the status code should be 403
