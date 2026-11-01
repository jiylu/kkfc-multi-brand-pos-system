@backend @e2e @robot @kitchen
Feature: Kitchen ticket assignments through real sessions
  Background:
    Given an isolated catalog fixture and a newly confirmed order with a queued ticket

  @E2E-KT-001
  Scenario: Kitchen staff and head assign a confirmed order ticket
    Given kitchen staff claim the ticket as preparer
    When the kitchen head assigns the checker
    Then the saved ticket contains both assignments
    And the ticket appears in today's and assignee listings

  @E2E-KT-002
  Scenario: Existing preparer cannot be replaced
    Given kitchen staff claim the ticket as preparer
    When the kitchen head attempts to replace the preparer
    Then the original preparer is preserved

  @E2E-KT-003
  Scenario: Kitchen staff cannot assign a checker
    Given the checker remains unassigned
    When kitchen staff attempt to assign a checker
    Then the checker remains unassigned

  @E2E-KT-004
  Scenario: Cashier cannot read or claim kitchen tickets
    Given the preparer remains unassigned
    When the cashier attempts to read and claim the kitchen ticket
    Then the preparer remains unassigned
