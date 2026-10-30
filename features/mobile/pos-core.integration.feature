@mobile @integration @real_api @pos
Feature: Mobile POS core flow through the real test API

  @IT-MOB-POS-001
  Scenario: Login and build a cart using the assigned brand and channel
    Given an isolated staff account with an assigned brand and priced menu
    When the staff member logs in and selects Takeaway
    And adds the available meal twice from the menu
    Then one cart line contains two meals with a total of 250 pesos
    When the staff member adds and removes one unit using the cart controls
    Then the quantities and totals update correctly
    When the staff member clears the cart
    Then the cart is empty

  @IT-MOB-POS-002
  Scenario: Reprice an existing cart when changing channels
    Given a logged in staff member with two meals in the Dine-in cart
    When the staff member selects Takeaway
    Then the repricing notice shows without losing the cart lines
    And the total changes from 200 to 250 pesos
    When the staff member acknowledges the notice
    Then the menu returns and the cart retains the Takeaway prices

  @IT-MOB-POS-003
  Scenario: Unavailable menu items cannot enter the cart
    Given a logged in staff member with a real API menu
    When the staff member taps the unavailable meal
    Then the cart remains empty
    When the staff member searches for and taps the available meal
    Then the cart contains one meal at the Dine-in price of 100 pesos
