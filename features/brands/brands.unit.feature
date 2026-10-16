Feature: Brands Service Unit Logic
  Feature ID: FEAT-BRND-UNIT
  Requirement ID: FR-001

  As the backend brand service,
  I want to manage brands and brand-to-user assignments in isolation,
  So that multi-brand access control is enforced consistently.

  Scenario: Create brand assignment for user and brand
    Test Case ID: UT-BRND-001
    Given an existing user and brand
    When BrandsService assigns user to brand
    Then it should persist and return the new assignment

  Scenario: Reject assignment when user or brand is missing
    Test Case ID: UT-BRND-002
    Given a non-existent user or brand ID
    When BrandsService attempts to assign the user
    Then it should throw NotFoundException without writing

  Scenario: Propagate duplicate race or foreign key errors
    Test Case ID: UT-BRND-003
    Given a concurrent race or DB constraint violation on assignUser
    When BrandsRepository throws P2002 or P2003
    Then BrandsService should rethrow the error for the global filter

  Scenario: Reject assignment when assignment already exists
    Test Case ID: UT-BRND-004
    Given an existing active or inactive assignment
    When BrandsService attempts to assign the user
    Then it should throw ConflictException with code EXISTING_ASSIGNMENT_FOUND

  Scenario: Propagate lookup failures on assignment
    Test Case ID: UT-BRND-005
    Given a database failure during assignment lookup
    When BrandsService attempts to assign user
    Then it should rethrow the database error without writing

  Scenario: Reject reactivation when related user or brand is missing
    Test Case ID: UT-BRND-006
    Given a deactivated assignment where the related user or brand is missing
    When BrandsService attempts to reactivate the assignment
    Then it should throw NotFoundException

  Scenario: Reactivate inactive assignment
    Test Case ID: UT-BRND-007
    Given an inactive assignment with active user and brand
    When BrandsService reactivates the assignment
    Then it should update is_active to true and log the reactivation

  Scenario: Reject reactivation of missing or already active assignment
    Test Case ID: UT-BRND-008
    Given a non-existent assignment or an already active assignment
    When BrandsService attempts reactivation
    Then it should throw NotFoundException or ConflictException

  Scenario: Handle concurrency conflict and propagate errors on reactivation
    Test Case ID: UT-BRND-009
    Given a concurrent modification race on reactivateBrandAssignment
    When BrandsRepository throws P2025
    Then BrandsService should throw ConflictException with code BRAND_ASSIGNMENT_CHANGED

  Scenario: Update existing brand
    Test Case ID: UT-BRND-010
    Given an existing brand ID and UpdateBrandDTO
    When BrandsService updates the brand
    Then it should persist the changes and return the updated entity

  Scenario: Handle not-found and propagate errors on brand update
    Test Case ID: UT-BRND-011
    Given a non-existent brand ID or database failure
    When BrandsService attempts update
    Then it should throw NotFoundException or rethrow the database error

  Scenario: Propagate P2025 when brand is deleted concurrently
    Test Case ID: UT-BRND-012
    Given a brand deleted concurrently after initial existence check
    When BrandsService updates or deletes the brand
    Then it should propagate P2025 to the global Prisma filter

  Scenario: Delete existing brand
    Test Case ID: UT-BRND-013
    Given an existing brand ID
    When BrandsService deletes the brand
    Then it should deactivate the brand and its associated assignments

  Scenario: Paginate brand assignments for user
    Test Case ID: UT-BRND-014
    Given an existing user ID and FindBrandsDTO
    When BrandsService lists brand assignments for user
    Then it should return paginated assignments and meta information

  Scenario: Reject missing user and invalid offset on user assignments
    Test Case ID: UT-BRND-015
    Given a non-existent user ID or out-of-range page number
    When BrandsService lists assignments
    Then it should throw NotFoundException or BadRequestException

  Scenario: Paginate assigned users for brand
    Test Case ID: UT-BRND-016
    Given an existing brand ID and FindBrandsDTO
    When BrandsService lists assigned users for brand
    Then it should return paginated users and meta information

  Scenario: Reject missing brand and invalid offset on brand users
    Test Case ID: UT-BRND-017
    Given a non-existent brand ID or out-of-range page number
    When BrandsService lists assigned users
    Then it should throw NotFoundException or BadRequestException
