*** Settings ***
Resource          common.resource
Resource          auth_keywords.resource

*** Keywords ***
An authenticated session exists for role "${role}"
    A registered test user exists with role "${role}"
    The client submits valid login credentials to "/api/auth/login"
    The HTTP response status should be 200
    The response should contain an active session token

The client creates a unique staff account
    ${suffix}=    Evaluate    uuid.uuid4().hex[:10]    modules=uuid
    The client submits a new user payload with username "e2e_${suffix}" and role "CASHIER_STAFF"

A staff account exists in the manager's brand
    The client creates a unique staff account
    The HTTP response status should be 201

The client submits a new user payload with username "${username}" and role "${role}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    username=${username}    first_name=Robot    last_name=Created    password=Password123!    role=${role}    brand_id=${SESSION_BRAND_ID}
    ${response}=   POST On Session      api    /api/users    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        Set Test Variable    ${CREATED_USER_ID}    ${body}[user_id]
        Set Test Variable    ${CREATED_USERNAME}   ${username}
    END

The client lists users with limit "${limit}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    url=/api/users/brand/${SESSION_BRAND_ID}?page=1&limit=${limit}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

Every listed user belongs to the session brand
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    ${users}=    Set Variable    ${body}[data]
    Should Not Be Empty    ${users}
    FOR    ${user}    IN    @{users}
        Should Be Equal    ${user}[brand_id]    ${SESSION_BRAND_ID}
        Dictionary Should Not Contain Key    ${user}    password_hash
    END

The client retrieves the created user including inactive accounts
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=    GET On Session    api    url=/api/users/${CREATED_USER_ID}?activeOnly=false    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The created user is inactive
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Should Be Equal    ${body}[is_active]    ${False}

The client retrieves the created user
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/users/${CREATED_USER_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client deactivates the created user
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   DELETE On Session    api    /api/users/${CREATED_USER_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client requests users without authentication
    ${response}=   GET On Session       api    /api/users    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
