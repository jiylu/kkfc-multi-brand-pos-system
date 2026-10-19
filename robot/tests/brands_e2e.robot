*** Settings ***
Documentation     Feature: Multi-Brand Management E2E API Flow
...               As an authorized Owner,
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
E2E-BRND-001: Owner retrieves their own brand
    [Documentation]    Verify that an Owner can fetch the brand they are assigned to.
    [Tags]             E2E    BRANDS    E2E-BRND-001    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client retrieves its own brand
    Then the HTTP response status should be 200
    And The response JSON key "brand_id" should be equal to "${SESSION_BRAND_ID}"

E2E-BRND-002: Owner updates a brand's configuration
    [Documentation]    Verify that an Owner can update their brand's name.
    [Tags]             E2E    BRANDS    E2E-BRND-002    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client updates its own brand name to "Gamcheon Premium Kitchen"
    Then the HTTP response status should be 200
    And The response JSON key "name" should be equal to "Gamcheon Premium Kitchen"

E2E-BRND-003: Owner without a brand creates a new brand
    [Documentation]    Verify that an Owner with no brand can create one.
    [Tags]             E2E    BRANDS    E2E-BRND-003    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "UNASSIGNED_OWNER"
    ${random_suffix}=  Generate Random String    4    [NUMBERS]
    When The client creates a brand named "New Brand ${random_suffix}" with code "${random_suffix}"
    Then the HTTP response status should be 201
    And The response JSON should contain key "brand_id"
    And The response JSON key "code" should be equal to "${random_suffix}"

E2E-BRND-004: Owner cannot list all brands
    [Documentation]    Verify that listing every brand is restricted to superadmins.
    [Tags]             E2E    BRANDS    E2E-BRND-004    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client lists all brands
    Then the HTTP response status should be 403
