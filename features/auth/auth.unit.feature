Feature: Authentication Service Unit Logic
  Feature ID: FEAT-AUTH-UNIT
  Requirement ID: FR-AUTH-001

  As the backend authentication service,
  I want to validate user credentials and manage session tokens in isolation,
  So that unauthenticated requests are rejected and authenticated sessions are securely tracked.

  Scenario: Create session for an active user with future expiration
    Test Case ID: UT-AUTH-001
    Given an active user exists in UsersRepository
    When AuthService creates a session with a valid future expiration date
    Then the session should be stored in AuthRepository and returned

  Scenario: Reject session creation for missing user
    Test Case ID: UT-AUTH-002
    Given a user does not exist in UsersRepository
    When AuthService attempts to create a session
    Then it should throw a NotFoundException

  Scenario: Reject invalid session expiration
    Test Case ID: UT-AUTH-003
    Given an active user exists in UsersRepository
    When AuthService attempts to create a session with a past or non-finite expiration date
    Then it should throw a BadRequestException with code INVALID_SESSION_EXPIRATION

  Scenario: Validate active session and update activity timestamp
    Test Case ID: UT-AUTH-004
    Given a valid unexpired session token
    When AuthService validates the token
    Then it should lookup the SHA-256 hash and update the session's last_seen_at timestamp

  Scenario: Reject empty session token
    Test Case ID: UT-AUTH-005
    Given an empty session token string
    When AuthService validates the token
    Then it should immediately throw an UnauthorizedException without querying the database

  Scenario: Reject missing or expired session
    Test Case ID: UT-AUTH-006
    Given a session token that does not exist or has expired
    When AuthService validates the token
    Then it should throw an UnauthorizedException with code EXPIRED_SESSION

  Scenario: Accept unexpired session regardless of last seen inactivity
    Test Case ID: UT-AUTH-007
    Given an unexpired session with an old last_seen_at timestamp
    When AuthService validates the token
    Then it should return the active session and user profile

  Scenario: Reject session whose user record was removed
    Test Case ID: UT-AUTH-008
    Given a valid session whose associated user cannot be found in UsersRepository
    When AuthService validates the token
    Then it should throw a NotFoundException

  Scenario: Reject session revoked concurrently between lookup and update
    Test Case ID: UT-AUTH-009
    Given a valid session that is deleted concurrently before last_seen_at update
    When AuthService updates last seen
    Then it should catch Prisma P2025 and throw an UnauthorizedException

  Scenario: Delete specified session on logout
    Test Case ID: UT-AUTH-010
    Given an active user session ID
    When AuthService deletes the session
    Then only that session record should be removed

  Scenario: Allow idempotent logout of already deleted session
    Test Case ID: UT-AUTH-011
    Given a session ID that is already deleted
    When AuthService deletes the session
    Then it should catch Prisma P2025 and return null without throwing

  Scenario: Propagate database failures and revoke all sessions for a user
    Test Case ID: UT-AUTH-012
    Given a user ID
    When AuthService deletes all sessions for the user
    Then AuthRepository deleteMany should be called and session count returned

  Scenario: Attach session and return true in Authenticated guard
    Test Case ID: UT-AUTH-013
    Given an incoming request with a valid "Bearer <token>" header
    When Authenticated guard checks authorization
    Then it should attach the session payload to the request and return true

  Scenario: Reject missing or malformed Authorization header in Authenticated guard
    Test Case ID: UT-AUTH-014
    Given an incoming request missing or having an invalid Bearer format
    When Authenticated guard checks authorization
    Then it should reject with UnauthorizedException and code SESSION_TOKEN_REQUIRED

  Scenario: Map user not found to invalid session in Authenticated guard
    Test Case ID: UT-AUTH-015
    Given an incoming request with a token whose user is deactivated or missing
    When Authenticated guard validates session
    Then it should translate NotFoundException into UnauthorizedException with code INVALID_SESSION

  Scenario: Propagate unexpected errors in Authenticated guard
    Test Case ID: UT-AUTH-016
    Given an incoming request where validateSession throws an unexpected error
    When Authenticated guard checks authorization
    Then it should rethrow the exception

  @pending
  Scenario: Pending, rejected and unenrolled accounts cannot authenticate
    Test Case ID: UT-AUTH-017
    Given an account that is pending approval, rejected or not securely enrolled
    When login or session validation is attempted
    Then the account cannot obtain or retain a session

  @pending
  Scenario: Enrollment and reset invitations cannot be replayed
    Test Case ID: UT-AUTH-018
    Given an expired, previously used or forged enrollment or reset invitation
    When the invitation is submitted
    Then it is rejected without exposing secrets
