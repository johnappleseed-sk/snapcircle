import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'SnapCircle';

  // Android emulator uses 10.0.2.2 to reach the host machine.
  // Chrome, macOS, and iOS simulator can use 127.0.0.1.
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }
}
