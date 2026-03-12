import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/environment_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/jwt_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;
  final EnvironmentService _environmentService;

  AuthRepositoryImpl(
    this._dioClient,
    this._storage,
    this._environmentService,
  );

  @override
  Future<JwtResponseModel> login(LoginRequestModel request) async {
    try {
      print('========================================');
      print('🔐 LOGIN ATTEMPT');
      print('Email: ${request.email}');
      print('Endpoint: /api/auth/login');
      print('========================================');

      // Clear any existing tokens before login attempt to prevent auto-authentication
      print('🧹 Clearing existing tokens before login');
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);

      final response = await _dioClient.dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      print('📦 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      final jwtResponse = JwtResponseModel.fromJson(response.data);

      // Store tokens in secure storage
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: jwtResponse.token,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: jwtResponse.refreshToken,
      );

      print('========================================');
      print('✅ LOGIN SUCCESSFUL');
      print('User: ${jwtResponse.firstName} ${jwtResponse.lastName}');
      print('Role: ${jwtResponse.role}');
      print('Token stored in secure storage');
      print('========================================');

      return jwtResponse;
    } catch (e) {
      print('========================================');
      print('❌ LOGIN FAILED');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('========================================');
      rethrow;
    }
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    try {
      print('========================================');
      print('📝 REGISTRATION ATTEMPT');
      print('Email: ${request.email}');
      print('Endpoint: /api/auth/register');
      print('========================================');

      final response = await _dioClient.dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );

      print('📦 Response status: ${response.statusCode}');
      print('✅ REGISTRATION SUCCESSFUL');
      print('========================================');
    } catch (e) {
      print('========================================');
      print('❌ REGISTRATION FAILED');
      print('Error: $e');
      print('========================================');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userDataKey);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<JwtResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/refresh',
        queryParameters: {'refreshToken': refreshToken},
      );

      final jwtResponse = JwtResponseModel.fromJson(response.data);

      // Update stored token
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: jwtResponse.token,
      );

      return jwtResponse;
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getLinkedInAuthUrl() {
    final baseUrl = _environmentService.baseUrl;
    // Spring OAuth2 authorization endpoint for LinkedIn with MENTOR role
    final authUrl = '$baseUrl/oauth2/authorization/linkedin?role=MENTOR';

    print('========================================');
    print('🔗 LINKEDIN AUTH URL GENERATED');
    print('URL: $authUrl');
    print('Role: MENTOR');
    print('Environment: ${_environmentService.environmentName}');
    print('========================================');

    return authUrl;
  }

  @override
  Future<JwtResponseModel> authenticateWithLinkedIn(Uri callbackUri) async {
    try {
      print('========================================');
      print('🔐 LINKEDIN OAUTH CALLBACK');
      print('Callback URI: $callbackUri');
      print('========================================');

      // Extract query parameters from deep link
      final queryParams = callbackUri.queryParameters;

      // Check for error
      if (queryParams.containsKey('error')) {
        final error = queryParams['error'];
        print('❌ OAuth Error: $error');
        throw Exception('LinkedIn authentication failed: $error');
      }

      // Extract tokens from query parameters
      final token = queryParams['token'];
      final refreshToken = queryParams['refreshToken'];
      final email = queryParams['email'];
      final firstName = queryParams['firstName'];
      final lastName = queryParams['lastName'];
      final role = queryParams['role'];

      if (token == null || refreshToken == null) {
        print('❌ Missing tokens in callback');
        throw Exception('Authentication failed: Missing tokens');
      }

      print('📦 Tokens received from OAuth callback');
      print('Email: $email');
      print('Name: $firstName $lastName');
      print('Role: $role');

      // Create JWT response model
      final jwtResponse = JwtResponseModel(
        token: token,
        refreshToken: refreshToken,
        type: 'Bearer',
        id: 0, // ID will be extracted from JWT token on backend
        email: email ?? '',
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        role: role ?? 'JOB_SEEKER',
      );

      // Store tokens in secure storage
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: jwtResponse.token,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: jwtResponse.refreshToken,
      );

      print('========================================');
      print('✅ LINKEDIN LOGIN SUCCESSFUL');
      print('User: ${jwtResponse.firstName} ${jwtResponse.lastName}');
      print('Role: ${jwtResponse.role}');
      print('Token stored in secure storage');
      print('========================================');

      return jwtResponse;
    } catch (e) {
      print('========================================');
      print('❌ LINKEDIN AUTHENTICATION FAILED');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('========================================');
      rethrow;
    }
  }

  @override
  String getGoogleAuthUrl() {
    final baseUrl = _environmentService.baseUrl;
    // Spring OAuth2 authorization endpoint for Google with MENTOR role
    final authUrl = '$baseUrl/oauth2/authorization/google?role=MENTOR';

    print('========================================');
    print('🔗 GOOGLE AUTH URL GENERATED');
    print('URL: $authUrl');
    print('Role: MENTOR');
    print('Environment: ${_environmentService.environmentName}');
    print('========================================');

    return authUrl;
  }

  @override
  Future<JwtResponseModel> authenticateWithGoogle(Uri callbackUri) async {
    try {
      print('========================================');
      print('🔐 GOOGLE OAUTH CALLBACK');
      print('Callback URI: $callbackUri');
      print('========================================');

      // Extract query parameters from deep link
      final queryParams = callbackUri.queryParameters;

      // Check for error
      if (queryParams.containsKey('error')) {
        final error = queryParams['error'];
        print('❌ OAuth Error: $error');
        throw Exception('Google authentication failed: $error');
      }

      // Extract tokens from query parameters
      final token = queryParams['token'];
      final refreshToken = queryParams['refreshToken'];
      final email = queryParams['email'];
      final firstName = queryParams['firstName'];
      final lastName = queryParams['lastName'];
      final role = queryParams['role'];

      // Extract user creation status
      // Check multiple possible parameter names for flexibility
      final isNewUserStr = queryParams['isNewUser'] ??
                           queryParams['userCreated'] ??
                           queryParams['newUser'] ??
                           queryParams['created'];
      final isNewUser = isNewUserStr != null
          ? (isNewUserStr.toLowerCase() == 'true')
          : null;

      if (token == null || refreshToken == null) {
        print('❌ Missing tokens in callback');
        throw Exception('Authentication failed: Missing tokens');
      }

      print('📦 Tokens received from OAuth callback');
      print('Email: $email');
      print('Name: $firstName $lastName');
      print('Role: $role');
      print('Is New User: $isNewUser');

      // Create JWT response model
      final jwtResponse = JwtResponseModel(
        token: token,
        refreshToken: refreshToken,
        type: 'Bearer',
        id: 0, // ID will be extracted from JWT token on backend
        email: email ?? '',
        firstName: firstName ?? '',
        lastName: lastName ?? '',
        role: role ?? 'MENTOR',
        isNewUser: isNewUser,
      );

      // Store tokens in secure storage
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: jwtResponse.token,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: jwtResponse.refreshToken,
      );

      print('========================================');
      print('✅ GOOGLE LOGIN SUCCESSFUL');
      print('User: ${jwtResponse.firstName} ${jwtResponse.lastName}');
      print('Role: ${jwtResponse.role}');
      print('Token stored in secure storage');
      print('========================================');

      return jwtResponse;
    } catch (e) {
      print('========================================');
      print('❌ GOOGLE AUTHENTICATION FAILED');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('========================================');
      rethrow;
    }
  }
}
