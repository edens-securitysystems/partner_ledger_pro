class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────────────────────

  static const String baseUrl = 'https://api.partnerledgerpro.com';
  static const String baseUrlDev = 'https://dev-api.partnerledgerpro.com';
  static const String baseUrlStaging = 'https://staging-api.partnerledgerpro.com';

  // ── API Version ───────────────────────────────────────────────────────────

  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  // ── Headers ───────────────────────────────────────────────────────────────

  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  static const String headerBearer = 'Bearer';
  static const String headerApiKey = 'X-API-Key';
  static const String headerDeviceId = 'X-Device-Id';
  static const String headerAppVersion = 'X-App-Version';
  static const String headerPlatform = 'X-Platform';
  static const String headerRequestId = 'X-Request-Id';
  static const String headerTimestamp = 'X-Timestamp';
  static const String headerPaginationPage = 'X-Page';
  static const String headerPaginationPerPage = 'X-Per-Page';
  static const String headerPaginationTotal = 'X-Total';
  static const String headerPaginationPages = 'X-Total-Pages';

  // ── Content Types ─────────────────────────────────────────────────────────

  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static const String contentTypeOctetStream = 'application/octet-stream';

  // ── Auth ──────────────────────────────────────────────────────────────────

  static const String login = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';
  static const String logout = '$apiPrefix/auth/logout';
  static const String refreshToken = '$apiPrefix/auth/refresh';
  static const String forgotPassword = '$apiPrefix/auth/forgot-password';
  static const String resetPassword = '$apiPrefix/auth/reset-password';
  static const String verifyEmail = '$apiPrefix/auth/verify-email';
  static const String resendVerification = '$apiPrefix/auth/resend-verification';
  static const String changePassword = '$apiPrefix/auth/change-password';
  static const String twoFactorEnable = '$apiPrefix/auth/2fa/enable';
  static const String twoFactorDisable = '$apiPrefix/auth/2fa/disable';
  static const String twoFactorVerify = '$apiPrefix/auth/2fa/verify';
  static const String socialLogin = '$apiPrefix/auth/social';
  static const String sessionRevoke = '$apiPrefix/auth/sessions/revoke';
  static const String sessionList = '$apiPrefix/auth/sessions';

  // ── Users ─────────────────────────────────────────────────────────────────

  static const String userMe = '$apiPrefix/users/me';
  static const String userUpdate = '$apiPrefix/users/me';
  static const String userAvatar = '$apiPrefix/users/me/avatar';
  static const String userPreferences = '$apiPrefix/users/me/preferences';
  static const String userList = '$apiPrefix/users';
  static const String userDetail = '$apiPrefix/users/{id}';
  static const String userUpdateAdmin = '$apiPrefix/users/{id}';
  static const String userDelete = '$apiPrefix/users/{id}';
  static const String userActivity = '$apiPrefix/users/{id}/activity';

  static String userById(String id) => '$apiPrefix/users/$id';

  // ── Businesses ────────────────────────────────────────────────────────────

  static const String businessList = '$apiPrefix/businesses';
  static const String businessCreate = '$apiPrefix/businesses';
  static const String businessDetail = '$apiPrefix/businesses/{id}';
  static const String businessUpdate = '$apiPrefix/businesses/{id}';
  static const String businessDelete = '$apiPrefix/businesses/{id}';
  static const String businessMembers = '$apiPrefix/businesses/{id}/members';
  static const String businessInviteMember =
      '$apiPrefix/businesses/{id}/members/invite';
  static const String businessRemoveMember =
      '$apiPrefix/businesses/{id}/members/{memberId}';
  static const String businessUpdateMemberRole =
      '$apiPrefix/businesses/{id}/members/{memberId}';
  static const String businessSettings = '$apiPrefix/businesses/{id}/settings';
  static const String businessStats = '$apiPrefix/businesses/{id}/stats';
  static const String businessSubscription =
      '$apiPrefix/businesses/{id}/subscription';
  static const String businessBilling = '$apiPrefix/businesses/{id}/billing';

  static String businessById(String id) => '$apiPrefix/businesses/$id';
  static String businessMemberById(String bizId, String memberId) =>
      '$apiPrefix/businesses/$bizId/members/$memberId';

  // ── Partners ──────────────────────────────────────────────────────────────

  static const String partnerList = '$apiPrefix/partners';
  static const String partnerCreate = '$apiPrefix/partners';
  static const String partnerDetail = '$apiPrefix/partners/{id}';
  static const String partnerUpdate = '$apiPrefix/partners/{id}';
  static const String partnerDelete = '$apiPrefix/partners/{id}';
  static const String partnerLedger = '$apiPrefix/partners/{id}/ledger';
  static const String partnerLedgerEntries =
      '$apiPrefix/partners/{id}/ledger/entries';
  static const String partnerTransactions = '$apiPrefix/partners/{id}/transactions';
  static const String partnerBalance = '$apiPrefix/partners/{id}/balance';
  static const String partnerBalanceHistory =
      '$apiPrefix/partners/{id}/balance/history';
  static const String partnerDocuments = '$apiPrefix/partners/{id}/documents';
  static const String partnerStatement = '$apiPrefix/partners/{id}/statement';
  static const String partnerSummary = '$apiPrefix/partners/{id}/summary';
  static const String partnerActivity = '$apiPrefix/partners/{id}/activity';
  static const String partnerKyc = '$apiPrefix/partners/{id}/kyc';
  static const String partnerKycUpdate = '$apiPrefix/partners/{id}/kyc';
  static const String partnerSearch = '$apiPrefix/partners/search';
  static const String partnerImport = '$apiPrefix/partners/import';
  static const String partnerExport = '$apiPrefix/partners/export';

  static String partnerById(String id) => '$apiPrefix/partners/$id';
  static String partnerLedgerById(String id) => '$apiPrefix/partners/$id/ledger';
  static String partnerTransactionById(String partnerId, String txId) =>
      '$apiPrefix/partners/$partnerId/transactions/$txId';

  // ── Transactions ──────────────────────────────────────────────────────────

  static const String transactionList = '$apiPrefix/transactions';
  static const String transactionCreate = '$apiPrefix/transactions';
  static const String transactionDetail = '$apiPrefix/transactions/{id}';
  static const String transactionUpdate = '$apiPrefix/transactions/{id}';
  static const String transactionDelete = '$apiPrefix/transactions/{id}';
  static const String transactionBulkCreate = '$apiPrefix/transactions/bulk';
  static const String transactionBulkDelete = '$apiPrefix/transactions/bulk/delete';
  static const String transactionSearch = '$apiPrefix/transactions/search';
  static const String transactionStats = '$apiPrefix/transactions/stats';
  static const String transactionSummary = '$apiPrefix/transactions/summary';
  static const String transactionVerify = '$apiPrefix/transactions/{id}/verify';
  static const String transactionApprove = '$apiPrefix/transactions/{id}/approve';
  static const String transactionReject = '$apiPrefix/transactions/{id}/reject';
  static const String transactionReverse = '$apiPrefix/transactions/{id}/reverse';
  static const String transactionAttachments =
      '$apiPrefix/transactions/{id}/attachments';
  static const String transactionAttachmentUpload =
      '$apiPrefix/transactions/{id}/attachments/upload';
  static const String transactionAttachmentDelete =
      '$apiPrefix/transactions/{id}/attachments/{attachmentId}';
  static const String transactionDuplicate = '$apiPrefix/transactions/{id}/duplicate';
  static const String transactionRecurring = '$apiPrefix/transactions/recurring';
  static const String transactionRecurringCreate =
      '$apiPrefix/transactions/recurring';
  static const String transactionRecurringDetail =
      '$apiPrefix/transactions/recurring/{id}';
  static const String transactionRecurringDelete =
      '$apiPrefix/transactions/recurring/{id}';
  static const String transactionImport = '$apiPrefix/transactions/import';
  static const String transactionExport = '$apiPrefix/transactions/export';

  static String transactionById(String id) => '$apiPrefix/transactions/$id';

  // ── Ledger ────────────────────────────────────────────────────────────────

  static const String ledgerEntries = '$apiPrefix/ledger/entries';
  static const String ledgerEntryCreate = '$apiPrefix/ledger/entries';
  static const String ledgerEntryDetail = '$apiPrefix/ledger/entries/{id}';
  static const String ledgerEntryUpdate = '$apiPrefix/ledger/entries/{id}';
  static const String ledgerEntryDelete = '$apiPrefix/ledger/entries/{id}';
  static const String ledgerBalance = '$apiPrefix/ledger/balance';
  static const String ledgerBalanceByPartner = '$apiPrefix/ledger/balance/{partnerId}';
  static const String ledgerTrialBalance = '$apiPrefix/ledger/trial-balance';
  static const String ledgerJournal = '$apiPrefix/ledger/journal';
  static const String ledgerJournalEntry = '$apiPrefix/ledger/journal/entries';
  static const String ledgerCloseBooks = '$apiPrefix/ledger/close-books';
  static const String ledgerReopenBooks = '$apiPrefix/ledger/reopen-books';
  static const String ledgerAuditLog = '$apiPrefix/ledger/audit-log';

  static String ledgerEntryById(String id) => '$apiPrefix/ledger/entries/$id';
  static String ledgerBalanceByPartnerId(String partnerId) =>
      '$apiPrefix/ledger/balance/$partnerId';

  // ── Reports ───────────────────────────────────────────────────────────────

  static const String reportProfitLoss = '$apiPrefix/reports/profit-loss';
  static const String reportBalanceSheet = '$apiPrefix/reports/balance-sheet';
  static const String reportCashFlow = '$apiPrefix/reports/cash-flow';
  static const String reportPartnerLedger = '$apiPrefix/reports/partner-ledger';
  static const String reportTrialBalance = '$apiPrefix/reports/trial-balance';
  static const String reportLedgerSummary = '$apiPrefix/reports/ledger-summary';
  static const String reportTransactionHistory =
      '$apiPrefix/reports/transaction-history';
  static const String reportTaxReport = '$apiPrefix/reports/tax';
  static const String reportCustom = '$apiPrefix/reports/custom';
  static const String reportExport = '$apiPrefix/reports/export';
  static const String reportSchedule = '$apiPrefix/reports/schedule';
  static const String reportScheduledList = '$apiPrefix/reports/schedule';
  static const String reportScheduledDelete = '$apiPrefix/reports/schedule/{id}';
  static const String reportTemplates = '$apiPrefix/reports/templates';
  static const String reportTemplatesSave = '$apiPrefix/reports/templates';

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static const String dashboardOverview = '$apiPrefix/dashboard/overview';
  static const String dashboardStats = '$apiPrefix/dashboard/stats';
  static const String dashboardRevenue = '$apiPrefix/dashboard/revenue';
  static const String dashboardExpenses = '$apiPrefix/dashboard/expenses';
  static const String dashboardProfit = '$apiPrefix/dashboard/profit';
  static const String dashboardCashFlow = '$apiPrefix/dashboard/cash-flow';
  static const String dashboardRecentTransactions =
      '$apiPrefix/dashboard/recent-transactions';
  static const String dashboardTopPartners = '$apiPrefix/dashboard/top-partners';
  static const String dashboardOutstanding = '$apiPrefix/dashboard/outstanding';
  static const String dashboardUpcoming = '$apiPrefix/dashboard/upcoming';
  static const String dashboardTrends = '$apiPrefix/dashboard/trends';
  static const String dashboardComparison = '$apiPrefix/dashboard/comparison';
  static const String dashboardAging = '$apiPrefix/dashboard/aging-receivables';
  static const String dashboardPayables = '$apiPrefix/dashboard/aging-payables';

  // ── Notifications ─────────────────────────────────────────────────────────

  static const String notificationList = '$apiPrefix/notifications';
  static const String notificationDetail = '$apiPrefix/notifications/{id}';
  static const String notificationMarkRead = '$apiPrefix/notifications/{id}/read';
  static const String notificationMarkAllRead = '$apiPrefix/notifications/read-all';
  static const String notificationDelete = '$apiPrefix/notifications/{id}';
  static const String notificationDeleteAll = '$apiPrefix/notifications';
  static const String notificationPreferences =
      '$apiPrefix/notifications/preferences';
  static const String notificationUnreadCount = '$apiPrefix/notifications/unread';
  static const String notificationRegister = '$apiPrefix/notifications/register';

  // ── Settings ──────────────────────────────────────────────────────────────

  static const String settingsGeneral = '$apiPrefix/settings/general';
  static const String settingsBusiness = '$apiPrefix/settings/business';
  static const String settingsFinancial = '$apiPrefix/settings/financial';
  static const String settingsTax = '$apiPrefix/settings/tax';
  static const String settingsCurrency = '$apiPrefix/settings/currency';
  static const String settingsFiscalYear = '$apiPrefix/settings/fiscal-year';
  static const String settingsInvoice = '$apiPrefix/settings/invoice';
  static const String settingsEmail = '$apiPrefix/settings/email';
  static const String settingsBackup = '$apiPrefix/settings/backup';
  static const String settingsRestore = '$apiPrefix/settings/restore';
  static const String settingsExport = '$apiPrefix/settings/export';
  static const String settingsImport = '$apiPrefix/settings/import';
  static const String settingsRoles = '$apiPrefix/settings/roles';
  static const String settingsRolesCreate = '$apiPrefix/settings/roles';
  static const String settingsRolesUpdate = '$apiPrefix/settings/roles/{id}';
  static const String settingsRolesDelete = '$apiPrefix/settings/roles/{id}';
  static const String settingsAudit = '$apiPrefix/settings/audit-log';

  // ── Files & Attachments ───────────────────────────────────────────────────

  static const String fileUpload = '$apiPrefix/files/upload';
  static const String fileDelete = '$apiPrefix/files/{id}';
  static const String fileDownload = '$apiPrefix/files/{id}/download';
  static const String filePreview = '$apiPrefix/files/{id}/preview';

  // ── Search ────────────────────────────────────────────────────────────────

  static const String searchGlobal = '$apiPrefix/search';
  static const String searchPartners = '$apiPrefix/search/partners';
  static const String searchTransactions = '$apiPrefix/search/transactions';
  static const String searchReports = '$apiPrefix/search/reports';

  // ── Admin ─────────────────────────────────────────────────────────────────

  static const String adminDashboard = '$apiPrefix/admin/dashboard';
  static const String adminUsers = '$apiPrefix/admin/users';
  static const String adminBusinesses = '$apiPrefix/admin/businesses';
  static const String adminSubscriptions = '$apiPrefix/admin/subscriptions';
  static const String adminPlans = '$apiPrefix/admin/plans';
  static const String adminSystemHealth = '$apiPrefix/admin/health';
  static const String adminLogs = '$apiPrefix/admin/logs';
  static const String adminMetrics = '$apiPrefix/admin/metrics';
  static const String adminMigrations = '$apiPrefix/admin/migrations';
  static const String adminCache = '$apiPrefix/admin/cache';

  // ── WebSocket ─────────────────────────────────────────────────────────────

  static const String wsBase = 'wss://api.partnerledgerpro.com/ws';
  static const String wsBaseDev = 'wss://dev-api.partnerledgerpro.com/ws';
  static const String wsTransactions = '$wsBase/transactions';
  static const String wsNotifications = '$wsBase/notifications';
  static const String wsDashboard = '$wsBase/dashboard';
  static const String wsSync = '$wsBase/sync';

  // ── Query Parameters ──────────────────────────────────────────────────────

  static const String paramPage = 'page';
  static const String paramPerPage = 'per_page';
  static const String paramSort = 'sort';
  static const String paramOrder = 'order';
  static const String paramSearch = 'search';
  static const String paramFilter = 'filter';
  static const String paramStartDate = 'start_date';
  static const String paramEndDate = 'end_date';
  static const String paramPartnerId = 'partner_id';
  static const String paramType = 'type';
  static const String paramStatus = 'status';
  static const String paramCategory = 'category';
  static const String paramPaymentMethod = 'payment_method';
  static const String paramMinAmount = 'min_amount';
  static const String paramMaxAmount = 'max_amount';
  static const String paramCurrency = 'currency';
  static const String paramFormat = 'format';
  static const String paramInclude = 'include';
  static const String paramFields = 'fields';
  static const String paramGroupBy = 'group_by';
  static const String paramPeriod = 'period';
}
