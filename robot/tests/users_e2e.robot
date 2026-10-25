*** Settings ***
Documentation     Feature: User Management E2E API Flow
...               As an authorized administrator,
...               I want staff account permissions and lifecycle enforced,
...               So that staff access remains controlled and traceable.
Metadata          Feature ID        FEAT-USER-001
Metadata          Requirement ID    FR-USER-001
Resource          ../resources/common.resource
Resource          ../resources/auth_keywords.resource
Resource          ../resources/users_keywords.resource
Suite Setup       Initialize Staff API Session
Test Setup        Prepare Independent Staff Case
Test Teardown     Clean Up Staff Case
Suite Teardown    Delete All Sessions

*** Test Cases ***
E2E-USER-001: Superadmin creates a new staff account
    [Tags]    E2E    USERS    E2E-USER-001    FR-USER-001
    Given the Staff caller is "SUPERADMIN"
    When a dedicated active staff account exists
    Then the created staff account is safe and brand scoped

E2E-USER-002: Superadmin retrieves paginated user list
    [Tags]    E2E    USERS    E2E-USER-002    FR-USER-001
    Given the Staff caller is "SUPERADMIN"
    When the Staff caller lists accounts
    Then the staff list contains pagination metadata

E2E-USER-003: Superadmin inspects and deactivates a staff account
    [Tags]    E2E    USERS    E2E-USER-003    FR-USER-001
    Given a dedicated active staff account exists
    And the created staff account is safe and brand scoped
    When the administrator deactivates the staff account
    Then the created staff account is inactive

E2E-USER-004: Cashier cannot list all users
    [Tags]    E2E    USERS    E2E-USER-004    FR-USER-001
    Given the Staff caller is "CASHIER_STAFF"
    When the Staff caller lists accounts
    Then the Staff creation is forbidden

E2E-USER-005: Unauthenticated access is denied
    [Tags]    E2E    USERS    E2E-USER-005    FR-USER-001
    Given the backend server is running against the test database
    When the client requests users without authentication
    Then the HTTP response status should be 401

E2E-USER-006: Deactivated staff cannot sign in or reuse an existing session
    [Tags]    E2E    USERS    E2E-USER-006    FR-USER-001
    Given a dedicated active staff account exists
    And the staff account has signed in
    When the administrator deactivates the staff account
    Then the saved staff session is rejected
    And the deactivated staff cannot sign in

E2E-USER-007: Cashier cannot create a Manager
    [Tags]    E2E    USERS    E2E-USER-007    FR-USER-001
    Given the Staff caller is "CASHIER_STAFF"
    When the Staff caller requests a "MANAGER" account
    Then the Staff creation is forbidden

E2E-USER-008: Manager cannot create a Recipe Manager
    [Tags]    E2E    USERS    E2E-USER-008    FR-USER-001
    Given the Staff caller is "MANAGER"
    When the Staff caller requests a "RECIPE_MANAGER" account
    Then the Staff creation is forbidden

E2E-USER-009: Caller cannot forge requester or approver identity
    [Tags]    E2E    USERS    E2E-USER-009    FR-USER-001
    Given the Staff caller is "MANAGER"
    When the Staff caller supplies forged approval fields
    Then the Staff payload is rejected

E2E-USER-010: Duplicate username does not create a second account
    [Tags]    E2E    USERS    E2E-USER-010    FR-USER-001
    Given a dedicated active staff account exists
    When the administrator repeats the Staff creation
    Then the Staff username conflict is reported
