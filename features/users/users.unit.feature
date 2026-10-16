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
