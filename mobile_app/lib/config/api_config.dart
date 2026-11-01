import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Chrome: localhost. Android emulator: 10.0.2.2. Real phone: laptop LAN IP.
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE');
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    return 'http://10.0.2.2:8080/api';
  }
}
