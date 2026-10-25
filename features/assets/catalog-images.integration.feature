@backend @integration @postgresql @assets
Feature: Persist catalog image associations

  @IT-ASSET-001
  Scenario Outline: Store image keys and resolve reads according to the resource contract
    Given an authenticated superadmin and a valid PNG
    When the image is attached to a <resource>
    Then the update returns 200
    And PostgreSQL stores the generated owner-scoped object key
    And storage receives decoded and re-encoded PNG bytes
    When the resource is read again
    Then its image field contains <readValue>
    Examples:
      | resource  | readValue                           |
      | brand     | a download URL for the stored key    |
      | menu item | the stored object key               |
