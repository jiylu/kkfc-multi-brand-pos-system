*** Settings ***
Resource          common.resource
Resource          auth_keywords.resource

*** Keywords ***
The client lists all brands
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/brands    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client retrieves its own brand
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=   GET On Session       api    /api/brands/${SESSION_BRAND_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client updates its own brand name to "${new_name}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    name=${new_name}
    ${response}=   PATCH On Session     api    /api/brands/${SESSION_BRAND_ID}    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The client creates a brand named "${name}" with code "${code}"
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}    Content-Type=application/json
    ${payload}=    Create Dictionary    name=${name}    code=${code}
    ${response}=   POST On Session      api    /api/brands    headers=${headers}    json=${payload}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}
