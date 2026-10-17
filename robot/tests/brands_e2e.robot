*** Settings ***
Documentation     Feature: Multi-Brand Management E2E API Flow
...               As an authorized Owner,
...               I want to inspect brands, manage brand configurations, and assign users to brands,
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
E2E-BRND-001: Owner lists available brands
    [Documentation]    Verify that an Owner can list all configured brands with pagination.
    [Tags]             E2E    BRANDS    E2E-BRND-001    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    When The client lists all brands
    Then the HTTP response status should be 200
    And The response JSON should contain key "data"
    And The response JSON should contain key "meta"

E2E-BRND-002: Owner updates a brand's configuration
    [Documentation]    Verify that an Owner can update an existing brand's name.
    [Tags]             E2E    BRANDS    E2E-BRND-002    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    And The client lists all brands
    When The client updates the target brand name to "Gamcheon Premium Kitchen"
    Then the HTTP response status should be 200
    And The response JSON key "name" should be equal to "Gamcheon Premium Kitchen"

E2E-BRND-003: Owner creates a new brand
    [Documentation]    Verify that an Owner can successfully create a new brand.
    [Tags]             E2E    BRANDS    E2E-BRND-003    FR-001
    Given the backend server is running against the test database
    And An authenticated session exists for role "OWNER"
    ${random_suffix}=  Generate Random String    4    [NUMBERS]
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    name=New Brand ${random_suffix}
    ${response}=   POST On Session      api    /api/brands    headers=${headers}    json=${payload}    expected_status=any
    Status Should Be    201    ${response}
    ${body}=       Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${body}    brand_id
    Dictionary Should Contain Key    ${body}    code
    Dictionary Should Contain Key    ${body}    name
