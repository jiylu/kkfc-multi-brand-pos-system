Feature: Mobile API Auth Interceptor
  Feature ID: FEAT-MOB-API
  Requirement ID: FR-MOB-002

  As the mobile API client layer,
  I want to attach authentication headers to outgoing requests and handle 401 responses,
  So that API requests are authenticated and unauthorized responses trigger session expiry.

  Scenario: Sends Bearer token when signed in
    Test Case ID: UT-MOB-API-001
    Given an authenticated user with a valid stored token
    When an API request is initiated through Dio
    Then the outgoing request should include the "Authorization: Bearer <token>" header

  Scenario: Sends no Authorization header when signed out
    Test Case ID: UT-MOB-API-002
    Given an unauthenticated state with null token
    When an API request is initiated through Dio
    Then the outgoing request should not contain an "Authorization" header

  Scenario: Triggers unauthorized callback on 401 response
    Test Case ID: UT-MOB-API-003
    Given an outgoing request made with an active token
    When the server responds with an HTTP 401 Unauthorized status
    Then the registered onUnauthorized callback should be invoked with the expired token
