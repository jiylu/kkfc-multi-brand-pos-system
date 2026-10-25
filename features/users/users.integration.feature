Feature: Users HTTP Integration Endpoints
  Feature ID: FEAT-USER-INT
  Requirement ID: FR-USER-001

  As an API client with SUPERADMIN privileges,
  I want to perform CRUD requests on /api/users,
  So that user accounts are managed with strict validation, role enforcement, and pagination.

  Scenario: Create a user via POST /api/users
    Test Case ID: IT-USER-001
    Given an authenticated SUPERADMIN session and valid CreateUserDTO
    When the client sends POST to "/api/users"
    Then the status code should be 201

  Scenario: Reject invalid CreateUserDTO payloads
    Test Case ID: IT-USER-002
    Given an authenticated SUPERADMIN session and invalid or unwhitelisted payload
    When the client sends POST to "/api/users"
    Then the status code should be 400

  Scenario: List users with default and custom pagination
    Test Case ID: IT-USER-003
    Given an authenticated SUPERADMIN session
    When the client sends GET to "/api/users" with query parameters
    Then the status code should be 200 and return data and meta pagination

  Scenario: Reject invalid query parameters on list users
    Test Case ID: IT-USER-004
    Given an authenticated SUPERADMIN session and invalid query values
    When the client sends GET to "/api/users"
    Then the status code should be 400

  Scenario: Get single user by UUID and respect activeOnly filter
    Test Case ID: IT-USER-005
    Given an authenticated SUPERADMIN session and valid user UUID
    When the client sends GET to "/api/users/:id"
    Then the status code should be 200

  Scenario: Update existing user with valid fields
    Test Case ID: IT-USER-006
    Given an authenticated SUPERADMIN session and valid UpdateUserDTO
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 200

  Scenario: Reject invalid or non-whitelisted update fields
    Test Case ID: IT-USER-007
    Given an authenticated SUPERADMIN session and invalid update payload
    When the client sends PATCH to "/api/users/:id"
    Then the status code should be 400

  Scenario: Deactivate user via DELETE /api/users/:id
    Test Case ID: IT-USER-008
    Given an authenticated SUPERADMIN session and valid user UUID
    When the client sends DELETE to "/api/users/:id"
    Then the status code should be 200

  Scenario: Reject malformed UUID path parameters
    Test Case ID: IT-USER-009
    Given an authenticated SUPERADMIN session and non-UUID path string
    When the client sends PATCH or DELETE
    Then the status code should be 400

  Scenario: Restrict staff roles to reading same-brand users
    Test Case ID: IT-USER-010
    Given an authenticated staff session other than Manager or SUPERADMIN
    When listing users or updating or deactivating another user
    Then the status code should be 403

  Scenario: Cashier cannot create a Manager
    Test Case ID: IT-USER-011
    Given a migrated disposable pos_test PostgreSQL database
    And independent Cashier and Superadmin fixtures authenticated through the real login endpoint
    When the Cashier posts a same-brand Manager creation request
    Then the server returns 403
    And no candidate account is persisted

  Scenario: Deactivation invalidates access
    Test Case ID: IT-USER-012
    Given a dedicated staff account with a valid session
    When an authenticated Superadmin deactivates the staff account
    Then the database records the account as inactive
    And both existing-session access and fresh login return 401
    And user responses do not expose password fields

  Scenario: Concurrent duplicate usernames
    Test Case ID: IT-USER-013
    Given an authenticated Superadmin and a unique candidate username
    When two creation requests for that username execute concurrently
    Then exactly one returns 201 and the other returns 409
    And exactly one account is persisted
