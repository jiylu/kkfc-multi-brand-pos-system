@backend @unit @orders
Feature: Order catalog and payment rules

  @UT-ORD-001
  Scenario Outline: Fall back to the base price without an override
    Given an active menu item priced at 10 pesos without a channel override
    When the draft is <operation>
    Then the resulting line price is 10 pesos
    Examples:
      | operation |
      | verified  |
      | confirmed |

  @UT-ORD-002
  Scenario Outline: Reject an unavailable override
    Given a draft whose menu channel override is unavailable
    When the draft is <operation>
    Then the service rejects the request before snapshot or ticket writes
    Examples:
      | operation |
      | verified  |
      | confirmed |

  @UT-ORD-003
  Scenario Outline: Reject an unusable recipe
    Given a menu item with a recipe that is <condition>
    When its draft is confirmed
    Then the service returns a bad request before snapshot or ticket writes
    Examples:
      | condition                    |
      | missing                      |
      | inactive                     |
      | a production recipe          |
      | using zero component quantity |
      | using negative component quantity |
      | using NaN component quantity |
      | using infinite component quantity |

  @UT-ORD-004
  Scenario Outline: Accept each supported internal payment combination
    Given a <channel> draft
    When it is verified with <method> and <status>
    Then verification preserves that payment without updating the order
    Examples:
      | channel  | method   | status |
      | DINE_IN  | CASH     | UNPAID |
      | DINE_IN  | CASH     | PAID   |
      | DINE_IN  | E_WALLET | UNPAID |
      | DINE_IN  | E_WALLET | PAID   |
      | DINE_IN  | CARD     | UNPAID |
      | DINE_IN  | CARD     | PAID   |
      | TAKEAWAY | CASH     | UNPAID |
      | TAKEAWAY | CASH     | PAID   |
      | TAKEAWAY | E_WALLET | UNPAID |
      | TAKEAWAY | E_WALLET | PAID   |
      | TAKEAWAY | CARD     | UNPAID |
      | TAKEAWAY | CARD     | PAID   |

  @UT-ORD-005
  Scenario Outline: Reject incompatible payment
    Given a <channel> draft
    When confirmation requests <method> and <status>
    Then the service returns a bad request without snapshot or ticket writes
    Examples:
      | channel   | method           | status   |
      | TAKEAWAY  | PLATFORM_SETTLED | PAID     |
      | DINE_IN   | CASH             | REFUNDED |
      | GRABFOOD  | CASH             | PAID     |
      | FOODPANDA | PLATFORM_SETTLED | UNPAID   |

  @UT-ORD-006
  Scenario Outline: Reject missing operational references
    Given a create request with <references>
    When the order is created
    Then the service returns a bad request without inserting an order
    Examples:
      | references                         |
      | a whitespace-only dine-in table    |
      | a GrabFood store without an order  |
      | a Foodpanda order without a store  |
      | a whitespace-only GrabFood store   |
