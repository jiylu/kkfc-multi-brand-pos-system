@backend @integration @assets
Feature: Additional assets integration coverage
  Feature ID: FEAT-ASSET-IT-ADDITIONAL
  Requirement ID: FR-ASSET-001

  As a backend maintainer,
  I want the assets behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-002
  Scenario: Forwards the function toggle and reports no expiry for public URLs
    Test Case ID: IT-ASSET-002
    Given download URL expiry is disabled for the assets service
    When upload and download operations request public URLs
    Then the storage toggle is forwarded and responses report no expiry

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-003
  Scenario: Normalize supported images and store them under the owner's prefix
    Test Case ID: IT-ASSET-003
    Given an authenticated owner uploads a supported real image
    When the upload endpoint accepts the file
    Then normalized image bytes are stored under the owner's prefix with dimensions and expiry metadata

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-004
  Scenario: Require a valid session for asset uploads
    Test Case ID: IT-ASSET-004
    Given a missing, malformed, or invalid bearer session
    When an image upload is requested
    Then the response is 401 without uploading

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-005
  Scenario: Requires a file
    Test Case ID: IT-ASSET-005
    Given an authenticated upload request without a file
    When the upload endpoint is called
    Then the response is 400

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-006
  Scenario: Reject disallowed and disguised image files
    Test Case ID: IT-ASSET-006
    Given a disallowed file type or disguised extension and MIME combination
    When the file is uploaded
    Then the request is rejected with 400 or 415 before storing it

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-007
  Scenario: Rejects an oversized upload before storage
    Test Case ID: IT-ASSET-007
    Given an image exceeds the upload byte limit
    When the file is uploaded
    Then the response is 413 before storage

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-008
  Scenario: Rejects multiple files
    Test Case ID: IT-ASSET-008
    Given an upload request contains multiple files
    When the upload endpoint is called
    Then the response is 400

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-009
  Scenario: Rejects a truncated JPG even when its extension and MIME type are correct
    Test Case ID: IT-ASSET-009
    Given a truncated JPG with matching extension and MIME type
    When the file is uploaded
    Then the decoder rejects it with 415

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-010
  Scenario: Rejects images above the pixel limit even if compressed bytes are small
    Test Case ID: IT-ASSET-010
    Given an image exceeds the pixel limit despite small compressed bytes
    When the image is uploaded
    Then the response is 415

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-011
  Scenario: Returns a sanitized error when S3 rejects an upload
    Test Case ID: IT-ASSET-011
    Given S3 rejects an image upload
    When the upload endpoint handles the error
    Then the response is a sanitized 503 without leaking storage details

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-012
  Scenario: Refreshes a download URL for the owner
    Test Case ID: IT-ASSET-012
    Given an authenticated owner requests their existing object
    When a refreshed download URL is requested
    Then object existence is checked and a no-store response contains the refreshed URL

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-013
  Scenario: Hide objects outside the authenticated owner's scope
    Test Case ID: IT-ASSET-013
    Given an object key is outside the authenticated user's allowed scope
    When a download URL is requested
    Then the response is 404

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-014
  Scenario: Requires a download key
    Test Case ID: IT-ASSET-014
    Given no object key is supplied
    When a download URL is requested
    Then the response is 400

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-015
  Scenario: Returns 404 for missing objects
    Test Case ID: IT-ASSET-015
    Given the requested object does not exist
    When its owner requests a download URL
    Then the response is 404

  # Jest: server/src/modules/assets/assets.http.spec.ts
  # Context: Assets HTTP
  @IT-ASSET-016
  Scenario: Does not write an object when signing fails
    Test Case ID: IT-ASSET-016
    Given download signing fails during upload preparation
    When the image upload is processed
    Then the response is 503 and no object is written
