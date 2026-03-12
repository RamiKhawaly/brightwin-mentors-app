class AppConstants {
  // API Configuration
  // For physical device: Use computer's IP address
  // For Android Emulator: Use 10.0.2.2 (maps to localhost on host machine)
  static const String baseUrl = 'http://192.168.31.251:8080';
  static const String apiDocs = '$baseUrl/api-docs';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // App Configuration
  // Increased timeout for LLM-based endpoints (e.g., job import from URL)
  static const int connectionTimeout = 60000; // 60 seconds
  static const int receiveTimeout = 120000;   // 120 seconds (2 minutes) for LLM responses

  // Subscription Pricing (in NIS)
  static const int mentorMonthlyPrice = 100;
  static const int freeTrialDays = 7;

  // Mentor Rewards (in NIS)
  static const int interviewSimulationReward = 100; // Full free month
  static const int interviewFeedbackReward = 100; // Full free month
  static const int phoneCallReward = 10;
  static const int chatHelpReward = 5;

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
}
