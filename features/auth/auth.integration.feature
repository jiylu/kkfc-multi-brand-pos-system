Feature: Authentication HTTP Integration Endpoints
  Feature ID: FEAT-AUTH-INT
  Requirement ID: FR-AUTH-001

  As an API client,
  I want to interact with /api/auth endpoints using HTTP and valid payloads,
  So that users can log in, inspect their profile, and log out with secure session handling.

  Scenario: Issues token and returns safe profile on login
    Test Case ID: IT-AUTH-001
    Given a registered user with a valid username and password
    When the client posts valid credentials to "/api/auth/login"
    Then the status code should be 200 with Cache-Control "no-store"
    And the response should contain a session token, expiration date, and user profile without password hash

  Scenario: Rejects invalid credentials without creating a session
    Test Case ID: IT-AUTH-002
    Given unknown username or incorrect password
    When the client posts to "/api/auth/login"
    Then the status code should be 401 with code INVALID_CREDENTIALS
    And no session should be recorded

  Scenario: Rejects client-supplied session fields
    Test Case ID: IT-AUTH-003
    Given a login payload containing forbidden parameters like user_id
    When the client posts to "/api/auth/login"
    Then the status code should be 400

  Scenario: Rejects missing or invalid bearer tokens on protected endpoints
    Test Case ID: IT-AUTH-004
    Given an unauthenticated request or malformed bearer header to "/api/auth/me"
    When the client sends the request
    Then the status code should be 401

  Scenario: Returns authenticated profile and updates activity timestamp
    Test Case ID: IT-AUTH-005
    Given an active bearer session token
    When the client sends GET to "/api/auth/me"
    Then the status code should be 200 and return the current user profile

  Scenario: Returns empty brand array when no brands assigned
    Test Case ID: IT-AUTH-006
    Given an active user with zero brand assignments
    When the client sends GET to "/api/auth/me"
    Then the status code should be 200 and brand_ids should be an empty list

  Scenario: Logout invalidates only current session
    Test Case ID: IT-AUTH-007
    Given two active sessions for a user
    When the client posts to "/api/auth/logout" using the first token
    Then the status code should be 204
    And the first token is invalidated while the second token remains valid

  Scenario: Logout-all revokes only requesting user sessions
    Test Case ID: IT-AUTH-008
    Given active sessions for user A and user B
    When user A posts to "/api/auth/logout-all"
    Then user A's sessions are terminated while user B's sessions remain active

  Scenario: Rejects expired sessions
    Test Case ID: IT-AUTH-009
    Given a session token that has passed expires_at
    When the client sends GET to "/api/auth/me"
    Then the status code should be 401

  Scenario: Rejects sessions after user deactivation
    Test Case ID: IT-AUTH-010
    Given a session token belonging to a deactivated user
    When the client sends GET to "/api/auth/me" or tries to log in again
    Then both requests should receive HTTP 401

  Scenario: Paginates users with activeOnly query parameter
    Test Case ID: IT-AUTH-011
    Given an authenticated OWNER session and users in database
    When the client sends GET to "/api/users" with page, limit, and activeOnly
    Then the status code should be 200 with structured data and meta pagination

  Scenario: Rejects invalid activeOnly query parameter
    Test Case ID: IT-AUTH-012
    Given an authenticated OWNER session
    When the client sends GET to "/api/users?activeOnly=invalid"
    Then the status code should be 400

  Scenario: Requires OWNER role for user management routes
    Test Case ID: IT-AUTH-013
    Given an unauthenticated or non-OWNER authenticated session
    When accessing user management endpoints
    Then it should return 401 for unauthenticated and 403 for non-OWNER
