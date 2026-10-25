@mobile @widget @brand-switch @prototype
Feature: Current prototype brand-switch behavior
  These tests describe the implemented confirmation flow, not a finalized product policy.

  @IT-MOB-BRAND-001
  Scenario: Cancel switching a populated cart
    Given a populated cart for brand A
    When brand B is selected and Keep current order is tapped
    Then brand A and the same cart remain selected

  @IT-MOB-BRAND-002
  Scenario: Confirm switching a populated cart
    Given a populated cart for brand A
    When brand B is selected and Clear cart and switch is tapped
    Then brand B is selected and the cart is empty with zero total

  @IT-MOB-BRAND-003
  Scenario: Continue with the current brand
    Given a populated cart for brand A
    When the picker continues with brand A
    Then no discard confirmation is displayed and the cart is preserved

  @IT-MOB-BRAND-004
  Scenario: Dismiss the picker
    Given a populated cart and an open brand picker
    When the picker barrier is tapped
    Then the picker closes without changing brand or cart

  @IT-MOB-BRAND-005
  Scenario: Switch an empty cart
    Given an empty cart for brand A and an observed menu provider
    When brand B is selected
    Then brand B is activated without a discard confirmation
    And the menu provider starts a new load

  @IT-MOB-BRAND-006
  Scenario: Reach brand-switch actions with enlarged text
    Given a 320 by 900 phone viewport with text scale 2
    When the picker and confirmation are opened
    Then neither dialog overflows
    And the confirmation can be scrolled into view and activated
