@backend @unit @brands
Feature: Global brand administration without employee assignments

  @UT-BRND-018
  Scenario: Creates a brand without changing user assignments
    Given employees exist
    When a brand is created
    Then leave employee records unchanged

  @UT-BRND-019
  Scenario: Propagates creation failures from an explicit transaction
    Given a failing explicit transaction
    When a brand is created
    Then propagate the error without changing employees

  @UT-BRND-020
  Scenario: Lists all brands with matching totals and activeOnly=the requested value
    Given activeOnly=the requested value
    When brands are listed
    Then rows and counts use the same global filter

  @UT-BRND-021
  Scenario: Deactivates only the brand, leaving users active
    Given active employees
    When a brand is deactivated
    Then leave employees active

  @UT-BRND-022
  Scenario: Queries only active brands by default
    Given a default lookup
    When a brand is retrieved
    Then query only active brands

  @UT-BRND-023
  Scenario: Propagates a duplicate code during the requested value to the global conflict filter
    Given a duplicate code
    When the requested value fails
    Then propagate P2002 for the global conflict filter

  @UT-BRND-024
  Scenario: Creates a brand with the supplied code
    Given a supplied brand code
    When a brand is created
    Then persist that code

  @UT-BRND-025
  Scenario: Returns an active brand and rejects a missing or inactive brand
    Given an active or missing brand
    When it is retrieved
    Then return it or BRAND_NOT_FOUND

  @UT-BRND-026
  Scenario: Preserves the code when only the name or logo changes: the requested value
    Given name change the requested value without a code
    When the brand is updated
    Then preserve its code

  @UT-BRND-027
  Scenario: Updates the code directly without requiring a name change
    Given a code-only update
    When the brand is updated
    Then persist the supplied code

  @UT-BRND-010
  Scenario: Updates an existing brand using the supplied fields
    Given an existing brand
    When supplied fields are updated
    Then persist and return the changes

  @UT-BRND-011
  Scenario: Uses the standard not-found error and propagates update/delete failures
    Given a missing brand or failed update
    When the brand is updated
    Then return the standard error without logging success

  @UT-BRND-012
  Scenario: Propagates P2025 to the global filter when a brand disappears before the requested value
    Given a concurrently removed brand
    When the requested value loses its write
    Then propagate P2025 to the global filter

  @UT-BRND-013
  Scenario: Deletes an existing brand and rejects missing brands
    Given an existing or missing brand
    When it is deleted
    Then deactivate it or return BRAND_NOT_FOUND

  @UT-BRND-028
  Scenario: Rejects pagination offsets beyond the database range
    Given a pagination offset beyond the database range
    When brands are listed
    Then reject before querying

  @UT-BRND-029
  Scenario: Returns zero pages for an empty listing
    Given no matching brands
    When brands are listed
    Then return zero total pages

  @UT-BRND-030
  Scenario: Returns pagination metadata and forwards activeOnly=the requested value
    Given activeOnly=the requested value and page 2
    When brands are listed
    Then return matching pagination metadata
