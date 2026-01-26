class BuildConfig {
  /// Values come from `--dart-define` at build time.
  ///
  /// Examples:
  /// - Production: `--dart-define=APP_ENV=prod`
  /// - Closed testing: `--dart-define=APP_ENV=closed --dart-define=ALLOW_TEST_CREDS=true ...`
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  ); // prod | closed

  /// When true, UI may prefill test credentials for internal testing builds.
  static const bool allowTestCreds = bool.fromEnvironment(
    'ALLOW_TEST_CREDS',
    defaultValue: false,
  );

  static const String testEmail = String.fromEnvironment(
    'TEST_EMAIL',
    defaultValue: '',
  );

  static const String testPassword = String.fromEnvironment(
    'TEST_PASSWORD',
    defaultValue: '',
  );

  static bool get isProd => appEnv == 'prod';

  /// Google Pay PaymentConfiguration asset to load.
  static String get googlePayConfigAsset =>
      isProd ? 'google_pay_config.json' : 'google_pay_config_test.json';

  /// Apple Pay PaymentConfiguration asset to load.
  static String get applePayConfigAsset => 'apple_pay_config.json';
}
