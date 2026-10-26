*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           OperatingSystem
Library           String

*** Variables ***
${API_BASE_URL}           %{API_BASE_URL=http://localhost:3000}
${E2E_FIXTURE_FILE}       ${CURDIR}/../.fixtures/e2e.json

*** Keywords ***
Initialize API Session
    File Should Exist    ${E2E_FIXTURE_FILE}    Run npm run test:e2e:prepare against the API test database first.
    ${text}=    Get File    ${E2E_FIXTURE_FILE}
    ${manifest}=    Evaluate    json.loads($text)    modules=json
    Set Suite Variable    ${CATALOG}    ${manifest}[fixture]
    Set Suite Variable    ${CATALOG_PASSWORD}    ${manifest}[password]
    Set Suite Variable    ${CATALOG_PIN}    ${manifest}[fixture][pin]
    Create Session    api    ${API_BASE_URL}

The backend server is running against the test database
    ${resp}=    GET On Session    api    /api/auth/me    expected_status=any
    Should Be Equal As Integers    ${resp.status_code}    401

The HTTP response status should be ${expected_status}
    Status Should Be    ${expected_status}    ${LAST_RESPONSE}

The response JSON should contain key "${key}"
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Dictionary Should Contain Key    ${body}    ${key}

The response JSON key "${key}" should be equal to "${expected_value}"
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    ${val}=     Get From Dictionary    ${body}    ${key}
    Should Be Equal As Strings    ${val}    ${expected_value}
