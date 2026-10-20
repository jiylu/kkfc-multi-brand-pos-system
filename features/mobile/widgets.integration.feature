Feature: Mobile UI Component and Layout Integration
  Feature ID: FEAT-MOB-UI
  Requirement ID: FR-MOB-003

  As a mobile application user,
  I want UI screens and scaffolds to render responsively across font scales and insets,
  So that POS interfaces are accessible and visually consistent.

  Scenario: Login screen lays out at 2.5x text scale without overflow
    Test Case ID: IT-MOB-WIDG-001
    Given an accessibility text scale factor of 2.5 linear
    When the LoginScreen is pumped and settled into the test harness
    Then no Flutter layout overflow exceptions should occur
    And the "Sign in" button should be rendered and visible

  Scenario: Scaffold body clears top system insets without app bar
    Test Case ID: IT-MOB-WIDG-002
    Given a mobile viewport with a 40px top system inset padding
    When KkfcScaffold is rendered with a body widget and no app bar
    Then the top-left y-position of the body should be greater than or equal to 40px

  Scenario: Unauthenticated users start on the login screen
    Test Case ID: IT-MOB-WIDG-003
    Given a fresh app launch without a saved session token
    When the App root widget is pumped and settled
    Then the application router should present the LoginScreen
