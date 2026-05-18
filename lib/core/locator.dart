import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../services/local_cache_service.dart';
import '../providers/auth_provider.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Register services
  try {
    locator.registerLazySingleton(() => LocalCacheService());
    locator.registerLazySingleton(() => AuthProvider());

    debugPrint('All services registered successfully');
  } catch (e) {
    debugPrint('Error registering services: $e');
  }
}