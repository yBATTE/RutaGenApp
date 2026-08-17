class ApiConfig {
  ApiConfig._();

  static const String serverUrl =
      'https://api.rutagen.com.ar';

  static const String baseUrl =
      '$serverUrl/api';

  static const Duration timeout =
      Duration(seconds: 15);
}