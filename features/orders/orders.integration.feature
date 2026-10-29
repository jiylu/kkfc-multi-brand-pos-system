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

  @IT-ORD-009
  Scenario Outline: Require both platform references before persistence
    Given a <channel> create with either reference omitted, null, empty or whitespace
    When the cashier posts the order
    Then the response status is 400
    And no order or daily counter is persisted
    Examples:
      | channel   |
      | GRABFOOD  |
      | FOODPANDA |

  @IT-ORD-010
  Scenario: Block sequential and simultaneous platform duplicates
    Given two UUIDs with the same channel and trimmed store and external reference
    When the requests are posted sequentially or simultaneously
    Then one returns 201 and one returns 409 with code DUPLICATE_PLATFORM_ORDER
    And existing_order contains the saved order in the requested brand
    And exactly one order, line and modifier is persisted with one daily number
    And private request fingerprints and recipe snapshots are absent

  @IT-ORD-011
  Scenario: Permit lookalikes with different platform identities
    Given a GrabFood order with a store and external reference
    When another UUID differs in channel, store or external reference
    Then both orders are created
    And reference comparison is case-sensitive after trimming

  @IT-ORD-012
  Scenario Outline: Recover concurrent creates and lost committed responses
    Given a <channel> submission with one stable UUID
    When three identical requests are posted simultaneously
    Then all return the same saved order
    When the order is confirmed and the menu item becomes unavailable
    And another authorized staff member replays the original create
    Then the replay returns the saved confirmed order and ticket
    And only one order, line, daily number and ticket are persisted
    Examples:
      | channel   |
      | DINE_IN   |
      | TAKEAWAY  |
      | GRABFOOD  |
      | FOODPANDA |

  @IT-ORD-013
  Scenario: Reject changed content under a saved or concurrent submission UUID
    Given two requests with the same UUID but different notes
    When posted sequentially or simultaneously
    Then one returns 201 and one returns 409 with code ORDER_ID_CONFLICT
    And the saved order preserves the winner's content

  @IT-ORD-014
  Scenario: Keep cross-brand duplicate responses opaque
    Given a platform order in brand A
    When brand B's manager submits the same platform identity to brand B
    Then DUPLICATE_PLATFORM_ORDER has existing_order null and no brand A details
    When the manager submits brand A's UUID to brand B
    Then ORDER_ID_CONFLICT contains no existing-order data
    And brand A's route still rejects unauthorized and unauthenticated replays

  @IT-ORD-015
  Scenario: Concurrent confirmation preserves the winning payment
    Given two persisted drafts
    When one draft receives simultaneous confirmations with different payments
    And the other draft is confirmed simultaneously
    Then the first draft's responses contain identical saved payment and ticket data
    And exactly two tickets with distinct numbers and order IDs are persisted

  @IT-ORD-016
  Scenario: Roll back an inserted order and retry its UUID
    Given an order transaction fails after inserting nested lines and modifiers
    When the failure is propagated
    Then no order, line, modifier or counter remains
    And retrying the same UUID creates the order with daily number one

  @IT-ORD-017
  Scenario: Roll back an inserted ticket and recover confirmation
    Given a draft whose confirmation fails after inserting its ticket
    Then the saved draft and snapshots equal their pre-confirmation state
    And no ticket remains
    When confirmation and its retry succeed
    Then both return identical data with one persisted ticket
