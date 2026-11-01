@backend @unit @menu-catalog
Feature: Additional menu catalog unit coverage
  Feature ID: FEAT-MCAT-UT-ADDITIONAL
  Requirement ID: FR-MCAT-001

  As a backend maintainer,
  I want the menu catalog behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService module wiring
  @UT-MCAT-001
  Scenario: Resolves the service through the application module
    Test Case ID: UT-MCAT-001
    Given the application module and substituted external dependencies
    When the testing module is compiled
    Then the menu catalog service can be resolved

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-002
  Scenario: Checks every active modifier before creating the catalog entry
    Test Case ID: UT-MCAT-002
    Given an active brand and active modifier references
    When a catalog entry is created
    Then every modifier is validated before creating the entry

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-003
  Scenario: Rejects a missing or inactive later modifier without creating anything
    Test Case ID: UT-MCAT-003
    Given a catalog payload whose later modifier is missing or inactive
    When catalog creation is requested
    Then a not-found error is returned without creating any entry

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-004
  Scenario: Allows creation without modifier assignments
    Test Case ID: UT-MCAT-004
    Given a catalog payload without modifier assignments
    When the catalog entry is created
    Then creation succeeds without querying modifiers

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-005
  Scenario: Preserves creation errors for the application exception filters
    Test Case ID: UT-MCAT-005
    Given catalog persistence raises an error
    When a catalog entry is created
    Then the original error is propagated for application exception handling

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-006
  Scenario: Does not create anything when a modifier lookup fails
    Test Case ID: UT-MCAT-006
    Given a modifier lookup raises an error
    When a catalog entry is created
    Then the error is propagated without creating the entry

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-007
  Scenario: Validates the active brand and paginates the mapped catalog
    Test Case ID: UT-MCAT-007
    Given an active brand and catalog rows
    When the brand catalog is listed with pagination
    Then the brand is validated and mapped entries and pagination metadata are returned

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-008
  Scenario: Rejects listing for a missing or inactive brand before querying the catalog
    Test Case ID: UT-MCAT-008
    Given a missing or inactive brand
    When its catalog is listed
    Then a not-found error is returned before querying catalog rows

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-009
  Scenario: Returns an empty catalog with default pagination
    Test Case ID: UT-MCAT-009
    Given an active brand with no catalog rows and no pagination options
    When its catalog is listed
    Then an empty catalog and default pagination metadata are returned

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-010
  Scenario: Rejects pagination overflow before querying the catalog
    Test Case ID: UT-MCAT-010
    Given a requested page whose offset exceeds the database range
    When the catalog is listed
    Then a bad-request error is returned before querying catalog rows

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService operations
  @UT-MCAT-011
  Scenario: Preserves catalog lookup errors
    Test Case ID: UT-MCAT-011
    Given the catalog repository raises a lookup error
    When a brand catalog is listed
    Then the lookup error is propagated

  # Jest: server/src/modules/menu/menu-catalog/tests/menu-catalog.service.spec.ts
  # Context: MenuCatalogService transactional creation
  @UT-MCAT-012
  Scenario: Return created catalog entries with or without children
    Test Case ID: UT-MCAT-012
    Given a newly created catalog entry with or without child records
    When catalog creation completes
    Then the full saved entry and its available children are returned
