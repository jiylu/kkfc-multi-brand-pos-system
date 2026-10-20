*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           OperatingSystem
Library           String

*** Variables ***
${API_BASE_URL}           %{API_BASE_URL=http://localhost:3000}
${TEST_OWNER_USER}        %{TEST_OWNER_USER=test_owner}
${TEST_OWNER_PASS}        %{TEST_OWNER_PASS=Password123!}
${TEST_UNASSIGNED_OWNER_USER}    %{TEST_UNASSIGNED_OWNER_USER=test_owner_unassigned}
${TEST_UNASSIGNED_OWNER_PASS}    %{TEST_UNASSIGNED_OWNER_PASS=Password123!}
${TEST_STAFF_USER}        %{TEST_STAFF_USER=test_order_staff}
${TEST_STAFF_PASS}        %{TEST_STAFF_PASS=Password123!}
${TEST_DEACT_USER}        %{TEST_DEACT_USER=test_deact_owner}
${TEST_DEACT_PASS}        %{TEST_DEACT_PASS=Password123!}
${TEST_INACTIVE_USER}     %{TEST_INACTIVE_USER=test_inactive_staff}
${TEST_INACTIVE_PASS}     %{TEST_INACTIVE_PASS=Password123!}

*** Keywords ***
Initialize API Session
    Create Session    api    ${API_BASE_URL}    verify=${False}

The backend server is running against the test database
    ${resp}=    GET On Session    api    /api/auth/me    expected_status=any
    Should Not Be Equal As Integers    ${resp.status_code}    502
    Should Not Be Equal As Integers    ${resp.status_code}    503

The HTTP response status should be ${expected_status}
    Status Should Be    ${expected_status}    ${LAST_RESPONSE}

The response JSON should contain key "${key}"
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Dictionary Should Contain Key    ${body}    ${key}

The response JSON key "${key}" should be equal to "${expected_value}"
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    ${val}=     Get From Dictionary    ${body}    ${key}
    Should Be Equal As Strings    ${val}    ${expected_value}
