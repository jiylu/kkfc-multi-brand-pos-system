*** Settings ***
Resource          catalog_keywords.resource

*** Keywords ***
A queued kitchen ticket exists
    Set Test Variable    ${MENU_ID}    ${CATALOG}[item][menu_item_id]
    Set Test Variable    ${ORDER_PATH}    /api/brands/${CATALOG}[brand][brand_id]/orders
    A cashier has a unique order payload
    The cashier creates the draft
    The cashier verifies and confirms the draft
    Set Test Variable    ${TICKET_ID}    ${CONFIRMED}[kitchen_tickets_order][kitchen_ticket_id]
    ${headers}=    An authenticated catalog user exists    5
    Set Test Variable    ${KITCHEN_HEADERS}    ${headers}
    ${headers}=    An authenticated catalog user exists    4
    Set Test Variable    ${HEAD_HEADERS}    ${headers}

Kitchen staff claim the ticket as preparer
    ${payload}=    Create Dictionary    preparer_id=${CATALOG}[users][5][user_id]
    ${response}=    PATCH On Session    api    /api/kitchen-ticket/${TICKET_ID}/preparer    headers=${KITCHEN_HEADERS}    json=${payload}    expected_status=200
    Should Be Equal    ${response.json()}[preparer_id]    ${CATALOG}[users][5][user_id]

The kitchen head assigns the checker
    ${payload}=    Create Dictionary    checker_id=${CATALOG}[users][4][user_id]
    ${response}=    PATCH On Session    api    /api/kitchen-ticket/${TICKET_ID}/checker    headers=${HEAD_HEADERS}    json=${payload}    expected_status=200
    Should Be Equal    ${response.json()}[checker_id]    ${CATALOG}[users][4][user_id]

The saved ticket contains both assignments
    ${response}=    GET On Session    api    /api/kitchen-ticket/${TICKET_ID}    headers=${KITCHEN_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[preparer_id]    ${CATALOG}[users][5][user_id]
    Should Be Equal    ${body}[checker_id]    ${CATALOG}[users][4][user_id]
    Should Be Equal    ${body}[status]    QUEUED

The ticket appears in today's and assignee listings
    ${paths}=    Create List    /today    /preparer/${CATALOG}[users][5][user_id]    /checker/${CATALOG}[users][4][user_id]
    FOR    ${path}    IN    @{paths}
        ${response}=    GET On Session    api    /api/kitchen-ticket${path}    headers=${KITCHEN_HEADERS}    expected_status=200
        ${body}=    Set Variable    ${response.json()}
        ${ids}=    Evaluate    [ticket['kitchen_ticket_id'] for ticket in $body]
        List Should Contain Value    ${ids}    ${TICKET_ID}
    END

The kitchen head attempts to replace the preparer
    ${payload}=    Create Dictionary    preparer_id=${CATALOG}[users][4][user_id]
    ${response}=    PATCH On Session    api    /api/kitchen-ticket/${TICKET_ID}/preparer    headers=${HEAD_HEADERS}    json=${payload}    expected_status=409
    Should Be Equal    ${response.json()}[code]    KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED

The original preparer is preserved
    ${response}=    GET On Session    api    /api/kitchen-ticket/${TICKET_ID}    headers=${KITCHEN_HEADERS}    expected_status=200
    Should Be Equal    ${response.json()}[preparer_id]    ${CATALOG}[users][5][user_id]

Kitchen staff attempt to assign a checker
    ${payload}=    Create Dictionary    checker_id=${CATALOG}[users][5][user_id]
    PATCH On Session    api    /api/kitchen-ticket/${TICKET_ID}/checker    headers=${KITCHEN_HEADERS}    json=${payload}    expected_status=403

The checker remains unassigned
    ${response}=    GET On Session    api    /api/kitchen-ticket/${TICKET_ID}    headers=${HEAD_HEADERS}    expected_status=200
    Should Be Equal    ${response.json()}[checker_id]    ${None}

The cashier attempts to read and claim the kitchen ticket
    GET On Session    api    /api/kitchen-ticket/${TICKET_ID}    headers=${CASHIER_HEADERS}    expected_status=403
    ${payload}=    Create Dictionary    preparer_id=${CATALOG}[users][1][user_id]
    PATCH On Session    api    /api/kitchen-ticket/${TICKET_ID}/preparer    headers=${CASHIER_HEADERS}    json=${payload}    expected_status=403

The preparer remains unassigned
    ${response}=    GET On Session    api    /api/kitchen-ticket/${TICKET_ID}    headers=${HEAD_HEADERS}    expected_status=200
    Should Be Equal    ${response.json()}[preparer_id]    ${None}
