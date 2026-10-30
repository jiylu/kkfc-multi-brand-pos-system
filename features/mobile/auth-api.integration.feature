@mobile @integration @real_api @auth
Feature: Sign in through the real authentication API

  @IT-MOB-AUTH-001
  Scenario: Successful staff login
    Given the app is signed out with no saved session token
    And the test API has a seeded staff account
    When the staff member submits their valid username and password
    Then the app opens the menu screen
    And the session token is saved in secure storage
    And the real API accepts that token at the authenticated profile endpoint

  @IT-MOB-AUTH-002
  Scenario: Reject an incorrect password
    Given the app is signed out with no saved session token
    And the test API has a seeded staff account
    When the staff member submits their username with an incorrect password
    Then the app displays the invalid credentials message
    And the app stays on the login screen
    And no session token is held or saved
    And the sign in button stops loading
