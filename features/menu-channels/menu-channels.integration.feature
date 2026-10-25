@backend @integration @postgresql @menu-channels
Feature: Persist and authorize menu channel operations
  Tests use the real application, guards, services and a migrated test database.

  @IT-MCH-001
  Scenario Outline: Authorize channel creation through actual sessions
    Given a <user> session and an active item in brand A
    When the user creates a GrabFood override
    Then the response status is <status>
    And a row is inserted only for a successful request
    Examples:
      | user                  | status |
      | brand A manager       | 201    |
      | brand A cashier       | 403    |
      | superadmin            | 201    |
      | brand B manager       | 403    |
      | unauthenticated user  | 401    |

  @IT-MCH-002
  Scenario Outline: Deny cross-brand access without mutation
    Given a saved channel in brand A
    When brand B manager attempts to <operation> it
    Then the response status is 403
    And its price and availability remain unchanged
    Examples:
      | operation  |
      | read       |
      | update     |
      | delete     |
      | reactivate |

  @IT-MCH-003
  Scenario Outline: Reserve the global listing for superadmins
    Given an authenticated <user>
    When all menu channels are listed
    Then the response status is <status>
    Examples:
      | user            | status |
      | brand A manager | 403    |
      | cashier         | 403    |
      | superadmin      | 200    |
      | brand B manager | 403    |

  @IT-MCH-004
  Scenario Outline: Enforce channel uniqueness
    Given two create requests for the same item and GrabFood channel
    When they are submitted <timing>
    Then one response is 201 and the other is 409
    And exactly one override exists in PostgreSQL
    Examples:
      | timing         |
      | sequentially   |
      | concurrently   |

  @IT-MCH-005
  Scenario: Persist the entire channel lifecycle
    Given a channel created through the API
    When its price is updated then it is deleted
    Then its saved price is 150 and the default read returns 404
    And an inactive-inclusive read returns the unavailable channel
    When the channel is reactivated
    Then the default read returns the available channel priced at 150
    And another reactivation returns 409

  @IT-MCH-006
  Scenario Outline: Enforce channel decimal boundaries
    Given a price of <price>
    When channel creation and price update are requested
    Then the response statuses are <createStatus> and <updateStatus>
    And rejected creation inserts no row
    And rejected update preserves the original price
    Examples:
      | price          | createStatus | updateStatus |
      | 0              | 201          | 200          |
      | 9999999999.99  | 201          | 200          |
      | -0.01          | 400          | 400          |
      | 10000000000    | 400          | 400          |
      | 1.001          | 400          | 400          |
      | null           | 400          | 400          |
      | string 120     | 400          | 400          |

  @IT-MCH-007
  Scenario Outline: Apply consistent listing predicates
    Given available and unavailable overrides for both platforms
    When item-specific and paginated listings use activeOnly <activeOnly>
    Then the item listing contains <count> fixture rows
    And the GrabFood pagination total matches the same database predicate
    Examples:
      | activeOnly | count |
      | true       | 1     |
      | false      | 2     |
