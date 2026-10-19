enum LoginStatus {
  idle,
  submitting,
  missingFields,
  invalidCredentials,
  networkError,
}

extension LoginStatusX on LoginStatus {
  bool get isSubmitting => this == LoginStatus.submitting;

  bool get hasNotice =>
      this == LoginStatus.missingFields ||
      this == LoginStatus.invalidCredentials ||
      this == LoginStatus.networkError;

  /// Network problems shouldn't turn the inputs red.
  bool get fieldsInError =>
      this == LoginStatus.missingFields ||
      this == LoginStatus.invalidCredentials;

  String get noticeTitle => switch (this) {
        LoginStatus.missingFields => 'Required fields',
        LoginStatus.invalidCredentials => 'Not signed in',
        LoginStatus.networkError => 'Unable to connect',
        _ => '',
      };

  String get noticeMessage => switch (this) {
        LoginStatus.missingFields => 'Enter both your username and password.',
        LoginStatus.invalidCredentials =>
          'Username or password is wrong. Check both and try again.',
        LoginStatus.networkError =>
          'Connection problem. Check your network and retry.',
        _ => '',
      };
}