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
    IF    ${response.status_code} == 201
        ${body}=    Set Variable    ${response.json()}
        ${text}=    Get File    ${E2E_FIXTURE_FILE}
        ${manifest}=    Evaluate    json.loads($text)    modules=json
        ${ids}=    Evaluate    $manifest.setdefault('extra_brand_ids', [])
        Append To List    ${ids}    ${body}[brand_id]
        ${updated}=    Evaluate    json.dumps($manifest, indent=2)    modules=json
        Create File    ${E2E_FIXTURE_FILE}    ${updated}
        Set Test Variable    ${CREATED_BRAND_ID}    ${body}[brand_id]
    END

The client creates a unique brand
    ${code}=    Generate Random String    4    [UPPER]
    The client creates a brand named "Robot brand ${code}" with code "${code}"
    Set Test Variable    ${CREATED_BRAND_CODE}    ${code}

The client retrieves the newly created brand
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=    GET On Session    api    /api/brands/${CREATED_BRAND_ID}    headers=${headers}    expected_status=any
    Set Test Variable    ${LAST_RESPONSE}    ${response}

The original brand name is preserved
    ${headers}=    Create Dictionary    Authorization=Bearer ${SESSION_TOKEN}
    ${response}=    GET On Session    api    /api/brands/${SESSION_BRAND_ID}    headers=${headers}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[name]    ${ORIGINAL_BRAND_NAME}

The current brand name is recorded
    The client retrieves its own brand
    The HTTP response status should be 200
    ${body}=    Set Variable    ${LAST_RESPONSE.json()}
    Set Test Variable    ${ORIGINAL_BRAND_NAME}    ${body}[name]
