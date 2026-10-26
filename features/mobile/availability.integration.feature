@mobile @widget @availability @prototype
Feature: Local availability screen interactions
  Persistence, audit writes and backend permission rules are not implemented by this screen.

  @IT-MOB-AVAIL-001
  Scenario: Toggle one item and channel row
    Given the sample availability rows
    When the first row is toggled
    Then only its availability changes
    And its On or Off label and toggled semantics reflect the new value

  @IT-MOB-AVAIL-002
  Scenario: Use availability with enlarged text
    Given a 320 by 900 phone viewport with text scale 2
    When the availability screen is opened
    Then no layout exception occurs
    And the last toggle can be scrolled into view
