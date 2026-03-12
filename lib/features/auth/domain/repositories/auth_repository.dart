import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/jwt_response_model.dart';

abstract class AuthRepository {
  Future<JwtResponseModel> login(LoginRequestModel request);
  Future<void> register(RegisterRequestModel request);
  Future<void> logout();
  Future<JwtResponseModel> refreshToken(String refreshToken);

  // LinkedIn OAuth methods
  String getLinkedInAuthUrl();
  Future<JwtResponseModel> authenticateWithLinkedIn(Uri callbackUri);

  // Google OAuth methods
  String getGoogleAuthUrl();
  Future<JwtResponseModel> authenticateWithGoogle(Uri callbackUri);
}
