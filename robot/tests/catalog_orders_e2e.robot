*** Settings ***
Documentation     Feature: Catalog and order API workflows using isolated PostgreSQL fixtures and real login sessions.
Resource          ../resources/orders_keywords.resource
Suite Setup       An isolated catalog fixture is loaded
Suite Teardown    Delete All Sessions
Test Setup        A manager has created a unique menu item

*** Test Cases ***
E2E-MCH-001: Manager persists a platform channel lifecycle
    [Tags]    E2E    CATALOG    E2E-MCH-001
    Given the manager creates a GrabFood override
    When the manager changes the channel price to 150
    Then the saved channel price is 150
    When the manager deactivates and reactivates the channel
    Then the saved channel is available

E2E-ORD-001: Cashier creates verifies and confirms an order
    [Tags]    E2E    ORDERS    E2E-ORD-001
    Given an order request payload is configured for item "${MENU_CODE}"
    When the cashier creates the draft
    And the cashier verifies and confirms the draft
    Then a confirmed order and queued ticket are returned

E2E-ORD-002: Order retries preserve identity and snapshots
    [Tags]    E2E    ORDERS    E2E-ORD-002
    Given a cashier has a unique order payload
    And the cashier creates the draft
    And the cashier verifies and confirms the draft
    When the cashier retries the same create and confirmation
    Then a confirmed order and queued ticket are returned
    And reusing the order ID with a changed payload is rejected

E2E-ORD-003: Duplicate platform references cannot create a second order
    [Tags]    E2E    ORDERS    E2E-ORD-003
    Given a cashier has a unique order payload    GRABFOOD
    And the cashier creates the draft
    When the cashier submits another ID with the same normalized platform references
    Then the HTTP response status should be 409

E2E-MCH-002: Managers can inspect and update channels across brands
    [Tags]    E2E    CATALOG    E2E-MCH-002
    Given the manager creates a GrabFood override
    When another manager reads and changes the channel
    Then the channel change is visible to the original manager

E2E-ASSET-001: Menu image association survives a read and downloads from storage
    [Documentation]    Requires a configured test S3 bucket and working download signing configuration.
    [Tags]    E2E    CATALOG    storage    E2E-ASSET-001
    Given an authenticated catalog user exists    0
    When the manager attaches a valid PNG to the menu item
    Then the stored image can be retrieved through an owner download URL
