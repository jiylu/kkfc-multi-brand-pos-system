*** Settings ***
Documentation     Feature: Kitchen ticket assignments persist through authenticated API requests.
...               As a kitchen employee,
...               I want to claim and inspect order tickets,
...               So that preparation and checking responsibilities are preserved.
Metadata          Feature ID        FEAT-KT-001
Metadata          Requirement ID    FR-KT-001
Resource          ../resources/kitchen_keywords.resource
Suite Setup       Initialize API Session
Suite Teardown    Delete All Sessions
Test Setup        A queued kitchen ticket exists

*** Test Cases ***
E2E-KT-001: Kitchen staff and head assign a confirmed order ticket
    [Tags]    E2E    KITCHEN    E2E-KT-001    FR-KT-001
    Given kitchen staff claim the ticket as preparer
    When the kitchen head assigns the checker
    Then the saved ticket contains both assignments
    And the ticket appears in today's and assignee listings

E2E-KT-002: Existing preparer cannot be replaced
    [Tags]    E2E    KITCHEN    E2E-KT-002    FR-KT-001
    Given kitchen staff claim the ticket as preparer
    When the kitchen head attempts to replace the preparer
    Then the original preparer is preserved

E2E-KT-003: Kitchen staff cannot assign a checker
    [Tags]    E2E    KITCHEN    E2E-KT-003    FR-KT-001
    Given the checker remains unassigned
    When kitchen staff attempt to assign a checker
    Then the checker remains unassigned

E2E-KT-004: Cashier cannot read or claim kitchen tickets
    [Tags]    E2E    KITCHEN    E2E-KT-004    FR-KT-001
    Given the preparer remains unassigned
    When the cashier attempts to read and claim the kitchen ticket
    Then the preparer remains unassigned
