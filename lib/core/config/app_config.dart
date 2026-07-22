enum Environment {
  development,
  staging,
  production,
}

extension EnvironmentX on Environment {
  String get displayName {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  String get apiKey {
    switch (this) {
      case Environment.development:
        return 'dev';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }
}

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.appName,
    required this.appVersion,
    required this.connectionTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.maxRetries,
    required this.retryDelay,
    required this.defaultPageSize,
    required this.maxPageSize,
    required this.enableLogging,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enablePerformanceMonitoring,
    required this.cacheExpiry,
    required this.sessionExpiry,
    required this.tokenRefreshThreshold,
    required this.searchDebounce,
  required this.enableOfflineMode,
  required this.enableBiometrics,
  required this.enablePersistence,
  required this.maxUploadSizeMB,
  required this.deepLinkScheme,
  required this.supportEmail,
  required this.privacyPolicyUrl,
  required this.termsOfServiceUrl,
});

  final Environment environment;
  final String apiBaseUrl;
  final String wsBaseUrl;
  final String appName;
  final String appVersion;
  final Duration connectionTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final int defaultPageSize;
  final int maxPageSize;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enablePerformanceMonitoring;
  final Duration cacheExpiry;
  final Duration sessionExpiry;
  final Duration tokenRefreshThreshold;
  final Duration searchDebounce;
  final bool enableOfflineMode;
  final bool enableBiometrics;
  final bool enablePersistence;
  final int maxUploadSizeMB;
  final String deepLinkScheme;
  final String supportEmail;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;

  // ── Singleton ─────────────────────────────────────────────────────────────

  static AppConfig? _instance;

  static AppConfig get instance {
    assert(_instance != null, 'AppConfig has not been initialized. Call configure() first.');
    return _instance!;
  }

  static bool get isConfigured => _instance != null;

  // ── Factory Constructors ──────────────────────────────────────────────────

  factory AppConfig.development() {
    return const AppConfig._(
      environment: Environment.development,
      apiBaseUrl: '',
      wsBaseUrl: '',
      appName: 'Partner Ledger Pro (Dev)',
      appVersion: '1.0.0-dev',
      connectionTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      sendTimeout: Duration(seconds: 15),
      maxRetries: 3,
      retryDelay: Duration(seconds: 2),
      defaultPageSize: 20,
      maxPageSize: 500,
      enableLogging: true,
      enableAnalytics: false,
      enableCrashReporting: false,
      enablePerformanceMonitoring: false,
      cacheExpiry: Duration(minutes: 5),
      sessionExpiry: Duration(hours: 12),
      tokenRefreshThreshold: Duration(minutes: 30),
      searchDebounce: Duration(milliseconds: 400),
      enableOfflineMode: true,
      enableBiometrics: false,
      enablePersistence: true,
      maxUploadSizeMB: 25,
      deepLinkScheme: 'partnerledgerpro-dev',
      supportEmail: 'support@partnerledgerpro.com',
      privacyPolicyUrl: 'https://partnerledgerpro.com/privacy',
      termsOfServiceUrl: 'https://partnerledgerpro.com/terms',
    );
  }

  factory AppConfig.staging() {
    return const AppConfig._(
      environment: Environment.staging,
      apiBaseUrl: 'https://staging-api.partnerledgerpro.com',
      wsBaseUrl: 'wss://staging-api.partnerledgerpro.com/ws',
      appName: 'Partner Ledger Pro (Staging)',
      appVersion: '1.0.0-staging',
      connectionTimeout: Duration(seconds: 25),
      receiveTimeout: Duration(seconds: 25),
      sendTimeout: Duration(seconds: 15),
      maxRetries: 3,
      retryDelay: Duration(seconds: 2),
      defaultPageSize: 20,
      maxPageSize: 500,
      enableLogging: true,
      enableAnalytics: true,
      enableCrashReporting: true,
      enablePerformanceMonitoring: true,
      cacheExpiry: Duration(minutes: 10),
      sessionExpiry: Duration(hours: 12),
      tokenRefreshThreshold: Duration(minutes: 30),
      searchDebounce: Duration(milliseconds: 400),
      enableOfflineMode: true,
      enableBiometrics: true,
      enablePersistence: true,
      maxUploadSizeMB: 50,
      deepLinkScheme: 'partnerledgerpro-staging',
      supportEmail: 'support@partnerledgerpro.com',
      privacyPolicyUrl: 'https://partnerledgerpro.com/privacy',
      termsOfServiceUrl: 'https://partnerledgerpro.com/terms',
    );
  }

  factory AppConfig.production() {
    return const AppConfig._(
      environment: Environment.production,
      apiBaseUrl: 'https://api.partnerledgerpro.com',
      wsBaseUrl: 'wss://api.partnerledgerpro.com/ws',
      appName: 'Partner Ledger Pro',
      appVersion: '1.0.0',
      connectionTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      sendTimeout: Duration(seconds: 15),
      maxRetries: 3,
      retryDelay: Duration(seconds: 2),
      defaultPageSize: 20,
      maxPageSize: 500,
      enableLogging: false,
      enableAnalytics: true,
      enableCrashReporting: true,
      enablePerformanceMonitoring: true,
      cacheExpiry: Duration(hours: 1),
      sessionExpiry: Duration(hours: 12),
      tokenRefreshThreshold: Duration(minutes: 30),
      searchDebounce: Duration(milliseconds: 400),
      enableOfflineMode: true,
      enableBiometrics: true,
      enablePersistence: true,
      maxUploadSizeMB: 100,
      deepLinkScheme: 'partnerledgerpro',
      supportEmail: 'support@partnerledgerpro.com',
      privacyPolicyUrl: 'https://partnerledgerpro.com/privacy',
      termsOfServiceUrl: 'https://partnerledgerpro.com/terms',
    );
  }

  // ── Configuration ─────────────────────────────────────────────────────────

  static void configure(Environment environment) {
    switch (environment) {
      case Environment.development:
        _instance = AppConfig.development();
        break;
      case Environment.staging:
        _instance = AppConfig.staging();
        break;
      case Environment.production:
        _instance = AppConfig.production();
        break;
    }
  }

  // ── Computed Properties ───────────────────────────────────────────────────

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  bool get isDebugMode => isDevelopment || isStaging;

  String get apiVersion => 'v1';

  String get fullApiBaseUrl => '$apiBaseUrl/api/$apiVersion';

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'environment': environment.apiKey,
      'apiBaseUrl': apiBaseUrl,
      'wsBaseUrl': wsBaseUrl,
      'appName': appName,
      'appVersion': appVersion,
      'connectionTimeout': connectionTimeout.inMilliseconds,
      'receiveTimeout': receiveTimeout.inMilliseconds,
      'sendTimeout': sendTimeout.inMilliseconds,
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.inMilliseconds,
      'defaultPageSize': defaultPageSize,
      'maxPageSize': maxPageSize,
      'enableLogging': enableLogging,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'cacheExpiry': cacheExpiry.inMinutes,
      'sessionExpiry': sessionExpiry.inHours,
      'tokenRefreshThreshold': tokenRefreshThreshold.inMinutes,
      'searchDebounce': searchDebounce.inMilliseconds,
      'enableOfflineMode': enableOfflineMode,
      'enableBiometrics': enableBiometrics,
      'maxUploadSizeMB': maxUploadSizeMB,
      'supportEmail': supportEmail,
    };
  }

  @override
  String toString() {
    return 'AppConfig(environment: ${environment.displayName}, apiBaseUrl: $apiBaseUrl, appVersion: $appVersion)';
  }
}
