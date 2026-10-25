@mobile @widget @routing
Feature: Protected navigation and draft retention

  @IT-MOB-ROUTE-001
  Scenario Outline: Redirect unauthenticated deep links
    Given no signed-in session
    When the router opens <route>
    Then the login screen and login location are active
    Examples:
      | route           |
      | /menu           |
      | /orders         |
      | /channel-change |
      | /availability   |

  @IT-MOB-ROUTE-002
  Scenario Outline: Redirect after session expiration
    Given a signed-in user on <route>
    When the current token expires
    Then the router presents login and flags the session as expired
    Examples:
      | route           |
      | /menu           |
      | /orders         |
      | /channel-change |
      | /availability   |

  @IT-MOB-CART-001
  Scenario: Retain a draft across route changes
    Given a cart containing one meal priced at 12345 centavos
    When the user visits menu orders repricing and menu again
    Then the same cart lines remain with count 1 and total 12345
