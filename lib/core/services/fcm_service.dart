import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../../firebase_options.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🔔 Background message: ${message.notification?.title}');
}

/// Firebase Cloud Messaging Service
/// Handles FCM token registration and push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? _deviceId;
  bool _initialized = false;

  /// Get Firebase Messaging instance (only after initialization)
  FirebaseMessaging get messaging {
    if (_messaging == null) {
      throw Exception('Firebase Messaging not initialized. Call initialize() first.');
    }
    return _messaging!;
  }

  /// Initialize Firebase and set up FCM
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ FCM Service already initialized');
      return;
    }

    try {
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized');

      // Initialize Firebase Messaging after Firebase is initialized
      _messaging = FirebaseMessaging.instance;
      print('✅ Firebase Messaging initialized');

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get or create device ID
      await _initializeDeviceId();

      // Get FCM token
      await _getFCMToken();

      _initialized = true;
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        print('✅ Notification permission granted');
      } else {
        print('⚠️ Notification permission denied');
      }

      return granted;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'brightwin_notifications',
        'Brightwin Notifications',
        description: 'Notifications from Brightwin app',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get or create device ID
  Future<void> _initializeDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');

      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString('device_id', _deviceId!);
        print('📱 New device ID created: $_deviceId');
      } else {
        print('📱 Existing device ID: $_deviceId');
      }
    } catch (e) {
      print('❌ Error initializing device ID: $e');
      _deviceId = const Uuid().v4();
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        print('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');
      } else {
        print('⚠️ FCM Token is null');
      }
      return _fcmToken;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with backend
  Future<bool> registerTokenWithBackend(DioClient dioClient) async {
    try {
      if (_fcmToken == null || _deviceId == null) {
        print('⚠️ Cannot register: Token or Device ID is null');
        return false;
      }

      print('📤 Registering FCM token with backend...');

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Prepare request body
      final requestData = {
        'token': _fcmToken,
        'deviceId': _deviceId,
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
        'deviceModel': deviceInfo['model'],
        'osVersion': deviceInfo['osVersion'],
        'appVersion': '1.0.0', // TODO: Get from package info
      };

      print('📤 Registration data: $requestData');

      // Register with backend
      await dioClient.dio.post(
        '/api/fcm/register-token',
        data: requestData,
      );

      print('✅ FCM token registered with backend');

      // Save registration timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('fcm_registered_at', DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      print('❌ Error registering token with backend: $e');
      return false;
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'model': '${androidInfo.manufacturer} ${androidInfo.model}',
          'osVersion': 'Android ${androidInfo.version.release}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'osVersion': 'iOS ${iosInfo.systemVersion}',
        };
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
    }

    return {
      'model': 'Unknown',
      'osVersion': 'Unknown',
    };
  }

  /// Setup message handlers
  void setupMessageHandlers({
    required Function(RemoteMessage) onForegroundMessage,
    required Function(RemoteMessage) onMessageOpened,
  }) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');

      // Show local notification when app is in foreground
      _showLocalNotification(message);

      // Call custom handler
      onForegroundMessage(message);
    });

    // Background message opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Message opened from background: ${message.notification?.title}');
      onMessageOpened(message);
    });

    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📭 App opened from terminated state: ${message.notification?.title}');
        onMessageOpened(message);
      }
    });

    // Token refresh handler
    messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      // Re-register with backend
      // Note: You'll need to pass DioClient here or use a global instance
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'brightwin_notifications',
        'Brightwin Notifications',
        channelDescription: 'Notifications from Brightwin app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Unregister device token
  Future<bool> unregisterToken(DioClient dioClient) async {
    try {
      if (_deviceId == null) {
        print('⚠️ Cannot unregister: Device ID is null');
        return false;
      }

      print('📤 Unregistering device token...');

      await dioClient.dio.delete(
        '/api/fcm/unregister-token/$_deviceId',
      );

      print('✅ Device token unregistered');

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_registered_at');

      return true;
    } catch (e) {
      print('❌ Error unregistering token: $e');
      return false;
    }
  }

  /// Check if token is registered
  Future<bool> isTokenRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final registeredAt = prefs.getInt('fcm_registered_at');
    return registeredAt != null;
  }

  /// Get FCM token (public getter)
  String? get fcmToken => _fcmToken;

  /// Get device ID (public getter)
  String? get deviceId => _deviceId;

  /// Check if initialized
  bool get isInitialized => _initialized;
}
