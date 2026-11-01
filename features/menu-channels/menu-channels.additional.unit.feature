@backend @unit @menu-channels
Feature: Additional menu channels unit coverage
  Feature ID: FEAT-MCH-UT-ADDITIONAL
  Requirement ID: FR-MCH-001

  As a backend maintainer,
  I want the menu channels behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService module wiring
  @UT-MCH-007
  Scenario: Resolves the service through the application module
    Test Case ID: UT-MCH-007
    Given the application module with substituted external dependencies
    When the testing module is compiled
    Then the menu channel service can be resolved

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-008
  Scenario: Paginate channels with either availability filter
    Test Case ID: UT-MCH-008
    Given channel rows and an activeOnly filter
    When channels are listed with pagination
    Then the filter and offset are forwarded and matching pagination metadata is returned

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-009
  Scenario: Returns empty pagination results without a channel filter
    Test Case ID: UT-MCH-009
    Given no matching channels and no channel filter
    When channels are listed
    Then an empty page and matching pagination metadata are returned

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-010
  Scenario: Rejects pagination overflow before querying
    Test Case ID: UT-MCH-010
    Given a pagination offset beyond the database range
    When channels are listed
    Then the request is rejected before querying the repository

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-011
  Scenario: Updates an available channel and returns the updated record
    Test Case ID: UT-MCH-011
    Given an available menu channel and valid changes
    When the channel is updated
    Then the changes are persisted and the updated channel is returned

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-012
  Scenario: Reactivates an unavailable channel
    Test Case ID: UT-MCH-012
    Given an unavailable menu channel
    When reactivation is requested
    Then the channel becomes available

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-013
  Scenario: Rejects reactivating an already available channel
    Test Case ID: UT-MCH-013
    Given an already available menu channel
    When reactivation is requested
    Then a conflict is returned without reactivating the channel

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-014
  Scenario: Soft-deletes an available channel
    Test Case ID: UT-MCH-014
    Given an available menu channel
    When deletion is requested
    Then the channel is soft-deleted

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-015
  Scenario: Reject writes to missing channels
    Test Case ID: UT-MCH-015
    Given a missing channel
    When an update, reactivation, or deletion is requested
    Then a not-found error is returned without writing

  # Jest: server/src/modules/menu/menu-channels/tests/menu-channels.service.spec.ts
  # Context: MenuChannelsService listing and mutations
  @UT-MCH-016
  Scenario: Propagate repository operation failures
    Test Case ID: UT-MCH-016
    Given a channel repository write fails
    When an update, reactivation, or deletion is requested
    Then the original repository error is propagated
