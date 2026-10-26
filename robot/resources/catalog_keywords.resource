*** Settings ***
Resource    common.resource

*** Keywords ***
An isolated catalog fixture is loaded
    Initialize API Session

An authenticated catalog user exists
    [Arguments]    ${index}=0
    ${username}=    Set Variable    ${CATALOG}[users][${index}][username]
    ${payload}=    Create Dictionary    username=${username}    password=${CATALOG_PASSWORD}
    ${response}=    POST On Session    api    /api/auth/login    json=${payload}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    ${headers}=    Create Dictionary    Authorization=Bearer ${body}[token]
    IF    $body['user']['role'] in ('SUPERADMIN', 'MANAGER', 'RECIPE_MANAGER', 'SUPERVISOR', 'KITCHEN_HEAD')
        Set To Dictionary    ${headers}    X-Action-Pin=${CATALOG_PIN}
    END
    RETURN    ${headers}

A manager has created a unique menu item
    ${headers}=    An authenticated catalog user exists    0
    Set Test Variable    ${MANAGER_HEADERS}    ${headers}
    ${suffix}=    Evaluate    str(uuid.uuid4())    modules=uuid
    ${payload}=    Create Dictionary    brand_id=${CATALOG}[brand][brand_id]    recipe_id=${CATALOG}[recipe][recipe_id]
    ...    code=robot-${suffix}    name=Robot fixture meal    img_url=https://example.com/fixture.png    base_price=${100}
    ${response}=    POST On Session    api    /api/menu-items    headers=${headers}    json=${payload}    expected_status=201
    ${body}=    Set Variable    ${response.json()}
    Set Test Variable    ${MENU_ID}    ${body}[menu_item_id]
    Set Test Variable    ${MENU_CODE}    ${body}[code]
    Set Test Variable    ${ORDER_PATH}    /api/brands/${CATALOG}[brand][brand_id]/orders

The manager creates a GrabFood override
    ${payload}=    Create Dictionary    menu_item_id=${MENU_ID}    order_channel=GRABFOOD    price=${120}
    ${response}=    POST On Session    api    /api/menu-channels    headers=${MANAGER_HEADERS}    json=${payload}    expected_status=201
    ${body}=    Set Variable    ${response.json()}
    Set Test Variable    ${CHANNEL_ID}    ${body}[menu_item_channel_id]

The manager changes the channel price to 150
    ${payload}=    Create Dictionary    price=${150}
    PATCH On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    json=${payload}    expected_status=200

The saved channel price is 150
    ${response}=    GET On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Numbers    ${body}[price]    150

The manager deactivates and reactivates the channel
    DELETE On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=200
    GET On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=404
    ${response}=    GET On Session    api    url=/api/menu-channels/${CHANNEL_ID}?activeOnly=false    headers=${MANAGER_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[is_available]    ${False}
    PATCH On Session    api    /api/menu-channels/reactivate/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=200

The saved channel is available
    ${response}=    GET On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[is_available]    ${True}

A cashier has a unique order payload
    [Arguments]    ${channel}=TAKEAWAY
    ${headers}=    An authenticated catalog user exists    1
    Set Test Variable    ${CASHIER_HEADERS}    ${headers}
    ${id}=    Evaluate    str(uuid.uuid4())    modules=uuid
    ${line}=    Create Dictionary    menu_item_id=${MENU_ID}    quantity=${2}
    ${lines}=    Create List    ${line}
    ${payload}=    Create Dictionary    order_id=${id}    order_channel=${channel}    lines=${lines}
    IF    '${channel}' == 'GRABFOOD'
        Set To Dictionary    ${payload}    merchant_store_reference=robot-store    external_order_reference=${id}
    END
    Set Test Variable    ${ORDER_ID}    ${id}
    Set Test Variable    ${ORDER_PAYLOAD}    ${payload}
    ${payment}=    Create Dictionary    payment_method=CASH    payment_status=UNPAID
    IF    '${channel}' == 'GRABFOOD'
        ${payment}=    Create Dictionary
    END
    Set Test Variable    ${PAYMENT}    ${payment}

The cashier creates the draft
    ${response}=    POST On Session    api    ${ORDER_PATH}    headers=${CASHIER_HEADERS}    json=${ORDER_PAYLOAD}    expected_status=201
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[order_id]    ${ORDER_ID}
    Should Be Equal    ${body}[status]    DRAFT

The cashier verifies and confirms the draft
    ${verify}=    POST On Session    api    ${ORDER_PATH}/${ORDER_ID}/verify    headers=${CASHIER_HEADERS}    json=${PAYMENT}    expected_status=200
    ${verified}=    Set Variable    ${verify.json()}
    Should Be Equal    ${verified}[valid]    ${True}
    ${response}=    POST On Session    api    ${ORDER_PATH}/${ORDER_ID}/confirm    headers=${CASHIER_HEADERS}    json=${PAYMENT}    expected_status=200
    Set Test Variable    ${CONFIRMED}    ${response.json()}

A confirmed order and queued ticket are returned
    Should Be Equal    ${CONFIRMED}[order_id]    ${ORDER_ID}
    Should Be Equal    ${CONFIRMED}[status]    CONFIRMED
    Should Be Equal    ${CONFIRMED}[kitchen_tickets_order][status]    QUEUED
    Should Match Regexp    ${CONFIRMED}[kitchen_tickets_order][ticket_number]    ^T-\\d{3,}$
    Should Be Equal As Numbers    ${CONFIRMED}[order_items_order][0][unit_price]    100
    Dictionary Should Not Contain Key    ${CONFIRMED}[order_items_order][0]    recipe_snapshot

The cashier retries the same create and confirmation
    POST On Session    api    ${ORDER_PATH}    headers=${CASHIER_HEADERS}    json=${ORDER_PAYLOAD}    expected_status=201
    ${response}=    POST On Session    api    ${ORDER_PATH}/${ORDER_ID}/confirm    headers=${CASHIER_HEADERS}    json=${PAYMENT}    expected_status=200
    Dictionaries Should Be Equal    ${response.json()}    ${CONFIRMED}

Reusing the order ID with a changed payload is rejected
    ${changed}=    Copy Dictionary    ${ORDER_PAYLOAD}
    Set To Dictionary    ${changed}    notes=Changed payload
    POST On Session    api    ${ORDER_PATH}    headers=${CASHIER_HEADERS}    json=${changed}    expected_status=409

The cashier submits another ID with the same normalized platform references
    ${changed}=    Copy Dictionary    ${ORDER_PAYLOAD}
    ${id}=    Evaluate    str(uuid.uuid4())    modules=uuid
    Set To Dictionary    ${changed}    order_id=${id}    merchant_store_reference= robot-store${SPACE}    external_order_reference=${SPACE}${ORDER_ID}${SPACE}
    ${response}=    POST On Session    api    ${ORDER_PATH}    headers=${CASHIER_HEADERS}    json=${changed}    expected_status=409
    Set Test Variable    ${LAST_RESPONSE}    ${response}

Another brand manager attempts to read and change the channel
    ${headers}=    An authenticated catalog user exists    3
    GET On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${headers}    expected_status=403
    ${payload}=    Create Dictionary    price=${999}
    PATCH On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${headers}    json=${payload}    expected_status=403
    DELETE On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${headers}    expected_status=403

The original channel remains unchanged
    ${response}=    GET On Session    api    /api/menu-channels/${CHANNEL_ID}    headers=${MANAGER_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal As Numbers    ${body}[price]    120
    Should Be Equal    ${body}[is_available]    ${True}

The manager attaches a valid PNG to the menu item
    ${image}=    Evaluate    base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAACXBIWXMAAAPoAAAD6AG1e1JrAAAAE0lEQVQImWP4z8DwnwGM/zMwAAAf7gP9qS/A4gAAAABJRU5ErkJggg==')    modules=base64
    ${file}=    Create List    fixture.png    ${image}    image/png
    ${files}=    Create Dictionary    file=${file}
    ${response}=    PATCH On Session    api    /api/menu-items/${MENU_ID}    headers=${MANAGER_HEADERS}    files=${files}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Set Test Variable    ${IMAGE_KEY}    ${body}[img_url]

The stored image can be retrieved through an owner download URL
    ${response}=    GET On Session    api    /api/menu-items/${MENU_ID}    headers=${MANAGER_HEADERS}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[img_url]    ${IMAGE_KEY}
    ${params}=    Create Dictionary    key=${IMAGE_KEY}
    ${response}=    GET On Session    api    /api/assets/download-url    headers=${MANAGER_HEADERS}    params=${params}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    ${image}=    GET    ${body}[downloadUrl]    expected_status=200
    Should Start With    ${image.headers}[Content-Type]    image/png
    Should Not Be Empty    ${image.content}
