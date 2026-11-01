@backend @unit @shared
Feature: Additional shared unit coverage
  Feature ID: FEAT-SHRD-UT-ADDITIONAL
  Requirement ID: FR-SHRD-001

  As a backend maintainer,
  I want the shared behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-015
  Scenario: Returns a stable encoded CloudFront URL without signing credentials when expiry is disabled
    Test Case ID: UT-SHRD-015
    Given a configured HTTPS CloudFront origin and download expiry disabled
    When a download URL is created for an object containing reserved characters
    Then a stable encoded URL is returned without requiring signing credentials

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-016
  Scenario: Requires a CloudFront base URL when expiry is disabled
    Test Case ID: UT-SHRD-016
    Given download expiry is disabled but no CloudFront origin is configured
    When a download URL is requested
    Then a service-unavailable error is returned without signing

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-017
  Scenario: Reject invalid origins for stable public download URLs
    Test Case ID: UT-SHRD-017
    Given an insecure or path-containing CloudFront origin
    When a non-expiring download URL is requested
    Then the invalid origin is rejected

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-018
  Scenario: Reject unsafe object keys for stable public URLs
    Test Case ID: UT-SHRD-018
    Given a wildcard or traversal object key
    When a non-expiring public URL is requested
    Then the invalid key is rejected

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-019
  Scenario: Keeps upload URLs signed for five minutes when download expiry is disabled
    Test Case ID: UT-SHRD-019
    Given public download URLs use non-expiring mode
    When an upload URL is requested
    Then the S3 upload URL remains signed for five minutes

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-020
  Scenario: Sign encoded CloudFront downloads for five minutes across clock offsets
    Test Case ID: UT-SHRD-020
    Given a configured CloudFront key pair and the current clock offset
    When a download URL is signed
    Then the encoded object URL has a five-minute expiry and a verifiable signature

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-021
  Scenario: Reject invalid CloudFront configuration without S3 fallback
    Test Case ID: UT-SHRD-021
    Given CloudFront signing configuration is invalid
    When a signed download URL is requested
    Then configuration failure is returned without falling back to S3 signing

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-022
  Scenario: Reject wildcard and traversal keys before signing
    Test Case ID: UT-SHRD-022
    Given a wildcard or traversal key
    When a signed download URL is requested
    Then the key is rejected

  # Jest: server/src/shared/storage/storage.service.spec.ts
  # Context: StorageService (UT-SHRD)
  @UT-SHRD-023
  Scenario: Continues uploading directly to S3 when CloudFront is configured
    Test Case ID: UT-SHRD-023
    Given CloudFront is configured for downloads
    When an object is uploaded
    Then the bytes are still uploaded directly to S3
