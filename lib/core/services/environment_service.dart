import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum Environment {
  development,
  production,
}

class EnvironmentService {
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();

  static const String _environmentKey = 'app_environment';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Default URLs
  static const String developmentUrl = 'http://192.168.31.251:8080';
  static const String productionUrl = 'https://brightwin-server.bright-way.ac';

  Environment _currentEnvironment = Environment.production;

  /// Get current environment
  Environment get currentEnvironment => _currentEnvironment;

  /// Get current base URL based on environment
  String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return developmentUrl;
      case Environment.production:
        return productionUrl;
    }
  }

  /// Initialize environment from storage
  Future<void> initialize() async {
    try {
      final savedEnv = await _storage.read(key: _environmentKey);
      if (savedEnv != null) {
        _currentEnvironment = savedEnv == 'production'
            ? Environment.production
            : Environment.development;
      } else {
        // First time - set to production and save it
        _currentEnvironment = Environment.production;
        await _storage.write(key: _environmentKey, value: 'production');
      }
    } catch (e) {
      // If reading fails, use default (production)
      _currentEnvironment = Environment.production;
    }
  }

  /// Switch to development environment
  Future<void> switchToDevelopment() async {
    _currentEnvironment = Environment.development;
    await _storage.write(key: _environmentKey, value: 'development');
  }

  /// Switch to production environment
  Future<void> switchToProduction() async {
    _currentEnvironment = Environment.production;
    await _storage.write(key: _environmentKey, value: 'production');
  }

  /// Toggle between environments
  Future<void> toggleEnvironment() async {
    if (_currentEnvironment == Environment.development) {
      await switchToProduction();
    } else {
      await switchToDevelopment();
    }
  }

  /// Get environment name for display
  String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  /// Check if in production
  bool get isProduction => _currentEnvironment == Environment.production;

  /// Check if in development
  bool get isDevelopment => _currentEnvironment == Environment.development;
}
