@backend @integration @postgresql @orders
Feature: Order validation and transactional persistence

  @IT-ORD-001
  Scenario Outline: Reject invalid create payloads without persistence
    Given an authenticated cashier and <invalidInput>
    When the order is posted
    Then the response status is 400
    And no order is inserted for the fixture brand
    Examples:
      | invalidInput             |
      | an invalid order UUID    |
      | an empty line list       |
      | 101 lines                |
      | an unknown field         |
      | quantity zero            |
      | quantity negative one    |
      | quantity 1.5             |
      | quantity 10000           |
      | duplicate modifiers      |
      | 101 modifiers            |

  @IT-ORD-002
  Scenario Outline: Validate verify and confirm request boundaries
    Given a persisted draft
    When <operation> receives invalid order UUIDs or invalid payment fields or unknown fields
    Then each request returns 400
    And the stored draft and its lines remain unchanged
    Examples:
      | operation |
      | verify    |
      | confirm   |

  @IT-ORD-003
  Scenario Outline: Enforce order session and brand scope
    Given a <user> session
    When an order for brand A is created
    Then the response status is <status>
    Examples:
      | user                  | status |
      | brand A manager       | 201    |
      | brand A cashier       | 201    |
      | superadmin            | 201    |
      | brand B manager       | 403    |
      | unauthenticated user  | 401    |

  @IT-ORD-004
  Scenario: Persist confirmation snapshots without inventory effects
    Given a GrabFood draft with an extra-rice modifier and a 120 peso override
    When the cashier verifies it
    Then verification returns current prices without changing the saved draft
    When the cashier confirms it
    Then a confirmed order and one queued ticket are saved
    And full recipe and modifier snapshots exist in PostgreSQL
    And HTTP responses omit recipe snapshots and instructions
    And ingredient balance and stock movements remain unchanged

  @IT-ORD-005
  Scenario: Concurrent confirmations create one ticket
    Given a persisted draft
    When two confirmations are sent concurrently
    Then both return 200 with identical order and ticket data
    And exactly one ticket exists for the order

  @IT-ORD-006
  Scenario: Roll back snapshot writes after ticket failure
    Given a persisted draft and a real PostgreSQL transaction
    And ticket insertion is configured to throw after snapshot writes
    When the order is confirmed
    Then the failure is propagated
    And the complete saved order equals its pre-confirmation state
    And no ticket exists

  @IT-ORD-007
  Scenario: Confirmation captures the latest price once
    Given a draft verified at 120 pesos
    When its override changes to 150 pesos before confirmation
    Then confirmation snapshots 150 pesos
    When the override changes to 200 pesos and confirmation is replayed
    Then the original confirmation snapshots and ticket are unchanged

  @IT-ORD-008
  Scenario: Reject a channel disabled after draft creation
    Given a draft created while its channel is available
    When the override is disabled and confirmation is requested
    Then confirmation returns 400
    And the draft remains unchanged without a ticket
