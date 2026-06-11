import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'SnapCircle';
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'SNAPCIRCLE_API_BASE_URL',
    defaultValue: '',
  );

  // Override for demos/releases:
  // flutter run --dart-define=SNAPCIRCLE_API_BASE_URL=https://api.example.com/api
  //
  // Local defaults:
  // - Android emulator: 10.0.2.2 reaches the host machine.
  // - iOS simulator, desktop, and web: 127.0.0.1 reaches the host machine.
  // - Real phones need your computer's LAN IP or a deployed HTTPS API.
  static String get baseUrl {
    if (_definedApiBaseUrl.trim().isNotEmpty) {
      return _definedApiBaseUrl.trim();
    }

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }
}
