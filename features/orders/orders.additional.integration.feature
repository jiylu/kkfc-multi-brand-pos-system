@backend @integration @orders
Feature: Additional orders integration coverage
  Feature ID: FEAT-ORD-IT-ADDITIONAL
  Requirement ID: FR-ORD-001

  As a backend maintainer,
  I want the orders behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-018
  Scenario: Reject order operations under the wrong brand URL
    Test Case ID: IT-ORD-018
    Given an order under a different brand than the URL
    When verification, confirmation, or cancellation is requested through that URL
    Then the response is 404 and the saved order remains a draft

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-019
  Scenario: Persists failed PIN attempts across different protected endpoints and enforces cooldown
    Test Case ID: IT-ORD-019
    Given an employee repeatedly supplies an incorrect PIN across protected endpoints
    When failed attempts reach the cooldown threshold
    Then attempts persist across endpoints, writes remain blocked, and a later valid attempt clears the lock after cooldown

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-020
  Scenario: Keeps reads and availability changes usable without an action PIN
    Test Case ID: IT-ORD-020
    Given an authenticated permitted employee without an action PIN
    When menu reads or availability changes are requested
    Then the operations succeed without a PIN

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-021
  Scenario: Assigns consecutive daily codes across channels and keeps cancelled draft numbers
    Test Case ID: IT-ORD-021
    Given orders are created for one brand across multiple channels on one Manila date
    When drafts are created and one is cancelled
    Then daily codes increase consecutively and cancelled draft numbers are not reused

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-022
  Scenario: Starts a separate sequence for another brand
    Test Case ID: IT-ORD-022
    Given another brand has its own catalog
    When its first order is created
    Then its independent daily sequence begins at one

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-023
  Scenario: Assigns different codes to simultaneous creates and preserves them on replay
    Test Case ID: IT-ORD-023
    Given multiple different order payloads are created concurrently
    When creation completes and one request is replayed
    Then each order has a distinct consecutive code and the replay preserves its original code

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-024
  Scenario: Allocates one number for simultaneous creates with the same UUID
    Test Case ID: IT-ORD-024
    Given two identical requests use the same order UUID concurrently
    When both drafts are created
    Then both responses identify one saved order and only one sequence number is allocated

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-025
  Scenario: Rolls back the allocated number if order insertion fails
    Test Case ID: IT-ORD-025
    Given order insertion fails after daily number allocation
    When a later valid order is created
    Then the failed allocation is rolled back and the next order starts at one

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)
  @IT-ORD-026
  Scenario: Continues a seeded daily counter and snapshots subsequent brand code changes
    Test Case ID: IT-ORD-026
    Given a seeded daily counter and an order saved before a brand code change
    When the order is replayed and another order is created
    Then the replay preserves its original code while the new order uses the changed prefix and next number

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: Daily order code migration
  @IT-ORD-027
  Scenario: Backfills Manila dates deterministically and seeds each brand/date counter
    Test Case ID: IT-ORD-027
    Given legacy orders span brands and Manila dates
    When the daily order code migration is applied
    Then dates and numbers are backfilled deterministically and each brand and date receives a valid counter

  # Jest: server/src/modules/orders/orders/catalog-orders.http.spec.ts
  # Context: User brand removal migration
  @IT-ORD-028
  Scenario: Drops assignments while preserving users, brands, and sessions
    Test Case ID: IT-ORD-028
    Given legacy users have brand assignments and active sessions
    When the user brand removal migration is applied
    Then assignments are removed while users, brands, and sessions are preserved

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-029
  Scenario: Allow permitted cancellation roles and use the session actor
    Test Case ID: IT-ORD-029
    Given an authenticated cashier, manager, or superadmin and a valid cancellation body
    When order cancellation is requested
    Then the response is 200 and the actor is taken from the session

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-030
  Scenario: Reject invalid or extra cancellation fields
    Test Case ID: IT-ORD-030
    Given an invalid cancellation body or an extra field
    When order cancellation is requested
    Then the response is 400 before calling the cancellation service

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-031
  Scenario: Requires authentication
    Test Case ID: IT-ORD-031
    Given no authenticated session
    When order cancellation is requested
    Then the response is 401

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-032
  Scenario: Rejects other roles
    Test Case ID: IT-ORD-032
    Given a role without order cancellation permission
    When order cancellation is requested
    Then the response is 403

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-033
  Scenario: Returns 404 for a missing order
    Test Case ID: IT-ORD-033
    Given the cancellation service reports a missing order
    When order cancellation is requested
    Then the response is 404

  # Jest: server/src/modules/orders/orders/orders-cancel.http.spec.ts
  # Context: Cancel order HTTP API
  @IT-ORD-034
  Scenario: Rejects malformed order IDs
    Test Case ID: IT-ORD-034
    Given a malformed order UUID
    When order cancellation is requested
    Then the response is 400 before calling the cancellation service
