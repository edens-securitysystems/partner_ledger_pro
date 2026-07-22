class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────

  static const String appName = 'Partner Ledger Pro';
  static const String appShortName = 'PLP';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'Professional partner ledger and accounting management system';
  static const String packageName = 'com.partnerledger.pro';
  static const String supportEmail = 'support@partnerledgerpro.com';
  static const String privacyPolicyUrl =
      'https://partnerledgerpro.com/privacy';
  static const String termsOfServiceUrl =
      'https://partnerledgerpro.com/terms';

  // ── Pagination ────────────────────────────────────────────────────────────

  static const int defaultPageSize = 20;
  static const int smallPageSize = 10;
  static const int mediumPageSize = 50;
  static const int largePageSize = 100;
  static const int maxPageSize = 500;
  static const int defaultPage = 1;
  static const int infiniteScrollThreshold = 5;

  // ── Date Formats ──────────────────────────────────────────────────────────

  static const String dateFormatFull = 'dd MMMM yyyy';
  static const String dateFormatMedium = 'dd MMM yyyy';
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatCompact = 'd MMM';
  static const String dateFormatYearMonth = 'yyyy-MM';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateFormatReadable = 'MMMM dd, yyyy';

  static const String timeFormatFull = 'hh:mm a';
  static const String timeFormat24Hour = 'HH:mm:ss';
  static const String timeFormatShort = 'hh:mm a';

  static const String dateTimeFormatFull = 'dd MMMM yyyy, hh:mm a';
  static const String dateTimeFormatMedium = 'dd MMM yyyy, hh:mm a';
  static const String dateTimeFormatShort = 'dd/MM/yyyy hh:mm a';
  static const String dateTimeFormatApi = 'yyyy-MM-ddTHH:mm:ss';

  // ── Currency ──────────────────────────────────────────────────────────────

  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';
  static const String defaultCurrencyName = 'Indian Rupee';
  static const int defaultDecimalPlaces = 2;
  static const String thousandSeparator = ',';
  static const String decimalSeparator = '.';

  // ── Validation ────────────────────────────────────────────────────────────

  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxPhoneLength = 15;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 2000;
  static const int maxReferenceLength = 50;
  static const int minAmount = 0;
  static const double maxAmount = 999999999999.99;

  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // ── Animation Durations ───────────────────────────────────────────────────

  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration animationDurationPage = Duration(milliseconds: 400);
  static const Duration animationDurationSplash = Duration(milliseconds: 1500);

  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const int staggerChildCount = 10;

  // ── Debounce & Throttle ───────────────────────────────────────────────────

  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration tapThrottle = Duration(milliseconds: 300);
  static const Duration scrollThrottle = Duration(milliseconds: 200);

  // ── Network ───────────────────────────────────────────────────────────────

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ── Cache ─────────────────────────────────────────────────────────────────

  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration longCacheExpiry = Duration(hours: 24);
  static const Duration shortCacheExpiry = Duration(minutes: 5);
  static const Duration sessionExpiry = Duration(hours: 12);
  static const Duration tokenRefreshThreshold = Duration(minutes: 30);

  // ── Storage Keys ──────────────────────────────────────────────────────────

  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'current_user';
  static const String keyBusiness = 'current_business';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyLastSync = 'last_sync_time';
  static const String keyDeviceId = 'device_id';
  static const String keyFcmToken = 'fcm_token';
  static const String keyNotificationSettings = 'notification_settings';
  static const String keyCurrency = 'preferred_currency';
  static const String keyDateFormat = 'preferred_date_format';

  // ── File Limits ───────────────────────────────────────────────────────────

  static const int maxFileSizeMB = 10;
  static const int maxAttachmentSizeMB = 25;
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> allowedDocumentExtensions = <String>[
    'pdf',
    'csv',
    'xlsx',
    'xls',
    'doc',
    'docx',
  ];

  // ── Export ────────────────────────────────────────────────────────────────

  static const List<String> exportFormats = <String>['pdf', 'csv', 'xlsx'];
  static const String defaultExportFormat = 'pdf';
  static const int maxExportRows = 10000;

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static const int recentTransactionsLimit = 5;
  static const int topPartnersLimit = 5;
  static const int chartDataPoints = 12;
  static const Duration dashboardRefreshInterval = Duration(minutes: 5);

  // ── Business Rules ────────────────────────────────────────────────────────

  static const int maxPartnersPerBusiness = 50;
  static const int maxBusinessesPerUser = 10;
  static const double minProfitMargin = -100.0;
  static const double maxProfitMargin = 10000.0;
  static const int financialYearStartMonth = 4;

  // ── Notification Defaults ─────────────────────────────────────────────────

  static const int maxNotifications = 50;
  static const int unreadBadgeLimit = 99;

  // ── Search ────────────────────────────────────────────────────────────────

  static const int minSearchLength = 2;
  static const int maxSearchLength = 100;
  static const int searchResultLimit = 20;

  // ── Regex Patterns ────────────────────────────────────────────────────────

  static const String invoiceNumberPattern = r'^(INV|INV-)\d{4,8}$';
  static const String referenceNumberPattern = r'^[A-Z0-9]{6,20}$';

  // ── Error Messages ────────────────────────────────────────────────────────

  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorUnauthorized = 'Session expired. Please log in again.';
  static const String errorForbidden = 'You do not have permission for this action.';
  static const String errorNotFound = 'Requested resource not found.';
  static const String errorValidation = 'Please check your input and try again.';
  static const String errorUnknown = 'An unexpected error occurred.';
  static const String errorOffline = 'You are currently offline.';
  static const String errorFileTooLarge = 'File size exceeds the maximum limit.';
  static const String errorInvalidFormat = 'Invalid file format.';

  // ── Success Messages ──────────────────────────────────────────────────────

  static const String successCreated = 'Created successfully';
  static const String successUpdated = 'Updated successfully';
  static const String successDeleted = 'Deleted successfully';
  static const String successSaved = 'Saved successfully';
  static const String successSynced = 'Synced successfully';
  static const String successExported = 'Exported successfully';
  static const String successCopied = 'Copied to clipboard';
}
