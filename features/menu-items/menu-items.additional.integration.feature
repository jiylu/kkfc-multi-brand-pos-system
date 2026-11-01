@backend @integration @menu-items
Feature: Additional menu items integration coverage
  Feature ID: FEAT-MI-IT-ADDITIONAL
  Requirement ID: FR-MI-001

  As a backend maintainer,
  I want the menu items behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-001
  Scenario: Remove confidential recipe fields from menu responses for every reader
    Test Case ID: IT-MI-001
    Given an authenticated menu reader and a response containing nested recipe secrets
    When the menu item is read
    Then only permitted menu fields are returned and recipe instructions and quantities are removed

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-002
  Scenario: Documents every menu route and preserves the create/update field contracts
    Test Case ID: IT-MI-002
    Given the generated menu item OpenAPI document
    When menu routes and create and update schemas are inspected
    Then security, payload contracts, and response schemas are documented

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-003
  Scenario: Delegate validated menu mutations for managers
    Test Case ID: IT-MI-003
    Given an authenticated manager and valid menu mutation input
    When a menu mutation endpoint is requested
    Then the expected status is returned and the service receives validated arguments

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-004
  Scenario: Allow superadmin menu mutations without brand assignments
    Test Case ID: IT-MI-004
    Given an authenticated superadmin without a brand assignment
    When a menu mutation is requested
    Then the operation succeeds and calls the service once

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-005
  Scenario: Require authentication for menu mutations
    Test Case ID: IT-MI-005
    Given no authenticated session
    When a menu mutation is requested
    Then the response is 401 before calling the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-006
  Scenario: Allow managers to mutate menus across brands
    Test Case ID: IT-MI-006
    Given an authenticated manager with another or no legacy brand value
    When a menu mutation is requested
    Then shared brand access permits creation or update

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-007
  Scenario: Reject menu mutations by unauthorized roles
    Test Case ID: IT-MI-007
    Given a role without menu mutation permission
    When menu mutations are requested
    Then each response is 403 without calling the mutation handler

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-008
  Scenario: Accepts menu-specific update fields and nullable descriptions
    Test Case ID: IT-MI-008
    Given a valid update containing menu fields and nullable descriptions
    When a menu item is updated with JSON
    Then the response is 200 and the payload is forwarded without uploading an image

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-009
  Scenario: Updates multipart fields without uploading or changing the image
    Test Case ID: IT-MI-009
    Given a multipart update containing fields but no image
    When the menu item is updated
    Then only the supplied fields are forwarded without changing or uploading the image

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-010
  Scenario: Uploads an optional image and updates the item with its asset key
    Test Case ID: IT-MI-010
    Given a multipart menu update with an optional image
    When the update is requested
    Then the item is checked, the image is uploaded under the actor, and its object key is saved

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-011
  Scenario: Does not upload an image when the item is inactive
    Test Case ID: IT-MI-011
    Given the target menu item is inactive
    When an image replacement is requested
    Then the response is 404 without uploading an image or updating the item

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-012
  Scenario: Accepts the schema maximum menu code length
    Test Case ID: IT-MI-012
    Given a menu code containing 64 characters
    When a menu update is requested
    Then the schema maximum code length is accepted

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-013
  Scenario: Reject invalid or forbidden menu update fields
    Test Case ID: IT-MI-013
    Given an update contains invalid or forbidden menu fields
    When the menu item is updated
    Then the response is 400 without calling the update service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-014
  Scenario: Reject menu codes on UUID-only mutation routes
    Test Case ID: IT-MI-014
    Given an existing menu code is used on a UUID-only mutation route
    When the mutation is requested
    Then the response is 400 before calling the handler

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-015
  Scenario: Allow menu UUID and code lookups with an activeOnly filter
    Test Case ID: IT-MI-015
    Given a menu UUID or code and an activeOnly option
    When the item is retrieved through GET
    Then the identifier and activeOnly filter reach the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-016
  Scenario: Rejects a non-UUID mutation identifier
    Test Case ID: IT-MI-016
    Given a non-UUID mutation identifier
    When a menu mutation is requested
    Then the response is 400

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-017
  Scenario: Forward pagination to brand and all-brand menu listings
    Test Case ID: IT-MI-017
    Given valid default or custom pagination
    When brand and all-brand menu listings are requested by an authorized caller
    Then both services receive the transformed pagination filters

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-018
  Scenario: Reserves the all-brands listing for superadmins
    Test Case ID: IT-MI-018
    Given a manager or an unauthenticated client
    When the all-brand menu listing is requested
    Then the manager receives 403 and the unauthenticated client receives 401

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints
  @IT-MI-019
  Scenario: Reject invalid menu listing filters
    Test Case ID: IT-MI-019
    Given invalid menu listing filters
    When brand or all-brand menu listings are requested
    Then the response is 400 before querying

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-020
  Scenario: Documents a required boolean body and the success/error responses
    Test Case ID: IT-MI-020
    Given the generated availability operation schema
    When its request and response contracts are inspected
    Then a required boolean body and success and error responses are documented

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-021
  Scenario: Save either availability boolean and return the updated item
    Test Case ID: IT-MI-021
    Given an existing menu item and a boolean availability value
    When availability is changed
    Then the response is 200 with the updated item and the boolean reaches the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-022
  Scenario: Allow permitted roles to change menu availability
    Test Case ID: IT-MI-022
    Given a role permitted to change menu availability
    When availability is changed
    Then the response is 200 and the handler receives the item UUID and requested value

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-023
  Scenario: Requires authentication
    Test Case ID: IT-MI-023
    Given no authenticated session
    When menu availability is changed
    Then the response is 401 without invoking the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-024
  Scenario: Denies cashiers
    Test Case ID: IT-MI-024
    Given an authenticated cashier
    When menu availability is changed
    Then the response is 403 without invoking the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-025
  Scenario: Allow permitted roles to change availability across brands
    Test Case ID: IT-MI-025
    Given a permitted role with shared brand access
    When another brand's menu availability is changed
    Then the response is 200

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-026
  Scenario: Reject invalid availability payloads
    Test Case ID: IT-MI-026
    Given an invalid availability payload
    When availability is changed
    Then the response is 400 before calling the service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-027
  Scenario: Rejects a code on the UUID-only route
    Test Case ID: IT-MI-027
    Given a menu code rather than a UUID on the availability route
    When availability is changed
    Then the response is 400

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-028
  Scenario: Rejects a missing item before invoking the service
    Test Case ID: IT-MI-028
    Given the requested menu item does not exist
    When availability is changed
    Then the response is 404 before invoking the availability service

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-029
  Scenario: Returns the availability conflict code
    Test Case ID: IT-MI-029
    Given the service reports unchanged availability
    When availability is changed
    Then the response is 409 with AVAILABILITY_CONFLICT

  # Jest: server/src/modules/menu/menu-items/tests/menu-items.http.spec.ts
  # Context: Menu items HTTP endpoints / availability toggle
  @IT-MI-030
  Scenario: Preserves service not-found errors for inactive items or brands
    Test Case ID: IT-MI-030
    Given the service reports an inactive item or brand as missing
    When availability is changed
    Then the not-found response remains 404
