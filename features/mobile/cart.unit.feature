@mobile @unit @cart
Feature: Cart quantities and monetary calculations

  @UT-MOB-CART-001
  Scenario: Merge repeated additions without mutating previous state
    Given an empty cart and a meal priced at 100 pesos
    When the meal is added twice
    Then one line has quantity 2 and the total is 20000 centavos
    And the state captured after the first addition still has quantity 1

  @UT-MOB-CART-002
  Scenario: Decrement and remove the last unit
    Given a cart containing two units
    When an unknown item is decremented
    Then the quantity remains 2
    When the known item is decremented twice
    Then the first decrement leaves quantity 1
    And the final decrement removes the line and resets count and total

  @UT-MOB-CART-003
  Scenario: Clear a populated cart
    Given a populated cart and its previously captured state
    When the cart is cleared
    Then the lines count and total are empty or zero
    And the captured state is unchanged

  @UT-MOB-CART-004
  Scenario: Reprice quantities and modifiers in integer centavos
    Given two meals with extra rice costing 25000 centavos on dine-in
    When the selected channel becomes GrabFood
    Then the total becomes 29000 centavos
    And quantities modifiers and cart line identities are preserved

  @UT-MOB-MONEY-001
  Scenario Outline: Format peso amounts exactly
    Given <centavos> centavos
    When the amount is formatted
    Then the result is "<formatted>"
    Examples:
      | centavos | formatted |
      | 0        | ₱0.00     |
      | 1        | ₱0.01     |
      | 99       | ₱0.99     |
      | 100      | ₱1.00     |
      | 123456   | ₱1,234.56 |

  @UT-MOB-SEARCH-001
  Scenario Outline: Search names and descriptions
    Given a chicken meal described as a grilled favorite and a rice item
    When the query is "<query>"
    Then only the chicken meal is visible
    When the query is cleared
    Then both items are visible
    Examples:
      | query     |
      |  CHICKEN  |
      |  grilled  |

  @UT-MOB-SEARCH-002
  Scenario: Propagate asynchronous menu states
    Given a pending menu load
    When visible items are observed
    Then the visible state is loading
    When the menu load fails
    Then the same failure is exposed instead of an empty successful list
