@backend @unit @menu-item-modifiers
Feature: Additional menu item modifiers unit coverage
  Feature ID: FEAT-MIM-UT-ADDITIONAL
  Requirement ID: FR-MIM-001

  As a backend maintainer,
  I want the menu item modifiers behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService module wiring
  @UT-MIM-001
  Scenario: Resolves the service, repository, and controller
    Test Case ID: UT-MIM-001
    Given the application module with substituted external dependencies
    When the testing module is compiled
    Then the modifier assignment service, repository, and controller can be resolved

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-002
  Scenario: Creates an assignment after checking the active menu item and modifier
    Test Case ID: UT-MIM-002
    Given an active menu item and modifier
    When a modifier assignment is created
    Then both references are checked before saving the assignment

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-003
  Scenario: Rejects creation when the menu item is missing or inactive
    Test Case ID: UT-MIM-003
    Given a missing or inactive menu item
    When a modifier assignment is created
    Then a not-found error is returned without saving

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-004
  Scenario: Rejects creation when the modifier is missing or inactive
    Test Case ID: UT-MIM-004
    Given a missing or inactive modifier
    When a modifier assignment is created
    Then a not-found error is returned without saving

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-005
  Scenario: Preserves duplicate-pair errors for the application exception filter
    Test Case ID: UT-MIM-005
    Given the menu item and modifier pair already exists
    When a duplicate assignment is created
    Then the database constraint error is propagated for the application filter

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-006
  Scenario: Retrieve assignments using either availability filter
    Test Case ID: UT-MIM-006
    Given an assignment lookup with an activeOnly filter
    When the assignment is retrieved
    Then the filter is forwarded and the assignment is returned

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-007
  Scenario: Rejects a missing assignment
    Test Case ID: UT-MIM-007
    Given no matching modifier assignment
    When the assignment is retrieved
    Then a not-found error is returned

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-008
  Scenario: Paginate assignments using either availability filter
    Test Case ID: UT-MIM-008
    Given assignment rows and an activeOnly filter
    When assignments are paginated
    Then the filter and pagination offset are forwarded with matching metadata

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-009
  Scenario: Returns empty results with default pagination
    Test Case ID: UT-MIM-009
    Given no assignments and no pagination options
    When assignments are listed
    Then an empty page with default pagination metadata is returned

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-010
  Scenario: Rejects pagination overflow before querying
    Test Case ID: UT-MIM-010
    Given a pagination offset beyond the database range
    When assignments are listed
    Then the request is rejected before querying

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-011
  Scenario: List menu item assignments with the requested availability filter
    Test Case ID: UT-MIM-011
    Given an active menu item and an activeOnly filter
    When its modifier assignments are listed
    Then the menu item is validated and the filter is forwarded

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-012
  Scenario: Rejects listing for a missing or inactive menu item
    Test Case ID: UT-MIM-012
    Given a missing or inactive menu item
    When its modifier assignments are listed
    Then a not-found error is returned before querying assignments

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-013
  Scenario: Returns an empty list for a menu item without assignments
    Test Case ID: UT-MIM-013
    Given an active menu item without modifier assignments
    When its assignments are listed
    Then an empty list is returned

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-014
  Scenario: Updates price after validating the current menu item and modifier
    Test Case ID: UT-MIM-014
    Given an existing assignment with active parent references
    When the additional price is updated
    Then the menu item and modifier are validated before saving the new price

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-015
  Scenario: Validates a replacement modifier instead of the previous modifier
    Test Case ID: UT-MIM-015
    Given an update that replaces the modifier reference
    When the assignment is updated
    Then the replacement modifier is validated instead of the original modifier

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-016
  Scenario: Reactivates an unavailable assignment after checking its active references
    Test Case ID: UT-MIM-016
    Given an unavailable assignment with active parent references
    When reactivation is requested
    Then both references are checked before making the assignment available

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-017
  Scenario: Rejects reactivation of an already-available assignment before checking references
    Test Case ID: UT-MIM-017
    Given an already available assignment
    When reactivation is requested
    Then a conflict is returned before checking parent references

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-018
  Scenario: Soft deletes an assignment even when its parent references are inactive
    Test Case ID: UT-MIM-018
    Given an assignment whose parent references are inactive
    When deletion is requested
    Then the assignment is soft-deleted without requiring active parent references

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-019
  Scenario: Reject writes to missing assignments
    Test Case ID: UT-MIM-019
    Given a missing assignment
    When an update, reactivation, or deletion is requested
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-020
  Scenario: Propagate repository operation failures
    Test Case ID: UT-MIM-020
    Given an assignment repository operation fails
    When an update, reactivation, or deletion is requested
    Then the original repository error is propagated

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-021
  Scenario: Require an active menu item before assignment writes
    Test Case ID: UT-MIM-021
    Given an assignment with a missing or inactive menu item
    When an operation requiring active references is requested
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: MenuItemModifiersService operations
  @UT-MIM-022
  Scenario: Require an active modifier before assignment writes
    Test Case ID: UT-MIM-022
    Given an assignment with a missing or inactive modifier
    When an operation requiring active references is requested
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-023
  Scenario: Creates an assignment and leaves timestamps and availability to database defaults
    Test Case ID: UT-MIM-023
    Given a valid assignment payload
    When the repository creates the assignment
    Then timestamps and availability are left to database defaults

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-024
  Scenario: Apply assignment availability filters consistently to lookups and totals
    Test Case ID: UT-MIM-024
    Given an activeOnly filter
    When repository lookups and pagination are requested
    Then the same availability filter applies to every lookup and the total count

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-025
  Scenario: Returns null for a missing assignment
    Test Case ID: UT-MIM-025
    Given no stored modifier assignment
    When the repository retrieves the assignment
    Then null is returned

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-026
  Scenario: Reuse the supplied assignment transaction without nesting
    Test Case ID: UT-MIM-026
    Given an explicitly supplied transaction client that also exposes $transaction
    When assignments are listed
    Then the supplied client is used

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-027
  Scenario: Updates only additional_price and modifier_id, and advances modified_at
    Test Case ID: UT-MIM-027
    Given an assignment update with a new price and modifier
    When the repository saves the update
    Then only allowed fields and modified_at are changed

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-028
  Scenario: Accept partial modifier assignment updates
    Test Case ID: UT-MIM-028
    Given a partial assignment update
    When the repository saves it
    Then only the supplied update fields and modification time are persisted

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-029
  Scenario: Reactivates an unavailable assignment without changing its references
    Test Case ID: UT-MIM-029
    Given an unavailable assignment
    When the repository reactivates it
    Then availability changes without replacing its parent references

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-030
  Scenario: Soft deletes an available assignment without deleting its record
    Test Case ID: UT-MIM-030
    Given an available assignment
    When the repository deletes it
    Then availability is disabled while the record remains stored

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-031
  Scenario: Uses the supplied transaction client for all non-paginated operations
    Test Case ID: UT-MIM-031
    Given an explicitly supplied transaction client
    When non-paginated assignment operations are executed
    Then every operation uses that transaction client

  # Jest: server/src/modules/menu/menu-item-modifiers/tests/menu-item-modifiers.service.spec.ts
  # Context: Menu item modifiers persistence
  @UT-MIM-032
  Scenario: Preserves database constraint errors for the application filters
    Test Case ID: UT-MIM-032
    Given the database reports an assignment constraint error
    When an assignment is persisted
    Then the error is propagated for application exception handling
