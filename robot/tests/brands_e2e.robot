*** Settings ***
Documentation     Feature: Multi-Brand Management E2E API Flow
...               As an authorized Manager or Superadmin,
...               I want to inspect and manage my own brand,
...               So that access control across brands is maintained.
Metadata          Feature ID        FEAT-BRND-001
Metadata          Requirement ID    FR-001
Resource          ../resources/common.resource
Resource          ../resources/auth_keywords.resource
Resource          ../resources/users_keywords.resource
Resource          ../resources/brands_keywords.resource
Suite Setup       Initialize API Session
Suite Teardown    Delete All Sessions

*** Test Cases ***
E2E-BRND-001: Manager retrieves their assigned brand
    [Documentation]    Verify that a manager can fetch their assigned brand.
    [Tags]             E2E    BRANDS    E2E-BRND-001    FR-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "MANAGER"
    When The client retrieves its own brand
    Then the HTTP response status should be 200
    And The response JSON key "brand_id" should be equal to "${SESSION_BRAND_ID}"

E2E-BRND-002: Superadmin updates a brand's configuration
    [Documentation]    Verify that a superadmin can update and read the saved brand name.
    [Tags]             E2E    BRANDS    E2E-BRND-002    FR-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "SUPERADMIN"
    When The client updates its own brand name to "Gamcheon Premium Kitchen"
    Then the HTTP response status should be 200
    And The response JSON key "name" should be equal to "Gamcheon Premium Kitchen"
    When the client retrieves its own brand
    Then the HTTP response status should be 200
    And the response JSON key "name" should be equal to "Gamcheon Premium Kitchen"

E2E-BRND-003: Superadmin creates a brand without a user assignment
    [Documentation]    Verify that brand creation is reserved for superadmins and persists without assigning users.
    [Tags]             E2E    BRANDS    E2E-BRND-003    FR-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "SUPERADMIN"
    When the client creates a unique brand
    Then the HTTP response status should be 201
    And The response JSON should contain key "brand_id"
    And the response JSON key "code" should be equal to "${CREATED_BRAND_CODE}"
    When the client retrieves the newly created brand
    Then the HTTP response status should be 200
    And the response JSON key "brand_id" should be equal to "${CREATED_BRAND_ID}"

E2E-BRND-004: Manager cannot list all brands
    [Documentation]    Verify that listing every brand is restricted to superadmins.
    [Tags]             E2E    BRANDS    E2E-BRND-004    FR-001
    Given the backend server is running against the test database
    And an authenticated session exists for role "MANAGER"
    When The client lists all brands
    Then the HTTP response status should be 403

E2E-BRND-005: Manager cannot update their brand configuration
    [Tags]    E2E    BRANDS    E2E-BRND-005
    Given an authenticated session exists for role "MANAGER"
    And the current brand name is recorded
    When the client updates its own brand name to "Unauthorized brand change"
    Then the HTTP response status should be 403
    And the original brand name is preserved

E2E-BRND-006: Manager cannot create a brand
    [Tags]    E2E    BRANDS    E2E-BRND-006
    Given an authenticated session exists for role "MANAGER"
    When the client creates a unique brand
    Then the HTTP response status should be 403
