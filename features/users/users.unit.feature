Feature: Users Service Unit Logic
  Feature ID: FEAT-USER-UNIT
  Requirement ID: FR-USER-001

  As the backend user service,
  I want to perform CRUD operations on user accounts in isolation,
  So that user data is validated, passwords securely hashed, and uniqueness rules enforced.

  Scenario: Create user with valid payload
    Test Case ID: UT-USER-001
    Given valid CreateUserDTO details
    When UsersService creates the user
    Then it should persist the record and return the created user

  Scenario: Prevent duplicate username on creation
    Test Case ID: UT-USER-002
    Given a username that is already registered in UsersRepository
    When UsersService attempts to create a user with that username
    Then it should throw ConflictException with code USERNAME_ALREADY_EXISTS

  Scenario: Propagate Prisma create failures to global filter
    Test Case ID: UT-USER-003
    Given a database error during user creation
    When UsersRepository throws PrismaClientKnownRequestError
    Then UsersService should rethrow the error for the global exception filter

  Scenario: Paginate users and forward activeOnly flag
    Test Case ID: UT-USER-004
    Given pagination query parameters
    When UsersService finds all users
    Then it should calculate skip/take and return paginated data with meta

  Scenario: Return empty list and zero pages when no users match
    Test Case ID: UT-USER-005
    Given no matching users in repository
    When UsersService finds all users
    Then it should return empty data array with total=0 and totalPages=0

  Scenario: Return empty page when page exceeds total records
    Test Case ID: UT-USER-006
    Given a page number past available records
    When UsersService queries the repository
    Then it should return empty data while preserving total and totalPages

  Scenario: Reject pagination offsets exceeding 32-bit integer range
    Test Case ID: UT-USER-007
    Given an excessively large page number causing 32-bit integer overflow
    When UsersService calculates skip offset
    Then it should throw BadRequestException with code PAGINATION_UNSUPPORTED_RANGE

  Scenario: Allow largest page number within database range
    Test Case ID: UT-USER-008
    Given a boundary page number with limit 1
    When UsersService queries the repository
    Then it should accept the offset and query the repository

  Scenario: Find single user by ID
    Test Case ID: UT-USER-009
    Given an existing user ID
    When UsersService queries the user
    Then it should return the matching user entity

  Scenario: Allow explicitly finding an inactive user
    Test Case ID: UT-USER-010
    Given an inactive user ID and activeOnly=false
    When UsersService queries the user
    Then it should return the inactive user record

  Scenario: Update existing user with valid fields
    Test Case ID: UT-USER-011
    Given an active user ID and UpdateUserDTO
    When UsersService updates the user
    Then it should update the user in UsersRepository and return the updated entity

  Scenario: Reject update when user is deactivated concurrently
    Test Case ID: UT-USER-012
    Given a user that is deactivated after the initial existence lookup
    When UsersRepository update throws Prisma P2025
    Then UsersService should throw NotFoundException with code USER_NOT_FOUND

  Scenario: Propagate database update failures
    Test Case ID: UT-USER-013
    Given an unrelated database connection error during update
    When UsersRepository update fails
    Then UsersService should propagate the error

  Scenario: Deactivate existing user
    Test Case ID: UT-USER-014
    Given an active user ID
    When UsersService deletes the user
    Then it should set is_active to false in UsersRepository

  Scenario: Reject finding, updating, or deactivating missing user
    Test Case ID: UT-USER-015
    Given a non-existent user ID
    When findOneUser, updateUser, or deleteUser is called
    Then UsersService should throw NotFoundException with code USER_NOT_FOUND without writing

  Scenario: Propagate repository failures across all service methods
    Test Case ID: UT-USER-016
    Given a generic database outage
    When any UsersService method is invoked
    Then it should rethrow the database error

  Scenario Outline: Staff cannot create accounts
    Test Case ID: UT-USER-017
    Given mocked repositories and a caller with a staff role
    When the real controller and service receive a creation request for any role
    Then the operation is forbidden before any repository write
    Examples:
      | caller          |
      | CASHIER_STAFF   |
      | KITCHEN_STAFF   |
      | INVENTORY_STAFF |

  Scenario: Manager cannot create Manager, Recipe Manager or Superadmin
    Test Case ID: UT-USER-018
    Given mocked repositories and a Manager caller
    When a senior account is requested
    Then the operation is forbidden before any repository write

  Scenario: Supervisor cannot create a peer or senior account
    Test Case ID: UT-USER-019
    Given mocked repositories and a Supervisor caller
    When a Supervisor, Manager or Recipe Manager account is requested
    Then the operation is forbidden before any repository write

  Scenario: Creation cannot cross the assigned brand
    Test Case ID: UT-USER-020
    Given a Manager, Recipe Manager or Supervisor assigned to one brand
    When a staff account is requested in another brand
    Then the operation is forbidden before any repository write

  Scenario: Superadmin can submit a senior account creation
    Test Case ID: UT-USER-021
    Given mocked repositories and a Superadmin caller
    When a Manager or Recipe Manager account is requested
    Then the creation reaches the repository once
    And this does not certify approval, enrollment or activation

  @pending
  Scenario: Recipe Manager creation respects department boundaries
    Test Case ID: UT-USER-022
    Given an approved department membership and subordinate-role policy
    When a Recipe Manager requests a subordinate in another department
    Then the request is forbidden

  @pending
  Scenario: Higher-role approval respects the approved role matrix
    Test Case ID: UT-USER-023
    Given a pending account request and approved top-owner exception policy
    When a self, same-rank or unauthorized cross-scope approval is attempted
    Then the request is denied except for the explicitly approved exception

  @pending
  Scenario: Approval transitions remain consistent under conflicts
    Test Case ID: UT-USER-024
    Given duplicate, concurrent or expired approval requests
    When approve or reject is attempted
    Then only one valid transition is recorded with its rejection reason when required

  @pending
  Scenario: Protect the last active owner
    Test Case ID: UT-USER-025
    Given one remaining active owner or concurrent owner-deactivation requests
    When deactivation would remove the final active owner
    Then at least one active owner remains

  @pending
  Scenario: Record account mutations without secrets
    Test Case ID: UT-USER-026
    Given successful and denied staff-account changes
    When account mutation audit events are written
    Then actor, target and outcome are preserved without credentials or tokens
