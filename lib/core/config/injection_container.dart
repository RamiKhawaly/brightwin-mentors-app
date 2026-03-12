import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  const flutterSecureStorage = FlutterSecureStorage();
  getIt.registerLazySingleton(() => flutterSecureStorage);

  // Core
  getIt.registerLazySingleton(() => DioClient(getIt()));

  // Features will be registered here
  // Auth
  // Jobs
  // Badges
  // Feedback
}
