*** Settings ***
Resource          common.resource
Resource          auth_keywords.resource

*** Keywords ***
An authenticated session exists for role "${role}"
    A registered test user exists with role "${role}"
    The client submits valid login credentials to "/api/auth/login"
    The response should contain an active session token

The client submits a new user payload with username "${username}" and role "${role}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    username=${username}    first_name=Robot    last_name=Created    password=Password123!    role=${role}
    ${response}=   POST On Session      api    /api/users    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        Set Suite Variable    ${CREATED_USER_ID}    ${body}[user_id]
        Set Suite Variable    ${CREATED_USERNAME}   ${username}
    END

The client lists users with limit "${limit}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    url=/api/users?page=1&limit=${limit}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client assigns the created user to the owner brand
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${brands_resp}=    GET On Session    api    /api/brands    headers=${headers}    expected_status=any
    ${brands_body}=    Set Variable      ${brands_resp.json()}
    ${first_brand}=    Set Variable      ${brands_body}[data][0]
    ${brand_id}=       Set Variable      ${first_brand}[brand_id]
    Set Suite Variable    ${ASSIGNED_BRAND_ID}    ${brand_id}
    ${payload}=        Create Dictionary    username=${CREATED_USERNAME}    brand_id=${brand_id}
    ${response}=       POST On Session      api    /api/brands/assign    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        Set Suite Variable    ${ASSIGNED_BRAND_ASSIGNMENT_ID}    ${body}[assignment_id]
    END

The client retrieves the created user
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/users/${CREATED_USER_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client deactivates the created user
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   DELETE On Session    api    /api/users/${CREATED_USER_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client deactivates the created user brand assignment
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   DELETE On Session    api    /api/brands/${ASSIGNED_BRAND_ID}/assignments/${ASSIGNED_BRAND_ASSIGNMENT_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client requests users without authentication
    ${response}=   GET On Session       api    /api/users    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
