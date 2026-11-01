@backend @integration @kitchen
Feature: Kitchen ticket HTTP access and validation

  @IT-KT-001
  Scenario: Allow permitted roles on each endpoint
    Given a valid session with a role permitted by the endpoint
    When the ticket read or assignment endpoint is requested
    Then the response is 200 and validated arguments reach the service

  @IT-KT-002
  Scenario: Deny roles outside the endpoint permission set
    Given a valid session whose role is not allowed for the endpoint
    When the ticket endpoint is requested
    Then ACCESS_DENIED is returned before persistence

  @IT-KT-003
  Scenario: Require a bearer session
    Given no bearer session token
    When a ticket endpoint is requested
    Then SESSION_TOKEN_REQUIRED is returned before persistence

  @IT-KT-004
  Scenario: Reject invalid and expired sessions
    Given an invalid or expired bearer session
    When a ticket endpoint is requested
    Then INVALID_SESSION is returned before persistence

  @IT-KT-005
  Scenario: Convert pagination to an offset and limit
    Given an authenticated kitchen head
    When tickets are requested with page 3 and limit 5
    Then the query uses offset 10 and limit 5

  @IT-KT-006
  Scenario Outline: Reject invalid pagination
    Given an authenticated kitchen head
    When tickets are requested with <query>
    Then the response is 400 before persistence

    Examples:
      | query |
      | page=0 |
      | page=1.5 |
      | page=invalid |
      | page=2147483648 |
      | limit=0 |
      | limit=101 |
      | limit=1.5 |
      | limit=invalid |
      | page=2147483647&limit=100 |
      | unknown=true |

  @IT-KT-007
  Scenario Outline: Transform explicit boolean filters
    Given an authenticated kitchen user
    When a preparer or checker listing uses <query>
    Then boolean values reach the service

    Examples:
      | query |
      | excludeHandedOver=false |
      | onlyToday=false |
      | excludeHandedOver=false&onlyToday=false |
      | excludeHandedOver=true&onlyToday=true |

  @IT-KT-008
  Scenario Outline: Reject invalid boolean filters
    Given an authenticated kitchen user
    When an assignee listing uses <query>
    Then the response is 400 before persistence

    Examples:
      | query |
      | excludeHandedOver=invalid |
      | excludeHandedOver=1 |
      | onlyToday=invalid |
      | onlyToday= |
      | unknown=true |

  @IT-KT-009
  Scenario: Return empty arrays for unmatched listings
    Given no matching tickets
    When today or an assignee listing is requested
    Then the response is 200 with an empty array

  @IT-KT-010
  Scenario: Validate UUID path parameters
    Given an authenticated permitted user
    When a ticket read or assignment request has a malformed UUID
    Then the response is 400 before persistence

  @IT-KT-011
  Scenario: Reject missing tickets
    Given an authenticated permitted user and a missing ticket
    When a read or assignment is requested
    Then KITCHEN_TICKET_NOT_FOUND is returned without assignment writes

  @IT-KT-012
  Scenario: Validate assignee UUIDs
    Given an authenticated permitted user
    When assignment contains a missing null blank non-UUID numeric or array assignee
    Then the response is 400 before persistence

  @IT-KT-013
  Scenario: Reject replacement assignments
    Given a ticket with an existing preparer or checker
    When another assignment is requested even to the same user
    Then the response is 409 without overwriting the assignee

  @IT-KT-014
  Scenario: Persist kitchen assignments through the full application
    Given a confirmed order and real kitchen sessions in PostgreSQL
    When staff claim the preparer and a kitchen head assigns the checker
    Then ticket reads and today and assignee listings contain the saved assignments
    And staff cannot assign a checker
    And a duplicate preparer claim preserves both assignments

  @IT-KT-015
  Scenario: Resolve concurrent preparer claims without overwriting the winner
    Given a queued ticket in PostgreSQL and two authenticated kitchen users
    When both users attempt to claim it concurrently
    Then exactly one response succeeds
    And the losing request returns 404 or 409
    And the saved preparer matches the successful response
