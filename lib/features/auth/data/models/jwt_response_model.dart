class JwtResponseModel {
  final String token;
  final String refreshToken;
  final String type;
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool? isNewUser; // Indicates if user was just created (true) or already existed (false)

  JwtResponseModel({
    required this.token,
    required this.refreshToken,
    required this.type,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.isNewUser,
  });

  factory JwtResponseModel.fromJson(Map<String, dynamic> json) {
    return JwtResponseModel(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      type: json['type'] as String,
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      isNewUser: json['isNewUser'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'type': type,
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        if (isNewUser != null) 'isNewUser': isNewUser,
      };
}
