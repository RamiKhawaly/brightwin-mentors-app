class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['token'] as String? ?? json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: (json['id'] ?? json['userId']).toString(),
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };
}
