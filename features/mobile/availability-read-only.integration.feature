@mobile @widget @availability
Feature: Backend-backed read-only availability
  The read-only screen lists the active brand's menu items and their
  availability for the selected channel.

  @IT-MOB-AVAIL-003
  Scenario: List backend menu items for the selected channel
    Given the backend brand menu contains active and inactive items
    When the read-only availability screen opens on Dine-in
    Then every menu item is listed with its Dine-in availability
    And inactive items are marked Inactive

  @IT-MOB-AVAIL-004
  Scenario: Change the availability channel
    Given backend menu items with different per-channel availability
    When the Takeaway channel is selected
    Then the rows show Takeaway availability

  @IT-MOB-AVAIL-005
  Scenario: Show a loading state while availability loads
    Given a pending availability request
    When the read-only availability screen opens
    Then a loading message is visible
    And the rows replace it when data arrives

  @IT-MOB-AVAIL-006
  Scenario: Recover from a failed availability request
    Given the availability request fails
    When Try again is pressed
    Then the menu items are displayed

  @IT-MOB-AVAIL-007
  Scenario: Show an empty availability state
    Given the active brand has no menu items
    When the read-only availability screen opens
    Then an empty menu message is visible
