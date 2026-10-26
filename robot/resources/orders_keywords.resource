*** Settings ***
Resource          common.resource
Resource          catalog_keywords.resource

*** Keywords ***
An order request payload is configured for item "${item_code}"
    ${headers}=    An authenticated catalog user exists    1
    ${response}=    GET On Session    api    /api/menu-items/${item_code}    headers=${headers}    expected_status=200
    ${body}=    Set Variable    ${response.json()}
    Set Test Variable    ${MENU_ID}    ${body}[menu_item_id]
    Set Test Variable    ${ORDER_PATH}    /api/brands/${body}[brand_id]/orders
    A cashier has a unique order payload
