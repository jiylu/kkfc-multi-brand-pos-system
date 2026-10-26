*** Settings ***
Resource          common.resource

*** Keywords ***
A registered test user exists with role "${role}"
    ${roles}=    Create Dictionary    MANAGER=${0}    CASHIER_STAFF=${1}    SUPERADMIN=${2}    OTHER_BRAND_MANAGER=${3}
    Dictionary Should Contain Key    ${roles}    ${role}
    ${index}=    Get From Dictionary    ${roles}    ${role}
    Set Test Variable    ${ACTIVE_USER}    ${CATALOG}[users][${index}][username]
    Set Test Variable    ${ACTIVE_PASS}    ${CATALOG_PASSWORD}

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
    Should Not Be Empty    ${body}[token]
    Dictionary Should Not Contain Key    ${body}[user]    password_hash
    Set Test Variable    ${SESSION_TOKEN}    ${body}[token]
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
