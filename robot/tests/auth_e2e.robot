*** Settings ***
Documentation     Feature: User Authentication E2E API Flow
...               As a registered user,
...               I want to log in using valid credentials,
...               So that I can access the application's protected features.
Metadata          Feature ID        FEAT-AUTH-001
Metadata          Requirement ID    FR-AUTH-001
Resource          ../resources/common.resource
Resource          ../resources/auth_keywords.resource
Suite Setup       Initialize API Session
Suite Teardown    Delete All Sessions

*** Test Cases ***
E2E-AUTH-001: Successful login with valid credentials
    [Documentation]    Verify that an active user can authenticate and retrieve profile data.
    [Tags]             E2E    AUTH    E2E-AUTH-001    FR-AUTH-001
    Given the backend server is running against the test database
    And a registered test user exists with role "OWNER"
    When the client submits valid login credentials to "/api/auth/login"
    Then the HTTP response status should be 200
    And the response should contain an active session token
    When the client requests the protected profile endpoint with the session token
    Then the HTTP response status should be 200

E2E-AUTH-002: Login with an incorrect password
    [Documentation]    Verify that authentication fails when an invalid password is provided.
    [Tags]             E2E    AUTH    E2E-AUTH-002    FR-AUTH-001
    Given the backend server is running against the test database
    And a registered test user exists with role "OWNER"
    When the client submits an invalid password to "/api/auth/login"
    Then the HTTP response status should be 401
    And the response should not contain a session token

E2E-AUTH-003: Login with empty credentials
    [Documentation]    Verify that ValidationPipe rejects empty login payloads.
    [Tags]             E2E    AUTH    E2E-AUTH-003    FR-AUTH-001
    Given the backend server is running against the test database
    When the client submits empty credentials to "/api/auth/login"
    Then the HTTP response status should be 400

E2E-AUTH-004: User logout and session invalidation
    [Documentation]    Verify that logging out revokes the session token.
    [Tags]             E2E    AUTH    E2E-AUTH-004    FR-AUTH-001
    Given the backend server is running against the test database
    And a registered test user exists with role "OWNER"
    When the client submits valid login credentials to "/api/auth/login"
    Then the response should contain an active session token
    When the client logs out with the session token
    Then the HTTP response status should be 204
    When the client requests the protected profile endpoint with the session token
    Then the HTTP response status should be 401
