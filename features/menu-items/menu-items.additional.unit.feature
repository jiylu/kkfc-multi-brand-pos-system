@backend @unit @menu-items
Feature: Additional menu items unit coverage
  Feature ID: FEAT-MI-UT-ADDITIONAL
  Requirement ID: FR-MI-001

  As a backend maintainer,
  I want the menu items behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations
  @UT-MI-001
  Scenario: Look up the menu item before mutation and return the saved result
    Test Case ID: UT-MI-001
    Given an existing menu item and a requested update, reactivation, or deletion
    When the service performs the operation
    Then the item is looked up and the repository result is returned

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations
  @UT-MI-002
  Scenario: Reject menu mutations for missing items
    Test Case ID: UT-MI-002
    Given a missing menu item
    When an update, reactivation, or deletion is requested
    Then MENU_ITEM_NOT_FOUND is returned without writing

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations
  @UT-MI-003
  Scenario: Propagate menu mutation repository failures
    Test Case ID: UT-MI-003
    Given the menu item repository raises a persistence error
    When an update, reactivation, or deletion is requested
    Then the original error is propagated

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations
  @UT-MI-004
  Scenario: Rejects reactivating an already-active item without writing
    Test Case ID: UT-MI-004
    Given an already active menu item
    When reactivation is requested
    Then MENU_ITEM_ALREADY_ACTIVE is returned without writing

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations / availability
  @UT-MI-005
  Scenario: Change menu availability and return the updated item
    Test Case ID: UT-MI-005
    Given an active menu item in an active brand with a different availability value
    When availability is changed to the requested boolean
    Then the item and brand are validated and the updated item is returned

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations / availability
  @UT-MI-006
  Scenario: Reject unchanged menu availability without writing
    Test Case ID: UT-MI-006
    Given an item already has the requested availability value
    When that availability is requested again
    Then AVAILABILITY_CONFLICT is returned without writing

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations / availability
  @UT-MI-007
  Scenario: Rejects missing or inactive items without writing
    Test Case ID: UT-MI-007
    Given a missing or inactive menu item
    When availability is changed
    Then MENU_ITEM_NOT_FOUND is returned without looking up its brand or writing

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations / availability
  @UT-MI-008
  Scenario: Rejects a missing or inactive brand without writing
    Test Case ID: UT-MI-008
    Given a menu item whose brand is missing or inactive
    When availability is changed
    Then BRAND_NOT_FOUND is returned without writing

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.service.spec.ts
  # Context: MenuItemsService mutations / availability
  @UT-MI-009
  Scenario: Preserves persistence failures
    Test Case ID: UT-MI-009
    Given the availability repository write fails
    When availability is changed
    Then the original persistence error is propagated

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.repository.spec.ts
  # Context: MenuItemsRepository availability
  @UT-MI-010
  Scenario: Update availability only on active items while preserving other fields
    Test Case ID: UT-MI-010
    Given an active menu item and a requested boolean availability
    When the repository changes availability
    Then only availability and modification time are updated while other fields are preserved
