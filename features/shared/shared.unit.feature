Feature: Shared Infrastructure and Security Unit Logic
  Feature ID: FEAT-SHRD-UNIT
  Requirement ID: FR-029

  As the backend application platform,
  I want robust global exception handling, role guards, and cloud file storage utilities,
  So that API errors are sanitized, endpoints secured, and private S3 URLs securely generated.

  Scenario: Preserve application error codes and log client errors as warnings
    Test Case ID: UT-SHRD-001
    Given an endpoint throwing a custom BadRequestException
    When AllExceptionsFilter catches the exception
    Then it should preserve the status code and JSON error payload

  Scenario: Preserve validation message arrays
    Test Case ID: UT-SHRD-002
    Given an endpoint throwing a validation error with message array
    When AllExceptionsFilter catches the exception
    Then it should return HTTP 400 with the full message list

  Scenario: Map Prisma known errors to HTTP status without leaking database details
    Test Case ID: UT-SHRD-003
    Given a Prisma P2002 or P2025 known request error
    When PrismaExceptionFilter handles the exception
    Then it should return 409 DUPLICATE_RESOURCE or 404 RESOURCE_NOT_FOUND without internal details

  Scenario: Preserve custom service not-found responses
    Test Case ID: UT-SHRD-004
    Given an endpoint throwing a custom NotFoundException
    When AllExceptionsFilter catches the exception
    Then it should return 404 with the custom response body

  Scenario: Preserve custom service conflict responses
    Test Case ID: UT-SHRD-005
    Given an endpoint throwing a custom ConflictException
    When AllExceptionsFilter catches the exception
    Then it should return 409 with the custom response body

  Scenario: Map unhandled Prisma errors to HTTP 500
    Test Case ID: UT-SHRD-006
    Given an unexpected Prisma error such as P1001 or P2003
    When AllExceptionsFilter catches the error
    Then it should return HTTP 500 without leaking database connection details

  Scenario: Log HTTP server errors once
    Test Case ID: UT-SHRD-007
    Given an InternalServerErrorException
    When AllExceptionsFilter catches the error
    Then it should log the server error and return HTTP 500

  Scenario: Delegate unexpected failures to Nest without leaking details
    Test Case ID: UT-SHRD-008
    Given an unhandled Error or non-standard thrown value
    When AllExceptionsFilter catches the error
    Then it should return HTTP 500 Internal server error

  Scenario: RolesGuard uses controller roles when endpoint has no override
    Test Case ID: UT-SHRD-009
    Given a controller decorated with Roles(OWNER)
    When a request from a KITCHEN_PREPARER accesses the method
    Then RolesGuard should throw ForbiddenException

  Scenario: RolesGuard allows listed endpoint roles and overrides controller roles
    Test Case ID: UT-SHRD-010
    Given a method decorated with Roles(KITCHEN_HEAD, KITCHEN_PREPARER) overriding controller
    When a request from a KITCHEN_PREPARER accesses the method
    Then RolesGuard should allow access

  Scenario: StorageService generates presigned PutObject upload URL
    Test Case ID: UT-SHRD-011
    Given an original filename and MIME content type
    When StorageService creates an upload URL
    Then it should generate a 5-minute presigned PutObject command with randomized key

  Scenario: StorageService generates presigned GetObject download URL
    Test Case ID: UT-SHRD-012
    Given an existing S3 object key
    When StorageService creates a download URL
    Then it should generate a 5-minute presigned GetObject command

  Scenario: StorageService throws ServiceUnavailableException when bucket not configured
    Test Case ID: UT-SHRD-013
    Given an unconfigured or empty S3_BUCKET setting
    When StorageService is invoked
    Then it should throw ServiceUnavailableException

  Scenario: RolesGuard requires authentication before evaluating role permissions
    Test Case ID: UT-SHRD-014
    Given an unauthenticated request without session
    When RolesGuard checks access on a restricted route
    Then it should throw UnauthorizedException
