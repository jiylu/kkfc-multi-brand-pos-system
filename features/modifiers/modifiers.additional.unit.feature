@backend @unit @modifiers
Feature: Additional modifiers unit coverage
  Feature ID: FEAT-MOD-UT-ADDITIONAL
  Requirement ID: FR-MOD-001

  As a backend maintainer,
  I want the modifiers behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService
  @UT-MOD-001
  Scenario: Resolves the service, repository, and controller through the application module
    Test Case ID: UT-MOD-001
    Given the application module with substituted external dependencies
    When the testing module is compiled
    Then the modifier service, repository, and controller can be resolved

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-002
  Scenario: Creates a modifier after validating its inventory item
    Test Case ID: UT-MOD-002
    Given a valid modifier payload referencing an inventory item
    When the modifier is created
    Then the inventory item is validated before saving

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-003
  Scenario: Create modifiers with omitted or null inventory references
    Test Case ID: UT-MOD-003
    Given a modifier payload with an omitted or null inventory item
    When the modifier is created
    Then creation succeeds without an inventory lookup

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-004
  Scenario: Rejects creating a modifier with a missing or inactive inventory item
    Test Case ID: UT-MOD-004
    Given a missing or inactive inventory item
    When a modifier referencing it is created
    Then a not-found error is returned without saving

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-005
  Scenario: Look up modifiers by UUID or code with the requested activity filter
    Test Case ID: UT-MOD-005
    Given a modifier UUID or code and an activeOnly filter
    When the modifier is retrieved
    Then the appropriate repository lookup receives the identifier and filter

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-006
  Scenario: Reject missing modifiers identified by UUID or code
    Test Case ID: UT-MOD-006
    Given no modifier matches the supplied UUID or code
    When the modifier is retrieved
    Then a not-found error is returned

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-007
  Scenario: List inventory item modifiers with the requested activity filter
    Test Case ID: UT-MOD-007
    Given an existing inventory item and an activeOnly filter
    When its modifiers are listed
    Then the inventory item is validated and the filter is forwarded

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-008
  Scenario: Rejects listing modifiers for a missing inventory item
    Test Case ID: UT-MOD-008
    Given a missing inventory item
    When its modifiers are listed
    Then a not-found error is returned before querying modifiers

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-009
  Scenario: Paginate modifiers using either activity filter
    Test Case ID: UT-MOD-009
    Given modifier rows and an activeOnly filter
    When modifiers are paginated
    Then the filter and offset are forwarded with matching pagination metadata

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-010
  Scenario: Returns empty pagination results using the default query
    Test Case ID: UT-MOD-010
    Given no modifiers and no pagination options
    When modifiers are listed
    Then an empty page with default metadata is returned

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-011
  Scenario: Rejects pagination overflow before querying
    Test Case ID: UT-MOD-011
    Given a pagination offset beyond the database range
    When modifiers are listed
    Then the request is rejected before querying

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-012
  Scenario: Validates the replacement inventory item before updating
    Test Case ID: UT-MOD-012
    Given a modifier update referencing a replacement inventory item
    When the modifier is updated
    Then the replacement inventory item is validated before saving

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-013
  Scenario: Skip inventory lookups for omitted or cleared modifier references
    Test Case ID: UT-MOD-013
    Given a modifier update with an omitted or null inventory item reference
    When the modifier is updated
    Then no inventory lookup is performed

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-014
  Scenario: Rejects updating with a missing or inactive inventory item
    Test Case ID: UT-MOD-014
    Given a missing or inactive replacement inventory item
    When the modifier is updated
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-015
  Scenario: Reactivates an inactive modifier
    Test Case ID: UT-MOD-015
    Given an inactive modifier
    When reactivation is requested
    Then the modifier becomes active

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-016
  Scenario: Rejects reactivating an already-active modifier
    Test Case ID: UT-MOD-016
    Given an already active modifier
    When reactivation is requested
    Then a conflict is returned without reactivation

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-017
  Scenario: Soft-deletes an active modifier
    Test Case ID: UT-MOD-017
    Given an active modifier
    When deletion is requested
    Then the modifier is soft-deleted

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-018
  Scenario: Reject writes to missing modifiers
    Test Case ID: UT-MOD-018
    Given a missing modifier
    When an update, reactivation, or deletion is requested
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: ModifiersService operations
  @UT-MOD-019
  Scenario: Propagate repository operation failures
    Test Case ID: UT-MOD-019
    Given a modifier repository operation fails
    When an update, reactivation, or deletion is requested
    Then the original repository error is propagated

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-020
  Scenario: Creates a modifier with an inventory item and quantity
    Test Case ID: UT-MOD-020
    Given a modifier payload with an inventory item and quantity
    When the repository creates the modifier
    Then both references and quantity are saved

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-021
  Scenario: Apply modifier activity filters consistently to lookups and totals
    Test Case ID: UT-MOD-021
    Given an activeOnly filter
    When modifier lookups and pagination are requested
    Then the filter applies consistently to every lookup and total count

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-022
  Scenario: Lists modifiers using a supplied transaction client
    Test Case ID: UT-MOD-022
    Given an explicitly supplied transaction client
    When modifiers are listed
    Then the supplied transaction performs both row and total queries

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-023
  Scenario: Save or clear a modifier's inventory item reference
    Test Case ID: UT-MOD-023
    Given an update that supplies or clears an inventory item reference
    When the repository updates the modifier
    Then the reference is saved with the supplied value

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-024
  Scenario: Reactivates an inactive modifier and updates its modification timestamp
    Test Case ID: UT-MOD-024
    Given an inactive modifier
    When the repository reactivates it
    Then is_active and modified_at are updated

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-025
  Scenario: Soft deletes an active modifier without removing its references
    Test Case ID: UT-MOD-025
    Given an active modifier
    When the repository deletes it
    Then the record becomes inactive while its references remain stored

  # Jest: server/src/modules/menu/modifiers/tests/modifiers.service.spec.ts
  # Context: Modifiers persistence
  @UT-MOD-026
  Scenario: Preserves database errors for the application exception filters
    Test Case ID: UT-MOD-026
    Given the database reports a modifier constraint error
    When a modifier is persisted
    Then the error is propagated for application exception handling
