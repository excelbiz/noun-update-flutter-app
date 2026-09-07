class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'NOUN_API_BASE_URL',
    defaultValue: 'https://nounupdate.com/api/v1',
  );

  static const oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );

  static const enableDemoFallback = bool.fromEnvironment(
    'ENABLE_DEMO_FALLBACK',
    defaultValue: true,
  );
}
