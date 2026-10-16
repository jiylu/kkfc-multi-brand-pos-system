*** Settings ***
Documentation     Feature: User Management E2E API Flow
...               As an authorized Owner,
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
E2E-USER-001: Owner creates a new staff account
    [Documentation]    Verify that an Owner can successfully provision a new staff user.
    [Tags]             E2E    USERS    E2E-USER-001    FR-USER-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    ${random_suffix}=  Generate Random String    6    [NUMBERS]
    When The client submits a new user payload with username "e2e_cashier_${random_suffix}" and role "ORDER_STAFF"
    Then the HTTP response status should be 201
    And The response JSON should contain key "user_id"
    And The response JSON key "role" should be equal to "ORDER_STAFF"

E2E-USER-002: Owner retrieves paginated user list
    [Documentation]    Verify that user accounts can be listed with pagination metadata.
    [Tags]             E2E    USERS    E2E-USER-002    FR-USER-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client lists users with limit "5"
    Then the HTTP response status should be 200
    And The response JSON should contain key "data"
    And The response JSON should contain key "meta"

E2E-USER-003: Owner inspects and deactivates created user
    [Documentation]    Verify that an Owner can fetch and deactivate an existing user.
    [Tags]             E2E    USERS    E2E-USER-003    FR-USER-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client retrieves the created user
    Then the HTTP response status should be 200
    When The client deactivates the created user
    Then the HTTP response status should be 200
    And The response JSON key "is_active" should be equal to "False"

E2E-USER-004: Non-owner staff is denied access to user management
    [Documentation]    Verify that non-owner staff cannot access user administration.
    [Tags]             E2E    USERS    E2E-USER-004    FR-USER-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "ORDER_STAFF"
    When The client lists users with limit "5"
    Then the HTTP response status should be 403

E2E-USER-005: Unauthenticated access is denied
    [Documentation]    Verify that unauthenticated requests to user management are rejected.
    [Tags]             E2E    USERS    E2E-USER-005    FR-USER-001
    Given the backend server is running against the test database
    When The client requests users without authentication
    Then the HTTP response status should be 401
