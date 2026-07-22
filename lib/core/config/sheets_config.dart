class SheetsConfig {
  const SheetsConfig._();

  // ── Google Apps Script Web App URL ────────────────────────────────────────
  static const String appsScriptUrl =
      'String.fromEnvironment('APPS_SCRIPT_URL')';

  // ── Google Spreadsheet ID ─────────────────────────────────────────────────
  // From the URL: https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit
  static const String spreadsheetId = '';

  // ── Sheet Names (tabs in the spreadsheet) ─────────────────────────────────
  static const String sheetUsers = 'users';
  static const String sheetBusinesses = 'businesses';
  static const String sheetPartners = 'partners';
  static const String sheetTransactions = 'transactions';
  static const String sheetLedgerEntries = 'ledger_entries';
  static const String sheetNotifications = 'notifications';
  static const String sheetUpdateRequests = 'partner_update_requests';
  static const String sheetApprovals = 'partner_approvals';

  // ── API Actions (matching Apps Script doPost/eDoGet handlers) ─────────────
  static const String actionGetAll = 'getAll';
  static const String actionGetById = 'getById';
  static const String actionCreate = 'create';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';
  static const String actionSearch = 'search';
  static const String actionGetByField = 'getByField';
  static const String actionPing = 'ping';

  // ── Request / Response Keys ───────────────────────────────────────────────
  static const String keyAction = 'action';
  static const String keySheet = 'sheet';
  static const String keyData = 'data';
  static const String keyId = 'id';
  static const String keyField = 'field';
  static const String keyValue = 'value';
  static const String keySearch = 'search';
  static const String keySuccess = 'success';
  static const String keyMessage = 'message';
  static const String keyResult = 'result';
  static const String keyRowCount = 'rowCount';

  // ── Column Headers for each sheet ─────────────────────────────────────────
  static const List<String> usersColumns = [
    'id',
    'email',
    'name',
    'phone',
    'photo',
    'role',
    'businessId',
    'createdAt',
    'updatedAt',
    'isActive',
  ];

  static const List<String> businessesColumns = [
    'id',
    'name',
    'description',
    'logo',
    'ownerEmail',
    'address',
    'phone',
    'email',
    'website',
    'currency',
    'taxId',
    'createdAt',
    'updatedAt',
    'isActive',
  ];

  static const List<String> partnersColumns = [
    'id',
    'businessId',
    'name',
    'email',
    'phone',
    'photo',
    'capital',
    'ownershipPercentage',
    'joiningDate',
    'status',
    'description',
    'createdAt',
    'updatedAt',
    'isActive',
  ];

  static const List<String> transactionsColumns = [
    'id',
    'businessId',
    'partnerId',
    'type',
    'amount',
    'category',
    'description',
    'date',
    'time',
    'attachmentPath',
    'createdBy',
    'updatedBy',
    'createdAt',
    'updatedAt',
    'isSynced',
    'syncStatus',
  ];

  static const List<String> ledgerEntriesColumns = [
    'id',
    'partnerId',
    'businessId',
    'transactionId',
    'type',
    'amount',
    'balance',
    'description',
    'date',
    'createdAt',
  ];

  static const List<String> notificationsColumns = [
    'id',
    'userId',
    'businessId',
    'title',
    'message',
    'type',
    'isRead',
    'referenceId',
    'referenceType',
    'createdAt',
  ];

  static const List<String> updateRequestsColumns = [
    'id',
    'businessId',
    'partnerId',
    'requestedByUserId',
    'requestedByEmail',
    'requestedByName',
    'proposedChanges',
    'currentValues',
    'reason',
    'status',
    'totalApprovers',
    'approvedCount',
    'rejectedCount',
    'createdAt',
    'updatedAt',
    'resolvedAt',
  ];

  static const List<String> approvalsColumns = [
    'id',
    'updateRequestId',
    'partnerId',
    'partnerName',
    'partnerEmail',
    'decision',
    'comment',
    'createdAt',
    'updatedAt',
    'decidedAt',
  ];

  // ── Helper: Get columns for a sheet ───────────────────────────────────────
  static List<String> getColumnsForSheet(String sheet) {
    switch (sheet) {
      case sheetUsers:
        return usersColumns;
      case sheetBusinesses:
        return businessesColumns;
      case sheetPartners:
        return partnersColumns;
      case sheetTransactions:
        return transactionsColumns;
      case sheetLedgerEntries:
        return ledgerEntriesColumns;
      case sheetNotifications:
        return notificationsColumns;
      case sheetUpdateRequests:
        return updateRequestsColumns;
      case sheetApprovals:
        return approvalsColumns;
      default:
        return [];
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────
  static bool get isConfigured => appsScriptUrl.isNotEmpty;
}
