class OTPVerificationRequest {
  final String sessionId;
  final String email;
  final String otpCode;

  OTPVerificationRequest({
    required this.sessionId,
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'email': email,
      'otpCode': otpCode,
    };
  }
}
