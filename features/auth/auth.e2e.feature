@backend @e2e @robot @auth
Feature: Authenticate and revoke real API sessions
  All scenarios use isolated fixture users through the shared Robot runner.

  @E2E-AUTH-001
  Scenario: Sign in and retrieve a protected profile
    Given an active fixture manager
    When valid credentials are posted to the login endpoint
    Then the response status is 200
    And a session token and safe user profile are returned
    When that token requests the protected profile
    Then the response status is 200

  @E2E-AUTH-002
  Scenario: Reject an incorrect password
    Given an active fixture manager
    When login uses an incorrect password
    Then the response status is 401 without a session token

  @E2E-AUTH-003
  Scenario: Reject empty credentials
    Given the API is running against the test database
    When login receives an empty username and password
    Then the response status is 400

  @E2E-AUTH-004
  Scenario: Revoke the current session on logout
    Given a manager signed in through the login endpoint
    When that manager logs out
    Then the response status is 204
    When the old token requests the protected profile
    Then the response status is 401
