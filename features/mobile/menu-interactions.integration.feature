@mobile @widget @menu
Feature: Menu interactions and asynchronous states

  @IT-MOB-MENU-001
  Scenario Outline: Respect item availability
    Given a menu card with <availability> availability
    When it is tapped
    Then the cart count is <count>
    And unavailable cards display their matching status badge
    Examples:
      | availability | count |
      | available    | 1     |
      | stockout     | 0     |
      | manualOff    | 0     |
      | inactive     | 0     |

  @IT-MOB-MENU-002
  Scenario: Replace loading skeletons with data
    Given a pending menu load
    When the menu screen is rendered
    Then a loading skeleton is visible
    When the load completes with an item
    Then the skeleton disappears and an item card is visible

  @IT-MOB-MENU-003
  Scenario: Recover from a failed load
    Given the initial menu load fails
    When Try again is tapped
    Then the menu provider loads a second time
    And the recovered item card is displayed

  @IT-MOB-MENU-004
  Scenario: Clear a search with no matches
    Given a loaded menu and a search that matches nothing
    When Clear search is tapped
    Then the search provider and text field are empty
    And the menu cards are restored

  @IT-MOB-MENU-005
  Scenario: Render an empty catalog
    Given a menu load returning no items
    When the menu screen settles
    Then an empty message is displayed without item cards
