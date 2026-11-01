*** Settings ***
Documentation     Feature: User Management E2E API Flow
...               As an authorized Manager,
...               I want to create, list, inspect, and deactivate staff user accounts,
...               So that kitchen and order staff have appropriate system access.
Metadata          Feature ID        FEAT-USER-001
Metadata          Requirement ID    FR-USER-001
Resource          ../resources/common.resource
Resource          ../resources/auth_keywords.resource
Resource          ../resources/users_keywords.resource
Suite Setup       Initialize API Session
Suite Teardown    Delete All Sessions

*** Test Cases ***
E2E-USER-001: Manager creates a new staff account
    [Documentation]    Verify that a manager can provision staff using a valid username length.
    [Tags]             E2E    USERS    E2E-USER-001    FR-USER-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "MANAGER"
    When the client creates a unique staff account
    Then the HTTP response status should be 201
    And The response JSON should contain key "user_id"
    And The response JSON key "role" should be equal to "CASHIER_STAFF"
    And the response JSON should not contain brand assignments

E2E-USER-002: Manager retrieves a paginated user list globally
    [Documentation]    Verify that user accounts can be listed with pagination metadata.
    [Tags]             E2E    USERS    E2E-USER-002    FR-USER-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "MANAGER"
    When The client lists users with limit "5"
    Then the HTTP response status should be 200
    And The response JSON should contain key "data"
    And The response JSON should contain key "meta"
    And every listed user has a safe global profile

E2E-USER-003: Manager inspects and deactivates staff
    [Documentation]    Creates its own account so this case can run independently or in any suite order.
    [Tags]             E2E    USERS    E2E-USER-003    FR-USER-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "MANAGER"
    And a staff account exists
    When The client retrieves the created user
    Then the HTTP response status should be 200
    And the response JSON should not contain brand assignments
    When The client deactivates the created user
    Then the HTTP response status should be 200
    When the client retrieves the created user
    Then the HTTP response status should be 404
    When the client retrieves the created user including inactive accounts
    Then the HTTP response status should be 200
    And the created user is inactive

E2E-USER-004: Cashier cannot list users
    [Documentation]    Verify that cashier staff cannot list users through the user administration route.
    [Tags]             E2E    USERS    E2E-USER-004    FR-USER-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "CASHIER_STAFF"
    When The client lists users with limit "5"
    Then the HTTP response status should be 403

E2E-USER-005: Unauthenticated access is denied
    [Documentation]    Verify that unauthenticated requests to user management are rejected.
    [Tags]             E2E    USERS    E2E-USER-005    FR-USER-001
    Given the backend server is running against the test database
    When The client requests users without authentication
    Then the HTTP response status should be 401
