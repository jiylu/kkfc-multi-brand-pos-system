Feature: Brands HTTP Integration Endpoints
  Feature ID: FEAT-BRND-INT
  Requirement ID: FR-001

  As an API client,
  I want to interact with /api/brands endpoints,
  So that brand records and user-brand assignments can be created, inspected, and updated.

  Scenario: Delegate brand route handlers for authenticated OWNER
    Test Case ID: IT-BRND-001
    Given an authenticated OWNER session
    When the client requests various /api/brands routes
    Then the controller should delegate to BrandsService and return HTTP 200

  Scenario: Assign user to brand via POST /api/brands/assign
    Test Case ID: IT-BRND-002
    Given an authenticated OWNER session and valid AssignUserToBrandDTO
    When the client sends POST to "/api/brands/assign"
    Then the status code should be 201

  Scenario: Reject invalid assignment bodies
    Test Case ID: IT-BRND-003
    Given an authenticated OWNER session and malformed assignment body
    When the client sends POST to "/api/brands/assign"
    Then the status code should be 400

  Scenario: Do not expose old assignment POST route
    Test Case ID: IT-BRND-004
    Given any request to the deprecated assignment POST path
    When the client sends POST
    Then the status code should be 404

  Scenario: Validate and forward brand updates via PATCH /api/brands/:id
    Test Case ID: IT-BRND-005
    Given an authenticated OWNER session and valid UpdateBrandDTO
    When the client sends PATCH to "/api/brands/:id"
    Then the status code should be 200

  Scenario: Reject invalid list queries on brands
    Test Case ID: IT-BRND-006
    Given an authenticated OWNER session and invalid query parameters
    When the client sends GET to "/api/brands"
    Then the status code should be 400

  Scenario: Reject invalid assigned-user list queries
    Test Case ID: IT-BRND-007
    Given an authenticated OWNER session and invalid query parameters
    When the client sends GET to "/api/brands/:id/users"
    Then the status code should be 400

  Scenario: Reject assigned-user listing for non-OWNER roles
    Test Case ID: IT-BRND-008
    Given an authenticated non-OWNER user session
    When the client requests "/api/brands/:id/users"
    Then the status code should be 403

  Scenario: Reject invalid assignment boolean filters
    Test Case ID: IT-BRND-009
    Given an authenticated OWNER session and non-boolean query value
    When the client requests assignment details
    Then the status code should be 400

  Scenario: Reject invalid brand update fields
    Test Case ID: IT-BRND-010
    Given an authenticated OWNER session and empty name in UpdateBrandDTO
    When the client sends PATCH to "/api/brands/:id"
    Then the status code should be 400

  Scenario: Reject malformed UUID path parameters across brand routes
    Test Case ID: IT-BRND-011
    Given an authenticated OWNER session and non-UUID string in path
    When the client sends the request
    Then the status code should be 400

  Scenario: Do not expose brand creation route
    Test Case ID: IT-BRND-012
    Given any request to POST /api/brands
    When the client sends the request
    Then the status code should be 404
