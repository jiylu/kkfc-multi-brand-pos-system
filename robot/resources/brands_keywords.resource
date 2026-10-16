*** Settings ***
Resource          common.resource
Resource          auth_keywords.resource

*** Keywords ***
The client lists all brands
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/brands    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
    IF    ${response.status_code} == 200
        ${body}=    Set Variable    ${response.json()}
        ${first_brand}=    Set Variable    ${body}[data][0]
        Set Suite Variable    ${TARGET_BRAND_ID}    ${first_brand}[brand_id]
    END

The client updates the target brand name to "${new_name}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    name=${new_name}
    ${response}=   PATCH On Session     api    /api/brands/${TARGET_BRAND_ID}    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client assigns a user to the target brand
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    user_id=${ASSIGNMENT_USER_ID}    brand_id=${TARGET_BRAND_ID}
    ${response}=   POST On Session      api    /api/brands/assign    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        Set Suite Variable    ${ASSIGNMENT_ID}    ${body}[assignment_id]
    END

The client deactivates the brand assignment
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   DELETE On Session    api    /api/brands/assignments/${ASSIGNMENT_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client reactivates the brand assignment
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   PATCH On Session     api    /api/brands/assignments/${ASSIGNMENT_ID}/reactivate    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
