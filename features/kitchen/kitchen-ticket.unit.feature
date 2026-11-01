@backend @unit @kitchen
Feature: Kitchen ticket lifecycle and repository rules

  @UT-KT-001
  Scenario: Validate the order before ticket creation
    Given an existing order
    When a kitchen ticket is created
    Then the order is validated before the ticket is persisted

  @UT-KT-002
  Scenario: Reject ticket creation for a missing order
    Given a missing order
    When a kitchen ticket is created
    Then ORDER_NOT_FOUND is returned without creating a ticket

  @UT-KT-003
  Scenario Outline: Persist legal lifecycle transitions
    Given a ticket in <from> with the required caller assignment
    When <action> is requested
    Then the status becomes <to> and applicable timestamps are saved

    Examples:
      | action | from | to |
      | acknowledge | QUEUED | ACKNOWLEDGED |
      | prepare | ACKNOWLEDGED | PREPARING |
      | forChecking | PREPARING | FOR_CHECKING |
      | forChecking | REWORKING | FOR_CHECKING |
      | check | FOR_CHECKING | CHECKING |
      | rework | CHECKING | REWORKING |
      | ready | CHECKING | READY |
      | handOver | READY | HANDED_OVER |
      | cancel | QUEUED | CANCELLED |
      | cancel | ACKNOWLEDGED | CANCELLED |
      | cancel | PREPARING | CANCELLED |
      | cancel | FOR_CHECKING | CANCELLED |
      | cancel | CHECKING | CANCELLED |
      | cancel | REWORKING | CANCELLED |
      | cancel | READY | CANCELLED |

  @UT-KT-004
  Scenario: Reject transitions from handed-over tickets
    Given a HANDED_OVER ticket and its assigned caller
    When any lifecycle action is requested
    Then KITCHEN_TICKET_INVALID_STATUS is returned without writing

  @UT-KT-005
  Scenario Outline: Require the assigned preparer or checker
    Given a ticket in <status> without an assigned caller
    When <action> is requested
    Then KITCHEN_TICKET_<role>_MISMATCH is returned without writing

    Examples:
      | action | status | role |
      | prepare | ACKNOWLEDGED | PREPARER |
      | forChecking | PREPARING | PREPARER |
      | check | FOR_CHECKING | CHECKER |
      | rework | CHECKING | CHECKER |
      | ready | CHECKING | CHECKER |

  @UT-KT-006
  Scenario: Cancel an already-cancelled ticket idempotently
    Given a CANCELLED ticket
    When cancellation is retried
    Then the saved ticket is returned without another write

  @UT-KT-007
  Scenario: Forward transaction clients through lifecycle transitions
    Given an explicit transaction client and a legal lifecycle transition
    When the action is requested
    Then only the transaction client reads and updates the ticket

  @UT-KT-008
  Scenario Outline: Assign an unclaimed ticket
    Given a ticket without a <field>
    When <action> is requested
    Then only <field> is changed

    Examples:
      | action | field |
      | assignPreparer | preparer_id |
      | assignChecker | checker_id |

  @UT-KT-009
  Scenario Outline: Preserve existing ticket assignments
    Given a ticket with an existing <role>
    When a replacement <role> is assigned
    Then a conflict is returned and the original assignment is preserved

    Examples:
      | role |
      | preparer |
      | checker |

  @UT-KT-010
  Scenario Outline: Return the standard missing ticket error
    Given a missing ticket
    When <action> is requested
    Then KITCHEN_TICKET_NOT_FOUND is returned without writing

    Examples:
      | action |
      | findOne |
      | assignPreparer |
      | assignChecker |

  @UT-KT-011
  Scenario: Reject every illegal lifecycle transition
    Given a ticket with its required caller assignment
    When an action is requested from a status outside its legal predecessors
    Then KITCHEN_TICKET_INVALID_STATUS is returned and the ticket is unchanged

  @UT-KT-012
  Scenario: Use Manila calendar days across the UTC boundary
    Given the time is 2026-10-31T16:30:00Z
    When today is queried
    Then the created_at range includes 2026-10-31T16:00:00Z and excludes 2026-11-01T16:00:00Z

  @UT-KT-013
  Scenario Outline: Default assignee filters to active work today
    Given a <role> identifier
    When its tickets are queried without explicit filters
    Then the query uses the Manila day and excludes HANDED_OVER

    Examples:
      | role |
      | preparer |
      | checker |

  @UT-KT-014
  Scenario Outline: Apply each assignee filter independently
    Given a preparer or checker identifier
    When excludeHandedOver is <exclude> and onlyToday is <today>
    Then the query includes only the requested restrictions

    Examples:
      | exclude | today |
      | true | true |
      | true | false |
      | false | true |
      | false | false |

  @UT-KT-015
  Scenario: Read paginated rows and totals consistently
    Given a root Prisma client
    When tickets are listed with offset 2 and limit 2
    Then rows and total share a RepeatableRead transaction with deterministic ordering

  @UT-KT-016
  Scenario: Reuse an existing transaction for pagination
    Given an explicit transaction client
    When tickets are listed
    Then both rows and total use that client without accessing the root client

  @UT-KT-017
  Scenario: Propagate a lost optimistic status update
    Given a concurrent status change causes the guarded write to fail
    When a status transition is persisted
    Then P2025 is propagated without retrying or overwriting the newer status
