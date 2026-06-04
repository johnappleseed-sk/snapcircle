class AppConfig {
  static const String appName = 'SnapCircle';

  // Android emulator uses 10.0.2.2 to reach the host machine.
  // iOS simulator can use http://127.0.0.1:8000/api.
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
