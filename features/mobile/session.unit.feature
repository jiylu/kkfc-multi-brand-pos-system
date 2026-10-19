Feature: Mobile Session and Authentication Logic
  Feature ID: FEAT-MOB-AUTH
  Requirement ID: FR-MOB-001

  As the mobile client application,
  I want to manage authentication session state and tokens securely,
  So that user sessions are maintained and expired tokens are properly evicted.

  Scenario: 401 for current token signs out and flags expiry
    Test Case ID: UT-MOB-AUTH-001
    Given an active session token exists in the session provider
    And a token store contains the active credentials
    When a 401 Unauthorized status is flagged for the current token
    Then the session provider should report unauthenticated
    And the session expired flag should be set to true
    And the stored token should be cleared from secure storage

  Scenario: Late 401 for an older token does not sign out a new session
    Test Case ID: UT-MOB-AUTH-002
    Given a new active session token exists
    When an expired notification is received for an older, previous token
    Then the session provider should remain authenticated
    And the session expired flag should remain false
    And the current token in secure storage should not be cleared

  Scenario: Signing in again clears the expired session flag
    Test Case ID: UT-MOB-AUTH-003
    Given an expired session state with expired flag set to true
    When a new valid authentication token is set
    Then the session provider should report authenticated
    And the session expired flag should be reset to false
