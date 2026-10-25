*** Settings ***
Resource          common.resource
Resource          auth_keywords.resource

*** Variables ***
${STAFF_TEST_ADMIN_USER}       %{STAFF_TEST_ADMIN_USER=test_superadmin}
${STAFF_TEST_MANAGER_USER}     %{STAFF_TEST_MANAGER_USER=test_owner}
${STAFF_TEST_CASHIER_USER}     %{STAFF_TEST_CASHIER_USER=test_order_staff}
${STAFF_TEST_FIXTURE_PASS}     %{STAFF_TEST_FIXTURE_PASS=Password123!}

*** Keywords ***
An authenticated session exists for role "${role}"
    A registered test user exists with role "${role}"
    The client submits valid login credentials to "/api/auth/login"
    The response should contain an active session token

The client submits a new user payload with username "${username}" and role "${role}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    username=${username}    first_name=Robot    last_name=Created    password=Password123!    role=${role}    brand_id=${SESSION_BRAND_ID}
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


Initialize Staff API Session
    # Explicit opt-in prevents account mutations against an accidental environment.
    Should Be Equal    %{TEST_ENVIRONMENT=unset}    disposable-test-db
    Create Session    api    ${API_BASE_URL}

Prepare Independent Staff Case
    ${ids}=    Create List
    Set Test Variable    ${STAFF_TEST_CREATED_IDS}    ${ids}
    ${tokens}=    Create List
    Set Test Variable    ${STAFF_TEST_TOKENS}    ${tokens}
    ${suffix}=    Generate Random String    8    [LOWER][NUMBERS]
    Set Test Variable    ${STAFF_TEST_USERNAME}    staff_${suffix}
    ${manager}=    Staff Sign In    ${STAFF_TEST_MANAGER_USER}    ${STAFF_TEST_FIXTURE_PASS}
    Should Be Equal    ${manager}[user][role]    MANAGER
    Should Not Be Equal    ${manager}[user][brand_id]    ${None}
    Set Test Variable    ${STAFF_TEST_BRAND}    ${manager}[user][brand_id]
    ${admin}=    Staff Sign In    ${STAFF_TEST_ADMIN_USER}    ${STAFF_TEST_FIXTURE_PASS}
    Should Be Equal    ${admin}[user][role]    SUPERADMIN
    ${headers}=    Create Dictionary    Authorization=Bearer ${admin}[token]
    Set Test Variable    ${STAFF_TEST_ADMIN_HEADERS}    ${headers}

Staff Sign In
    [Arguments]    ${username}    ${password}
    ${payload}=    Create Dictionary    username=${username}    password=${password}
    ${response}=    POST On Session    api    /api/auth/login    json=${payload}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Append To List    ${STAFF_TEST_TOKENS}    ${body}[token]
    RETURN    ${body}

The Staff Caller Is "${role}"
    IF    '${role}' == 'SUPERADMIN'
        ${body}=    Staff Sign In    ${STAFF_TEST_ADMIN_USER}    ${STAFF_TEST_FIXTURE_PASS}
    ELSE IF    '${role}' == 'MANAGER'
        ${body}=    Staff Sign In    ${STAFF_TEST_MANAGER_USER}    ${STAFF_TEST_FIXTURE_PASS}
    ELSE IF    '${role}' == 'CASHIER_STAFF'
        ${body}=    Staff Sign In    ${STAFF_TEST_CASHIER_USER}    ${STAFF_TEST_FIXTURE_PASS}
    ELSE
        Fail    Unsupported Staff fixture role
    END
    Should Be Equal    ${body}[user][role]    ${role}
    ${headers}=    Create Dictionary    Authorization=Bearer ${body}[token]
    Set Test Variable    ${STAFF_TEST_CALLER_HEADERS}    ${headers}
    IF    '${role}' != 'SUPERADMIN'
        Set Test Variable    ${STAFF_TEST_BRAND}    ${body}[user][brand_id]
    END

Staff Creation Payload
    [Arguments]    ${role}
    ${payload}=    Create Dictionary    username=${STAFF_TEST_USERNAME}    first_name=Staff    last_name=Disposable    password=${STAFF_TEST_FIXTURE_PASS}    role=${role}    brand_id=${STAFF_TEST_BRAND}
    RETURN    ${payload}

Record Unexpected Staff Creation
    [Arguments]    ${response}
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        Append To List    ${STAFF_TEST_CREATED_IDS}    ${body}[user_id]
    END

The Staff Caller Requests A "${role}" Account
    ${payload}=    Staff Creation Payload    ${role}
    ${response}=    POST On Session    api    /api/users    headers=${STAFF_TEST_CALLER_HEADERS}    json=${payload}    expected_status=any
    Record Unexpected Staff Creation    ${response}
    Set Test Variable    ${STAFF_TEST_RESPONSE}    ${response}

The Staff Creation Is Forbidden
    Should Be Equal As Integers    ${STAFF_TEST_RESPONSE.status_code}    403

The Staff Caller Supplies Forged Approval Fields
    ${payload}=    Staff Creation Payload    CASHIER_STAFF
    Set To Dictionary    ${payload}    requester_id=00000000-0000-4000-8000-000000000001    approver_id=00000000-0000-4000-8000-000000000002    status=ACTIVE
    ${response}=    POST On Session    api    /api/users    headers=${STAFF_TEST_CALLER_HEADERS}    json=${payload}    expected_status=any
    Record Unexpected Staff Creation    ${response}
    Set Test Variable    ${STAFF_TEST_RESPONSE}    ${response}

The Staff Payload Is Rejected
    Should Be Equal As Integers    ${STAFF_TEST_RESPONSE.status_code}    400

A Dedicated Active Staff Account Exists
    ${payload}=    Staff Creation Payload    CASHIER_STAFF
    ${response}=    POST On Session    api    /api/users    headers=${STAFF_TEST_ADMIN_HEADERS}    json=${payload}    expected_status=any
    Record Unexpected Staff Creation    ${response}
    Should Be Equal As Integers    ${response.status_code}    201
    ${body}=    Set Variable    ${response.json()}
    Dictionary Should Not Contain Key    ${body}    password_hash
    Dictionary Should Not Contain Key    ${body}    password
    Set Test Variable    ${STAFF_TEST_CREATED_ID}    ${body}[user_id]

The Staff Account Has Signed In
    ${body}=    Staff Sign In    ${STAFF_TEST_USERNAME}    ${STAFF_TEST_FIXTURE_PASS}
    ${headers}=    Create Dictionary    Authorization=Bearer ${body}[token]
    Set Test Variable    ${STAFF_TEST_STAFF_HEADERS}    ${headers}

The Administrator Deactivates The Staff Account
    DELETE On Session    api    /api/users/${STAFF_TEST_CREATED_ID}    headers=${STAFF_TEST_ADMIN_HEADERS}    expected_status=200
    Remove Values From List    ${STAFF_TEST_CREATED_IDS}    ${STAFF_TEST_CREATED_ID}

The Saved Staff Session Is Rejected
    GET On Session    api    /api/auth/me    headers=${STAFF_TEST_STAFF_HEADERS}    expected_status=401

The Deactivated Staff Cannot Sign In
    ${payload}=    Create Dictionary    username=${STAFF_TEST_USERNAME}    password=${STAFF_TEST_FIXTURE_PASS}
    POST On Session    api    /api/auth/login    json=${payload}    expected_status=401

The Administrator Repeats The Staff Creation
    ${payload}=    Staff Creation Payload    CASHIER_STAFF
    ${response}=    POST On Session    api    /api/users    headers=${STAFF_TEST_ADMIN_HEADERS}    json=${payload}    expected_status=any
    Record Unexpected Staff Creation    ${response}
    Set Test Variable    ${STAFF_TEST_RESPONSE}    ${response}

The Staff Username Conflict Is Reported
    Should Be Equal As Integers    ${STAFF_TEST_RESPONSE.status_code}    409

Clean Up Staff Case
    FOR    ${id}    IN    @{STAFF_TEST_CREATED_IDS}
        DELETE On Session    api    /api/users/${id}    headers=${STAFF_TEST_ADMIN_HEADERS}    expected_status=200
    END
    FOR    ${token}    IN    @{STAFF_TEST_TOKENS}
        ${headers}=    Create Dictionary    Authorization=Bearer ${token}
        POST On Session    api    /api/auth/logout    headers=${headers}    expected_status=any
    END

The Created Staff Account Is Safe And Brand Scoped
    ${response}=    GET On Session    api    /api/users/${STAFF_TEST_CREATED_ID}    headers=${STAFF_TEST_ADMIN_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[brand_id]    ${STAFF_TEST_BRAND}
    Dictionary Should Not Contain Key    ${body}    password_hash
    Dictionary Should Not Contain Key    ${body}    password

The Created Staff Account Is Inactive
    ${response}=    GET On Session    api    /api/users/${STAFF_TEST_CREATED_ID}?activeOnly=false    headers=${STAFF_TEST_ADMIN_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[is_active]    ${False}

The Staff Caller Lists Accounts
    ${response}=    GET On Session    api    /api/users?page=1&limit=5    headers=${STAFF_TEST_CALLER_HEADERS}    expected_status=any
    Set Test Variable    ${STAFF_TEST_RESPONSE}    ${response}

The Staff List Contains Pagination Metadata
    Should Be Equal As Integers    ${STAFF_TEST_RESPONSE.status_code}    200
    ${body}=    Set Variable    ${STAFF_TEST_RESPONSE.json()}
    Dictionary Should Contain Key    ${body}    data
    Dictionary Should Contain Key    ${body}    meta
