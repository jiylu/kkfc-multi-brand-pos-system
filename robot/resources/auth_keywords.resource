*** Settings ***
Resource          common.resource

*** Keywords ***
A registered test user exists with role "${role}"
    IF    '${role}' == 'OWNER'
        Set Suite Variable    ${ACTIVE_USER}    ${TEST_OWNER_USER}
        Set Suite Variable    ${ACTIVE_PASS}    ${TEST_OWNER_PASS}
    ELSE IF    '${role}' == 'UNASSIGNED_OWNER'
        Set Suite Variable    ${ACTIVE_USER}    ${TEST_UNASSIGNED_OWNER_USER}
        Set Suite Variable    ${ACTIVE_PASS}    ${TEST_UNASSIGNED_OWNER_PASS}
    ELSE IF    '${role}' == 'DEACT_OWNER'
        Set Suite Variable    ${ACTIVE_USER}    ${TEST_DEACT_USER}
        Set Suite Variable    ${ACTIVE_PASS}    ${TEST_DEACT_PASS}
    ELSE IF    '${role}' == 'INACTIVE'
        Set Suite Variable    ${ACTIVE_USER}    ${TEST_INACTIVE_USER}
        Set Suite Variable    ${ACTIVE_PASS}    ${TEST_INACTIVE_PASS}
    ELSE
        Set Suite Variable    ${ACTIVE_USER}    ${TEST_STAFF_USER}
        Set Suite Variable    ${ACTIVE_PASS}    ${TEST_STAFF_PASS}
    END

The client submits valid login credentials to "${endpoint}"
    ${payload}=    Create Dictionary    username=${ACTIVE_USER}    password=${ACTIVE_PASS}
    ${response}=   POST On Session      api    ${endpoint}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client submits an invalid password to "${endpoint}"
    ${payload}=    Create Dictionary    username=${ACTIVE_USER}    password=WrongPassword999!
    ${response}=   POST On Session      api    ${endpoint}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client submits empty credentials to "${endpoint}"
    ${payload}=    Create Dictionary    username=${EMPTY}    password=${EMPTY}
    ${response}=   POST On Session      api    ${endpoint}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The response should contain an active session token
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Dictionary Should Contain Key    ${body}    token
    Dictionary Should Contain Key    ${body}    user
    Set Test Variable    ${SESSION_TOKEN}    ${body}[token]
    ${user_id}=     Evaluate    $body['user'].get('user_id')
    Set Test Variable    ${SESSION_USER_ID}    ${user_id}
    ${brand_id}=    Evaluate    $body['user'].get('brand_id')
    Set Test Variable    ${SESSION_BRAND_ID}    ${brand_id}

The response should not contain a session token
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Dictionary Should Not Contain Key    ${body}    token

The client requests the protected profile endpoint with the session token
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/auth/me    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client logs out with the session token
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   POST On Session      api    /api/auth/logout    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client deactivates their own user account
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   DELETE On Session    api    /api/users/${SESSION_USER_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
