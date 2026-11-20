/// Build-time environment configuration (`--dart-define`).
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() => const AppConfig(
        apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: productionUrl),
      );

  /// Production backend used when no override is supplied.
  static const String productionUrl = 'https://api.fatturafacile.eu';

  /// Android emulator loopback to a local `php artisan serve`.
  static const String localUrl = 'http://10.0.2.2:8000';

  final String apiBaseUrl;

  /// Versioned REST root.
  String get apiRoot => '$apiBaseUrl/api/v1';
}
