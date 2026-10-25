@backend @unit @menu-channels
Feature: Menu channel creation and lookup
  Platform overrides belong to active menu items and preserve lookup filters.

  @UT-MCH-001
  Scenario Outline: Create a supported platform override
    Given an active menu item
    When its channel override is created for <channel> at 120 pesos
    Then the repository receives the supplied fields and its saved record is returned
    Examples:
      | channel   |
      | GRABFOOD  |
      | FOODPANDA |

  @UT-MCH-002
  Scenario Outline: Reject overrides for internal channels
    Given an override request for <channel>
    When the channel creation service is called
    Then it returns INVALID_ORDER_CHANNEL with status 400
    And neither the menu lookup nor the channel insert is called
    Examples:
      | channel  |
      | DINE_IN  |
      | TAKEAWAY |

  @UT-MCH-003
  Scenario: Reject creation without an active parent
    Given the active parent menu lookup returns no item
    When a GrabFood channel is created
    Then the service returns not found without inserting a channel

  @UT-MCH-004
  Scenario Outline: Preserve the channel lookup filter
    Given activeOnly is <activeOnly>
    When a channel is retrieved
    Then that filter is passed to the repository
    And a missing repository result returns not found
    Examples:
      | activeOnly |
      | true       |
      | false      |

  @UT-MCH-005
  Scenario Outline: List filtered channels of an active parent
    Given an active parent menu item and activeOnly <activeOnly>
    When its Foodpanda channels are listed
    Then the parent ID and both filters reach the repository
    Examples:
      | activeOnly |
      | true       |
      | false      |

  @UT-MCH-006
  Scenario: Stop a channel listing when its parent is missing
    Given no active parent menu item
    When its channels are listed
    Then the service returns not found before querying channels
