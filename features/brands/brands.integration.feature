@backend @integration @brands
Feature: Global brand HTTP contracts and logo uploads

  @IT-BRND-001
  Scenario: Updates the brand image with multipart form data
    Given a superadmin and valid multipart fields
    When a replacement logo is uploaded
    Then save its object key with the supplied brand fields

  @IT-BRND-002
  Scenario: Updates only the image without requiring name or code
    Given a superadmin and an image-only payload
    When the brand is updated
    Then save the logo without requiring name or code

  @IT-BRND-003
  Scenario: Keeps multipart updates without an image working
    Given a superadmin and multipart fields without a file
    When the brand is updated
    Then forward fields without uploading an image

  @IT-BRND-004
  Scenario: Rejects malformed update fields before uploading the image
    Given an oversized brand code and image
    When the brand is updated
    Then return 400 before uploading or saving

  @IT-BRND-005
  Scenario: Checks the target brand before uploading its replacement image
    Given a missing brand
    When a replacement logo is uploaded
    Then return 404 without storing the image

  @IT-BRND-006
  Scenario: Rejects invalid image bytes without changing the brand
    Given invalid PNG bytes
    When a replacement logo is uploaded
    Then return 415 without updating the brand

  @IT-BRND-007
  Scenario: Rejects oversized update images
    Given an oversized image
    When a replacement logo is uploaded
    Then return 413 without updating the brand

  @IT-BRND-008
  Scenario: Rejects multiple update images
    Given multiple image files
    When a replacement logo is uploaded
    Then return 400 without updating the brand

  @IT-BRND-009
  Scenario: Keeps the brand unchanged when image storage fails
    Given unavailable storage
    When a replacement logo is uploaded
    Then return 503 without updating the brand

  @IT-BRND-010
  Scenario: Blocks managers before uploading replacement images
    Given a manager session
    When a replacement logo is uploaded
    Then return 403 before storage or update

  @IT-BRND-011
  Scenario: Lists brands with pagination: the supplied value
    Given pagination query the supplied value
    When brands are listed
    Then forward the global pagination filters

  @IT-BRND-012
  Scenario: Delegates the supplied value for the superadmin
    Given a superadmin session
    When the supplied value targets a brand
    Then delegate to the service

  @IT-BRND-013
  Scenario: Validates and forwards brand updates
    Given a valid JSON update
    When a superadmin updates a brand
    Then forward all supplied fields without an upload

  @IT-BRND-014
  Scenario: Documents optional multipart images while retaining JSON updates
    Given the generated OpenAPI document
    When the brand update operation is inspected
    Then document JSON multipart and upload error responses

  @IT-BRND-015
  Scenario: Allows the supplied value to read any brand
    Given employee role the supplied value without brand assignments
    When another fixture brand is read
    Then return 200 and query that brand

  @IT-BRND-016
  Scenario: Allows superadmins to access another brand: the supplied value
    Given a superadmin session
    When the supplied value targets another brand
    Then return 200

  @IT-BRND-017
  Scenario: Keeps the write method superadmin-only for the staff role
    Given staff role the staff role
    When the write method modifies a brand
    Then return 403 without calling the service

  @IT-BRND-018
  Scenario: Creates a brand for the authenticated superadmin: the supplied value
    Given a superadmin and payload the supplied value
    When a brand is created with an image
    Then save the supplied code and uploaded logo key

  @IT-BRND-019
  Scenario: Rejects invalid creation bodies: the supplied value
    Given invalid creation payload the supplied value
    When brand creation is requested
    Then return 400 without creating a brand

  @IT-BRND-020
  Scenario: Creates a brand without requiring a user assignment
    Given a superadmin without brand assignments
    When a valid brand is created
    Then return 201 without assigning employees

  @IT-BRND-021
  Scenario: Allows the supplied value to list all brands
    Given employee role the supplied value
    When the global brand listing is requested
    Then return 200

  @IT-BRND-022
  Scenario: Rejects brand creation for the supplied value
    Given staff role the supplied value
    When brand creation is requested
    Then return 403 without creating a brand

  @IT-BRND-023
  Scenario: Rejects invalid update bodies: the supplied value
    Given invalid update payload the supplied value
    When a brand update is requested
    Then return 400 without saving

  @IT-BRND-024
  Scenario: Rejects malformed brand IDs: the supplied value
    Given a malformed brand UUID
    When the supplied value targets that path
    Then return 400 without calling the service

  @IT-BRND-025
  Scenario: Rejects invalid list filters: the supplied value
    Given invalid list query the supplied value
    When brands are listed
    Then return 400 before querying

  @IT-BRND-026
  Scenario: Removes assignment routes: the supplied value the supplied value
    Given the removed assignment API
    When the supplied value requests path the supplied value
    Then return 404 without calling the brand service

  @IT-BRND-030
  Scenario: Brand deactivation preserves employees and sessions
    Given active employees with real database sessions
    When a superadmin deactivates a fixture brand
    Then employees remain active and their sessions remain valid
