class RegisterRequestModel {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;
  final String currentCompany;
  final String role;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.currentCompany,
    this.role = 'MENTOR', // Default role for mentor app
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'currentCompany': currentCompany,
      'role': role,
    };
  }
}
