import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_links/app_links.dart';
import 'core/config/injection_container.dart';
import 'core/config/router_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'core/services/environment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase and FCM
  try {
    await FCMService().initialize();
    print('✅ FCM Service initialized in main');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('⚠️ Error initializing FCM in main: $e');
    // Continue app execution even if FCM fails
  }

  // Setup dependency injection
  await setupLocator();

  runApp(const BrightwinMentorsApp());
}

class BrightwinMentorsApp extends StatefulWidget {
  const BrightwinMentorsApp({super.key});

  @override
  State<BrightwinMentorsApp> createState() => _BrightwinMentorsAppState();
}

class _BrightwinMentorsAppState extends State<BrightwinMentorsApp> {
  late AppLinks _appLinks;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _setupFCMMessageHandlers();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial deep link if app was launched from a link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Listen to deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('❌ Error handling deep link: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    print('========================================');
    print('🔗 Deep Link Received');
    print('URL: $uri');
    print('Scheme: ${uri.scheme}');
    print('Host: ${uri.host}');
    print('Path: ${uri.path}');
    print('Query Parameters: ${uri.queryParameters}');
    print('========================================');

    // Check if this is an app navigation deep link (e.g. from email)
    if (uri.scheme == 'brightwin' && uri.host == 'app') {
      final path = uri.path;
      if (path == '/sign-in' || path.isEmpty || path == '/') {
        AppRouterConfig.router.go(AppRoutes.signIn);
      } else {
        // Try to navigate directly to the path
        AppRouterConfig.router.go(path);
      }
      return;
    }

    // Check if this is an OAuth2 callback
    if (uri.scheme == 'brightwin' && uri.host == 'oauth2' && uri.path == '/redirect') {
      // Check if there's an error
      if (uri.queryParameters.containsKey('error')) {
        final error = uri.queryParameters['error'] ?? 'Authentication failed';
        print('❌ OAuth Error: $error');

        // Navigate back to sign-in
        AppRouterConfig.router.go(AppRoutes.signIn);

        // Show error message to user
        Future.delayed(const Duration(milliseconds: 300), () {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        });
      } else {
        await _handleOAuth2Callback(uri);
      }
    }
  }

  Future<void> _handleOAuth2Callback(Uri uri) async {
    try {
      final storage = const FlutterSecureStorage();
      final dioClient = DioClient(storage);
      final environmentService = EnvironmentService();
      await environmentService.initialize();

      final authRepository = AuthRepositoryImpl(dioClient, storage, environmentService);

      // Check for error
      if (uri.queryParameters.containsKey('error')) {
        final error = uri.queryParameters['error'];
        print('❌ OAuth Error: $error');
        // Navigate back to sign-in
        AppRouterConfig.router.go(AppRoutes.signIn);
        return;
      }

      // Authenticate with Google
      final jwtResponse = await authRepository.authenticateWithGoogle(uri);

      print('✅ OAuth authentication successful');
      print('User: ${jwtResponse.firstName} ${jwtResponse.lastName}');
      print('Is New User: ${jwtResponse.isNewUser}');

      // Register FCM token
      try {
        print('📱 Registering FCM token with backend...');
        final registered = await FCMService().registerTokenWithBackend(dioClient);
        if (registered) {
          print('✅ FCM token registered successfully');
        }
      } catch (e) {
        print('⚠️ Error registering FCM token: $e');
      }

      // Google users are always kept logged in until token expires
      await storage.write(key: 'keep_logged_in', value: 'true');

      // Route based on backend's indication of user creation status
      if (jwtResponse.isNewUser == true) {
        // New user - redirect to onboarding
        print('→ New user detected (backend confirmed), redirecting to onboarding');
        AppRouterConfig.router.go(AppRoutes.mentorOnboarding);
      } else if (jwtResponse.isNewUser == false) {
        // Existing user - mark onboarding as completed and redirect to home
        print('→ Existing user detected (backend confirmed), redirecting to home');
        await storage.write(key: 'onboarding_completed', value: 'true');
        AppRouterConfig.router.go(AppRoutes.home);
      } else {
        // Fallback: Backend didn't send isNewUser parameter
        // Use profile completeness as before
        print('⚠️ Backend did not indicate user status, checking profile completeness...');
        try {
          final profileResponse = await dioClient.dio.get('/api/profile');
          final profileCompleteness = profileResponse.data['profileCompleteness'] as int? ?? 0;

          print('Profile completeness: $profileCompleteness%');

          if (profileCompleteness < 30) {
            print('→ New user detected (by profile completeness), redirecting to onboarding');
            AppRouterConfig.router.go(AppRoutes.mentorOnboarding);
          } else {
            print('→ Existing user detected (by profile completeness), redirecting to home');
            await storage.write(key: 'onboarding_completed', value: 'true');
            AppRouterConfig.router.go(AppRoutes.home);
          }
        } catch (e) {
          print('⚠️ Error fetching profile: $e');
          // Default to home if profile fetch fails
          AppRouterConfig.router.go(AppRoutes.home);
        }
      }
    } catch (e) {
      print('❌ Error handling OAuth2 callback: $e');
      // Navigate back to sign-in on error
      AppRouterConfig.router.go(AppRoutes.signIn);
    }
  }

  void _setupFCMMessageHandlers() {
    FCMService().setupMessageHandlers(
      onForegroundMessage: (message) {
        print('📩 Foreground message received: ${message.notification?.title}');
        // Message is automatically shown as notification by FCMService
      },
      onMessageOpened: (message) {
        print('📬 Message opened: ${message.notification?.title}');
        _handleNotificationNavigation(message);
      },
    );
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    // Handle navigation based on notification data
    final data = message.data;
    print('🔔 Handling notification navigation with data: $data');

    // Navigate based on notification type
    if (data.containsKey('sessionId')) {
      // Navigate to session details
      final sessionId = data['sessionId'];
      print('→ Navigating to session: $sessionId');
      AppRouterConfig.router.push('/sessions/$sessionId');
    } else if (data.containsKey('jobId')) {
      // Navigate to job details
      final jobId = data['jobId'];
      print('→ Navigating to job: $jobId');
      AppRouterConfig.router.push('/jobs/$jobId');
    } else if (data.containsKey('actionUrl')) {
      // Navigate to custom URL from backend
      final actionUrl = data['actionUrl'];
      print('→ Navigating to: $actionUrl');
      AppRouterConfig.router.push(actionUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brightwin Mentors',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouterConfig.router,
    );
  }
}
