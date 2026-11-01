@backend @integration @auth
Feature: Authentication HTTP Integration Endpoints
  Feature ID: FEAT-AUTH-INT
  Requirement ID: FR-AUTH-001

  As an API client,
  I want to interact with /api/auth endpoints using HTTP and valid payloads,
  So that users can log in, inspect their profile, and log out with secure session handling.

  @IT-AUTH-001
  Scenario: Issues token and returns safe profile on login
    Given a registered user with a valid username and password
    When the client posts valid credentials to "/api/auth/login"
    Then the status code should be 200 with Cache-Control "no-store"
    And the response should contain a session token, expiration date, and user profile without password hash

  @IT-AUTH-002
  Scenario: Rejects invalid credentials without creating a session
    Given unknown username or incorrect password
    When the client posts to "/api/auth/login"
    Then the status code should be 401 with code INVALID_CREDENTIALS
    And no session should be recorded

  @IT-AUTH-003
  Scenario: Rejects client-supplied session fields
    Given a login payload containing forbidden parameters like user_id
    When the client posts to "/api/auth/login"
    Then the status code should be 400

  @IT-AUTH-004
  Scenario: Rejects missing or invalid bearer tokens on protected endpoints
    Given an unauthenticated request or malformed bearer header to "/api/auth/me"
    When the client sends the request
    Then the status code should be 401

  @IT-AUTH-005
  Scenario: Returns authenticated profile and updates activity timestamp
    Given an active bearer session token
    When the client sends GET to "/api/auth/me"
    Then the status code should be 200 and return the current user profile

  @IT-AUTH-006
  Scenario: Returns a profile without brand assignments
    Given an active employee
    When the client sends GET to "/api/auth/me"
    Then the status code should be 200 without brand_id or brand_ids

  @IT-AUTH-007
  Scenario: Logout invalidates only current session
    Given two active sessions for a user
    When the client posts to "/api/auth/logout" using the first token
    Then the status code should be 204
    And the first token is invalidated while the second token remains valid

  @IT-AUTH-008
  Scenario: Logout-all revokes only requesting user sessions
    Given active sessions for user A and user B
    When user A posts to "/api/auth/logout-all"
    Then user A's sessions are terminated while user B's sessions remain active

  @IT-AUTH-009
  Scenario: Rejects expired sessions
    Given a session token that has passed expires_at
    When the client sends GET to "/api/auth/me"
    Then the status code should be 401

  @IT-AUTH-010
  Scenario: Rejects sessions after user deactivation
    Given a session token belonging to a deactivated user
    When the client sends GET to "/api/auth/me" or tries to log in again
    Then both requests should receive HTTP 401

  @IT-AUTH-011
  Scenario: Paginates users with activeOnly query parameter
    Given an authenticated SUPERADMIN session and users in database
    When the client sends GET to "/api/users" with page, limit, and activeOnly
    Then the status code should be 200 with structured data and meta pagination

  @IT-AUTH-012
  Scenario: Rejects invalid activeOnly query parameter
    Given an authenticated SUPERADMIN session
    When the client sends GET to "/api/users?activeOnly=invalid"
    Then the status code should be 400

  @IT-AUTH-013
  Scenario: Requires a management role for user listings
    Given an unauthenticated or CASHIER_STAFF authenticated session
    When accessing GET /api/users
    Then it should return 401 for unauthenticated and 403 for CASHIER_STAFF
