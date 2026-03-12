import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../services/navigation_service.dart';
import '../services/environment_service.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();
  bool _isRefreshing = false;
  final EnvironmentService _environmentService = EnvironmentService();

  DioClient(this._storage) {
    // Use the singleton instance to get the base URL
    final baseUrl = _environmentService.baseUrl;

    print('🌐 DioClient initialized with base URL: $baseUrl');
    print('🌍 Current environment: ${_environmentService.environmentName}');

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _loggingInterceptor(),
      _authInterceptor(),
      _errorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('========================================');
        print('📤 HTTP REQUEST');
        print('Method: ${options.method}');
        print('Full URL: ${options.baseUrl}${options.path}');
        print('Path: ${options.path}');
        print('Query Parameters: ${options.queryParameters}');
        print('Headers: ${options.headers}');
        print('Request Body: ${options.data}');
        print('========================================');
        _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
        _logger.d('Query Parameters: ${options.queryParameters}');
        _logger.d('Headers: ${options.headers}');
        _logger.d('Body: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('========================================');
        print('📥 HTTP RESPONSE');
        print('Status Code: ${response.statusCode}');
        print('Status Message: ${response.statusMessage}');
        print('Path: ${response.requestOptions.path}');
        print('Response Data: ${response.data}');
        print('========================================');
        _logger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        _logger.d('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('========================================');
        print('❌ HTTP ERROR');
        print('Status Code: ${error.response?.statusCode}');
        print('Method: ${error.requestOptions.method}');
        print('Path: ${error.requestOptions.path}');
        print('Full URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
        print('Query Parameters: ${error.requestOptions.queryParameters}');
        print('Request Body: ${error.requestOptions.data}');
        print('Error Type: ${error.type}');
        print('Message: ${error.message}');
        print('Response Data: ${error.response?.data}');
        print('========================================');
        _logger.e('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        _logger.e('Query Parameters: ${error.requestOptions.queryParameters}');
        _logger.e('Request Body: ${error.requestOptions.data}');
        _logger.e('Message: ${error.message}');
        return handler.next(error);
      },
    );
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Don't try to refresh if this IS the refresh request (prevents infinite loop)
        final isRefreshRequest = error.requestOptions.path.contains('/auth/refresh');

        // Check if this request was already retried after token refresh
        final isRetryAttempt = error.requestOptions.extra['retry_after_refresh'] == true;

        if (error.response?.statusCode == 401 && !isRefreshRequest && !_isRefreshing && !isRetryAttempt) {
          _isRefreshing = true;
          print('🔄 Got 401 error, attempting to refresh token...');
          // Token expired, try to refresh
          try {
            final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              // Attempt to refresh the token
              final response = await _dio.post(
                '/api/auth/refresh',
                queryParameters: {'refreshToken': refreshToken},
              );

              if (response.statusCode == 200) {
                final newAccessToken = response.data['token'];
                await _storage.write(
                  key: AppConstants.accessTokenKey,
                  value: newAccessToken,
                );

                print('✅ Token refreshed successfully, retrying original request');
                _isRefreshing = false;

                // Mark this request as a retry to prevent infinite loops
                error.requestOptions.extra['retry_after_refresh'] = true;
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                // Retry the original request
                return handler.resolve(await _dio.fetch(error.requestOptions));
              } else {
                print('❌ Token refresh returned non-200 status, clearing tokens');
                // Only clear tokens if refresh endpoint itself fails
                await _storage.delete(key: AppConstants.accessTokenKey);
                await _storage.delete(key: AppConstants.refreshTokenKey);
                await _storage.delete(key: AppConstants.userDataKey);
                _isRefreshing = false;

                // Navigate to login
                NavigationService().showSnackBar(
                  'Session expired. Please login again.',
                  backgroundColor: Colors.orange,
                );
                NavigationService().navigateToLogin();

                return handler.reject(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: error.type,
                    error: 'Session expired. Please login again.',
                  ),
                );
              }
            } else {
              print('❌ No refresh token found, clearing all tokens');
              // Clear stored tokens when no refresh token is available
              await _storage.delete(key: AppConstants.accessTokenKey);
              await _storage.delete(key: AppConstants.refreshTokenKey);
              await _storage.delete(key: AppConstants.userDataKey);
              _isRefreshing = false;

              // Navigate to login
              NavigationService().showSnackBar(
                'Session expired. Please login again.',
                backgroundColor: Colors.orange,
              );
              NavigationService().navigateToLogin();

              // Modify error to be more user-friendly
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: 'Session expired. Please login again.',
                ),
              );
            }
          } catch (e) {
            print('❌ Token refresh failed with exception: $e');
            _logger.e('Token refresh failed: $e');
            // Only clear tokens if refresh itself failed (not if retry failed)
            if (e.toString().contains('401') || e.toString().contains('403')) {
              print('🔑 Refresh token is invalid, clearing all tokens');
              await _storage.delete(key: AppConstants.accessTokenKey);
              await _storage.delete(key: AppConstants.refreshTokenKey);
              await _storage.delete(key: AppConstants.userDataKey);

              _isRefreshing = false;

              // Navigate to login
              NavigationService().showSnackBar(
                'Session expired. Please login again.',
                backgroundColor: Colors.orange,
              );
              NavigationService().navigateToLogin();

              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: error.type,
                  error: 'Session expired. Please login again.',
                ),
              );
            } else {
              // Other error during refresh, don't clear tokens
              print('⚠️ Refresh attempt failed but tokens may still be valid');
              _isRefreshing = false;
            }
          }
        } else if (isRetryAttempt && error.response?.statusCode == 401) {
          // Retry after token refresh also failed with 401
          // This means the 401 is NOT about token expiration, it's an authorization issue
          print('⚠️ Retry after token refresh also failed with 401 - this is an authorization issue, NOT token expiration');
          print('💡 Not clearing tokens - user is authenticated but not authorized for this action');
        }
        return handler.next(error);
      },
    );
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        String errorMessage;

        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Connection timeout. Please try again.';
            break;
          case DioExceptionType.badResponse:
            errorMessage = _handleStatusCode(error.response?.statusCode);
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Request cancelled';
            break;
          default:
            errorMessage = 'Network error. Please check your connection.';
        }

        error = error.copyWith(
          message: errorMessage,
        );

        return handler.next(error);
      },
    );
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
