import 'package:flutter/material.dart';

// ── TransactionType ─────────────────────────────────────────────────────────

enum TransactionType {
  income,
  expense,
  investment,
  withdrawal,
  transfer,
  loan,
  adjustment,
}

extension TransactionTypeX on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.loan:
        return 'Loan';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String get shortName {
    switch (this) {
      case TransactionType.income:
        return 'INC';
      case TransactionType.expense:
        return 'EXP';
      case TransactionType.investment:
        return 'INV';
      case TransactionType.withdrawal:
        return 'WTH';
      case TransactionType.transfer:
        return 'TRF';
      case TransactionType.loan:
        return 'LON';
      case TransactionType.adjustment:
        return 'ADJ';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.investment:
        return Icons.account_balance_rounded;
      case TransactionType.withdrawal:
        return Icons.payments_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.loan:
        return Icons.handshake_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFF276749);
      case TransactionType.expense:
        return const Color(0xFFC05621);
      case TransactionType.investment:
        return const Color(0xFF2B6CB0);
      case TransactionType.withdrawal:
        return const Color(0xFF9C4221);
      case TransactionType.transfer:
        return const Color(0xFF553C9A);
      case TransactionType.loan:
        return const Color(0xFF2C7A7B);
      case TransactionType.adjustment:
        return const Color(0xFF718096);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TransactionType.income:
        return const Color(0xFFC6F6D5);
      case TransactionType.expense:
        return const Color(0xFFFEEBC8);
      case TransactionType.investment:
        return const Color(0xFFBEE3F8);
      case TransactionType.withdrawal:
        return const Color(0xFFFEEBC8);
      case TransactionType.transfer:
        return const Color(0xFFE9D8FD);
      case TransactionType.loan:
        return const Color(0xFFB2F5EA);
      case TransactionType.adjustment:
        return const Color(0xFFE2E8F0);
    }
  }

  String get apiKey {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.investment:
        return 'investment';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.transfer:
        return 'transfer';
      case TransactionType.loan:
        return 'loan';
      case TransactionType.adjustment:
        return 'adjustment';
    }
  }

  bool get isCredit {
    return this == TransactionType.income ||
        this == TransactionType.investment ||
        this == TransactionType.adjustment;
  }

  bool get isDebit {
    return this == TransactionType.expense ||
        this == TransactionType.withdrawal ||
        this == TransactionType.loan;
  }

  static TransactionType fromApiKey(String key) {
    return TransactionType.values.firstWhere(
      (TransactionType t) => t.apiKey == key,
      orElse: () => TransactionType.adjustment,
    );
  }
}

// ── UserRole ────────────────────────────────────────────────────────────────

enum UserRole {
  superAdmin,
  businessOwner,
  partner,
  accountant,
  viewer,
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.businessOwner:
        return 'Business Owner';
      case UserRole.partner:
        return 'Partner';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.superAdmin:
        return 'SA';
      case UserRole.businessOwner:
        return 'BO';
      case UserRole.partner:
        return 'PT';
      case UserRole.accountant:
        return 'AC';
      case UserRole.viewer:
        return 'VW';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.businessOwner:
        return Icons.business_center_rounded;
      case UserRole.partner:
        return Icons.group_rounded;
      case UserRole.accountant:
        return Icons.calculate_rounded;
      case UserRole.viewer:
        return Icons.visibility_rounded;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.superAdmin:
        return const Color(0xFFE53E3E);
      case UserRole.businessOwner:
        return const Color(0xFF2B6CB0);
      case UserRole.partner:
        return const Color(0xFF38A169);
      case UserRole.accountant:
        return const Color(0xFF805AD5);
      case UserRole.viewer:
        return const Color(0xFF718096);
    }
  }

  int get accessLevel {
    switch (this) {
      case UserRole.superAdmin:
        return 100;
      case UserRole.businessOwner:
        return 80;
      case UserRole.partner:
        return 60;
      case UserRole.accountant:
        return 40;
      case UserRole.viewer:
        return 20;
    }
  }

  String get apiKey {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.businessOwner:
        return 'business_owner';
      case UserRole.partner:
        return 'partner';
      case UserRole.accountant:
        return getShortApiKey();
      case UserRole.viewer:
        return 'viewer';
    }
  }

  String getShortApiKey() {
    return 'accountant';
  }

  static UserRole fromApiKey(String key) {
    return UserRole.values.firstWhere(
      (UserRole r) => r.apiKey == key,
      orElse: () => UserRole.viewer,
    );
  }
}

// ── PartnerStatus ───────────────────────────────────────────────────────────

enum PartnerStatus {
  active,
  inactive,
  pending,
  suspended,
}

extension PartnerStatusX on PartnerStatus {
  String get displayName {
    switch (this) {
      case PartnerStatus.active:
        return 'Active';
      case PartnerStatus.inactive:
        return 'Inactive';
      case PartnerStatus.pending:
        return 'Pending';
      case PartnerStatus.suspended:
        return 'Suspended';
    }
  }

  IconData get icon {
    switch (this) {
      case PartnerStatus.active:
        return Icons.check_circle_rounded;
      case PartnerStatus.inactive:
        return Icons.cancel_rounded;
      case PartnerStatus.pending:
        return Icons.pending_rounded;
      case PartnerStatus.suspended:
        return Icons.pause_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PartnerStatus.active:
        return const Color(0xFF38A169);
      case PartnerStatus.inactive:
        return const Color(0xFFA0AEC0);
      case PartnerStatus.pending:
        return const Color(0xFFDD6B20);
      case PartnerStatus.suspended:
        return const Color(0xFFE53E3E);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PartnerStatus.active:
        return const Color(0xFFC6F6D5);
      case PartnerStatus.inactive:
        return const Color(0xFFEDF2F7);
      case PartnerStatus.pending:
        return const Color(0xFFFEEBC8);
      case PartnerStatus.suspended:
        return const Color(0xFFFED7D7);
    }
  }

  String get apiKey {
    switch (this) {
      case PartnerStatus.active:
        return 'active';
      case PartnerStatus.inactive:
        return 'inactive';
      case PartnerStatus.pending:
        return 'pending';
      case PartnerStatus.suspended:
        return 'suspended';
    }
  }

  static PartnerStatus fromApiKey(String key) {
    return PartnerStatus.values.firstWhere(
      (PartnerStatus s) => s.apiKey == key,
      orElse: () => PartnerStatus.inactive,
    );
  }
}

// ── LedgerEntryType ─────────────────────────────────────────────────────────

enum LedgerEntryType {
  credit,
  debit,
}

extension LedgerEntryTypeX on LedgerEntryType {
  String get displayName {
    switch (this) {
      case LedgerEntryType.credit:
        return 'Credit';
      case LedgerEntryType.debit:
        return 'Debit';
    }
  }

  IconData get icon {
    switch (this) {
      case LedgerEntryType.credit:
        return Icons.arrow_downward_rounded;
      case LedgerEntryType.debit:
        return Icons.arrow_upward_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LedgerEntryType.credit:
        return const Color(0xFF2F855A);
      case LedgerEntryType.debit:
        return const Color(0xFFC53030);
    }
  }

  bool get isPositive => this == LedgerEntryType.credit;

  String get apiKey {
    switch (this) {
      case LedgerEntryType.credit:
        return 'credit';
      case LedgerEntryType.debit:
        return 'debit';
    }
  }

  static LedgerEntryType fromApiKey(String key) {
    return LedgerEntryType.values.firstWhere(
      (LedgerEntryType e) => e.apiKey == key,
      orElse: () => LedgerEntryType.debit,
    );
  }
}

// ── ReportType ──────────────────────────────────────────────────────────────

enum ReportType {
  profitLoss,
  balanceSheet,
  cashFlow,
  partnerLedger,
  trialBalance,
  ledgerSummary,
  transactionHistory,
  taxReport,
}

extension ReportTypeX on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.profitLoss:
        return 'Profit & Loss';
      case ReportType.balanceSheet:
        return 'Balance Sheet';
      case ReportType.cashFlow:
        return 'Cash Flow';
      case ReportType.partnerLedger:
        return 'Partner Ledger';
      case ReportType.trialBalance:
        return 'Trial Balance';
      case ReportType.ledgerSummary:
        return 'Ledger Summary';
      case ReportType.transactionHistory:
        return 'Transaction History';
      case ReportType.taxReport:
        return 'Tax Report';
    }
  }

  String get shortName {
    switch (this) {
      case ReportType.profitLoss:
        return 'P&L';
      case ReportType.balanceSheet:
        return 'BS';
      case ReportType.cashFlow:
        return 'CF';
      case ReportType.partnerLedger:
        return 'PL';
      case ReportType.trialBalance:
        return 'TB';
      case ReportType.ledgerSummary:
        return 'LS';
      case ReportType.transactionHistory:
        return 'TH';
      case ReportType.taxReport:
        return 'TX';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.profitLoss:
        return Icons.insights_rounded;
      case ReportType.balanceSheet:
        return Icons.balance_rounded;
      case ReportType.cashFlow:
        return Icons.waterfall_chart_rounded;
      case ReportType.partnerLedger:
        return Icons.book_rounded;
      case ReportType.trialBalance:
        return Icons.scale_rounded;
      case ReportType.ledgerSummary:
        return Icons.summarize_rounded;
      case ReportType.transactionHistory:
        return Icons.history_rounded;
      case ReportType.taxReport:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ReportType.profitLoss:
        return const Color(0xFF38A169);
      case ReportType.balanceSheet:
        return const Color(0xFF2B6CB0);
      case ReportType.cashFlow:
        return const Color(0xFF319795);
      case ReportType.partnerLedger:
        return const Color(0xFF805AD5);
      case ReportType.trialBalance:
        return const Color(0xFFDD6B20);
      case ReportType.ledgerSummary:
        return const Color(0xFF3182CE);
      case ReportType.transactionHistory:
        return const Color(0xFF718096);
      case ReportType.taxReport:
        return const Color(0xFFC53030);
    }
  }

  String get apiKey {
    switch (this) {
      case ReportType.profitLoss:
        return 'profit_loss';
      case ReportType.balanceSheet:
        return 'balance_sheet';
      case ReportType.cashFlow:
        return 'cash_flow';
      case ReportType.partnerLedger:
        return 'partner_ledger';
      case ReportType.trialBalance:
        return 'trial_balance';
      case ReportType.ledgerSummary:
        return 'ledger_summary';
      case ReportType.transactionHistory:
        return 'transaction_history';
      case ReportType.taxReport:
        return 'tax_report';
    }
  }

  static ReportType fromApiKey(String key) {
    return ReportType.values.firstWhere(
      (ReportType r) => r.apiKey == key,
      orElse: () => ReportType.partnerLedger,
    );
  }
}

// ── ChartType ───────────────────────────────────────────────────────────────

enum ChartType {
  line,
  bar,
  pie,
  doughnut,
  area,
  stackedBar,
  radar,
}

extension ChartTypeX on ChartType {
  String get displayName {
    switch (this) {
      case ChartType.line:
        return 'Line';
      case ChartType.bar:
        return 'Bar';
      case ChartType.pie:
        return 'Pie';
      case ChartType.doughnut:
        return 'Doughnut';
      case ChartType.area:
        return 'Area';
      case ChartType.stackedBar:
        return 'Stacked Bar';
      case ChartType.radar:
        return 'Radar';
    }
  }

  IconData get icon {
    switch (this) {
      case ChartType.line:
        return Icons.show_chart_rounded;
      case ChartType.bar:
        return Icons.bar_chart_rounded;
      case ChartType.pie:
        return Icons.pie_chart_rounded;
      case ChartType.doughnut:
        return Icons.donut_large_rounded;
      case ChartType.area:
        return Icons.area_chart_rounded;
      case ChartType.stackedBar:
        return Icons.stacked_bar_chart_rounded;
      case ChartType.radar:
        return Icons.radar_rounded;
    }
  }

  String get apiKey {
    switch (this) {
      case ChartType.line:
        return 'line';
      case ChartType.bar:
        return 'bar';
      case ChartType.pie:
        return 'pie';
      case ChartType.doughnut:
        return 'doughnut';
      case ChartType.area:
        return 'area';
      case ChartType.stackedBar:
        return 'stacked_bar';
      case ChartType.radar:
        return 'radar';
    }
  }

  static ChartType fromApiKey(String key) {
    return ChartType.values.firstWhere(
      (ChartType c) => c.apiKey == key,
      orElse: () => ChartType.bar,
    );
  }
}

// ── SortOrder ───────────────────────────────────────────────────────────────

enum SortOrder {
  ascending,
  descending,
}

extension SortOrderX on SortOrder {
  String get displayName {
    switch (this) {
      case SortOrder.ascending:
        return 'Ascending';
      case SortOrder.descending:
        return 'Descending';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOrder.ascending:
        return Icons.arrow_upward_rounded;
      case SortOrder.descending:
        return Icons.arrow_downward_rounded;
    }
  }

  bool get isAscending => this == SortOrder.ascending;

  String get apiKey {
    switch (this) {
      case SortOrder.ascending:
        return 'asc';
      case SortOrder.descending:
        return 'desc';
    }
  }

  static SortOrder fromApiKey(String key) {
    return SortOrder.values.firstWhere(
      (SortOrder s) => s.apiKey == key,
      orElse: () => SortOrder.descending,
    );
  }
}

// ── FilterType ──────────────────────────────────────────────────────────────

enum FilterType {
  dateRange,
  transactionType,
  partner,
  amountRange,
  status,
  category,
  paymentMethod,
  custom,
}

extension FilterTypeX on FilterType {
  String get displayName {
    switch (this) {
      case FilterType.dateRange:
        return 'Date Range';
      case FilterType.transactionType:
        return 'Transaction Type';
      case FilterType.partner:
        return 'Partner';
      case FilterType.amountRange:
        return 'Amount Range';
      case FilterType.status:
        return 'Status';
      case FilterType.category:
        return 'Category';
      case FilterType.paymentMethod:
        return 'Payment Method';
      case FilterType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case FilterType.dateRange:
        return Icons.date_range_rounded;
      case FilterType.transactionType:
        return Icons.category_rounded;
      case FilterType.partner:
        return Icons.people_rounded;
      case FilterType.amountRange:
        return Icons.attach_money_rounded;
      case FilterType.status:
        return Icons.flag_rounded;
      case FilterType.category:
        return Icons.label_rounded;
      case FilterType.paymentMethod:
        return Icons.payment_rounded;
      case FilterType.custom:
        return Icons.tune_rounded;
    }
  }

  String get apiKey {
    switch (this) {
      case FilterType.dateRange:
        return 'date_range';
      case FilterType.transactionType:
        return 'transaction_type';
      case FilterType.partner:
        return 'partner';
      case FilterType.amountRange:
        return 'amount_range';
      case FilterType.status:
        return 'status';
      case FilterType.category:
        return 'category';
      case FilterType.paymentMethod:
        return 'payment_method';
      case FilterType.custom:
        return 'custom';
    }
  }

  static FilterType fromApiKey(String key) {
    return FilterType.values.firstWhere(
      (FilterType f) => f.apiKey == key,
      orElse: () => FilterType.custom,
    );
  }
}

// ── PaymentMethod ───────────────────────────────────────────────────────────

enum PaymentMethod {
  cash,
  bankTransfer,
  upi,
  cheque,
  card,
  netBanking,
  demandDraft,
  other,
}

extension PaymentMethodX on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.demandDraft:
        return 'Demand Draft';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.upi:
        return Icons.phone_android_rounded;
      case PaymentMethod.cheque:
        return Icons.receipt_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.netBanking:
        return Icons.language_rounded;
      case PaymentMethod.demandDraft:
        return Icons.description_rounded;
      case PaymentMethod.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return const Color(0xFF38A169);
      case PaymentMethod.bankTransfer:
        return const Color(0xFF2B6CB0);
      case PaymentMethod.upi:
        return const Color(0xFF805AD5);
      case PaymentMethod.cheque:
        return const Color(0xFFDD6B20);
      case PaymentMethod.card:
        return const Color(0xFF319795);
      case PaymentMethod.netBanking:
        return const Color(0xFF2C5282);
      case PaymentMethod.demandDraft:
        return const Color(0xFF718096);
      case PaymentMethod.other:
        return const Color(0xFFA0AEC0);
    }
  }

  String get apiKey {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.netBanking:
        return 'net_banking';
      case PaymentMethod.demandDraft:
        return 'demand_draft';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod fromApiKey(String key) {
    return PaymentMethod.values.firstWhere(
      (PaymentMethod m) => m.apiKey == key,
      orElse: () => PaymentMethod.other,
    );
  }
}

// ── Currency ────────────────────────────────────────────────────────────────

enum Currency {
  inr,
  usd,
  eur,
  gbp,
  aed,
  sar,
  jpy,
  aud,
  cad,
  sgd,
}

extension CurrencyX on Currency {
  String get displayName {
    switch (this) {
      case Currency.inr:
        return 'Indian Rupee';
      case Currency.usd:
        return 'US Dollar';
      case Currency.eur:
        return 'Euro';
      case Currency.gbp:
        return 'British Pound';
      case Currency.aed:
        return 'UAE Dirham';
      case Currency.sar:
        return 'Saudi Riyal';
      case Currency.jpy:
        return 'Japanese Yen';
      case Currency.aud:
        return 'Australian Dollar';
      case Currency.cad:
        return 'Canadian Dollar';
      case Currency.sgd:
        return 'Singapore Dollar';
    }
  }

  String get symbol {
    switch (this) {
      case Currency.inr:
        return '₹';
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
      case Currency.aed:
        return 'د.إ';
      case Currency.sar:
        return '﷼';
      case Currency.jpy:
        return '¥';
      case Currency.aud:
        return 'A\$';
      case Currency.cad:
        return 'C\$';
      case Currency.sgd:
        return 'S\$';
    }
  }

  String get code {
    switch (this) {
      case Currency.inr:
        return 'INR';
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.gbp:
        return 'GBP';
      case Currency.aed:
        return 'AED';
      case Currency.sar:
        return 'SAR';
      case Currency.jpy:
        return 'JPY';
      case Currency.aud:
        return 'AUD';
      case Currency.cad:
        return 'CAD';
      case Currency.sgd:
        return 'SGD';
    }
  }

  int get decimalPlaces {
    switch (this) {
      case Currency.jpy:
        return 0;
      default:
        return 2;
    }
  }

  String formatAmount(double amount) {
    final String fixed = amount.toStringAsFixed(decimalPlaces);
    final List<String> parts = fixed.split('.');
    final String intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    if (decimalPlaces == 0) {
      return '$symbol$intPart';
    }
    return '$symbol$intPart.${parts[1]}';
  }

  String get apiKey => code.toLowerCase();

  static Currency fromApiKey(String key) {
    return Currency.values.firstWhere(
      (Currency c) => c.apiKey == key,
      orElse: () => Currency.inr,
    );
  }
}

// ── NotificationType ────────────────────────────────────────────────────────

enum NotificationType {
  transaction,
  partner,
  system,
  alert,
  reminder,
  report,
  approval,
  security,
}

extension NotificationTypeX on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.partner:
        return 'Partner';
      case NotificationType.system:
        return 'System';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.report:
        return 'Report';
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.security:
        return 'Security';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.transaction:
        return Icons.receipt_long_rounded;
      case NotificationType.partner:
        return Icons.people_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
      case NotificationType.alert:
        return Icons.notifications_active_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.report:
        return Icons.assessment_rounded;
      case NotificationType.approval:
        return Icons.approval_rounded;
      case NotificationType.security:
        return Icons.shield_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.transaction:
        return const Color(0xFF3182CE);
      case NotificationType.partner:
        return const Color(0xFF38A169);
      case NotificationType.system:
        return const Color(0xFF718096);
      case NotificationType.alert:
        return const Color(0xFFE53E3E);
      case NotificationType.reminder:
        return const Color(0xFFDD6B20);
      case NotificationType.report:
        return const Color(0xFF805AD5);
      case NotificationType.approval:
        return const Color(0xFF319795);
      case NotificationType.security:
        return const Color(0xFFC53030);
    }
  }

  String get apiKey {
    switch (this) {
      case NotificationType.transaction:
        return 'transaction';
      case NotificationType.partner:
        return 'partner';
      case NotificationType.system:
        return 'system';
      case NotificationType.alert:
        return 'alert';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.report:
        return 'report';
      case NotificationType.approval:
        return 'approval';
      case NotificationType.security:
        return 'security';
    }
  }

  static NotificationType fromApiKey(String key) {
    return NotificationType.values.firstWhere(
      (NotificationType n) => n.apiKey == key,
      orElse: () => NotificationType.system,
    );
  }
}

// ── SyncStatus ──────────────────────────────────────────────────────────────

enum SyncStatus {
  synced,
  pending,
  syncing,
  failed,
  conflict,
}

extension SyncStatusX on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  IconData get icon {
    switch (this) {
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.pending:
        return Icons.cloud_queue_rounded;
      case SyncStatus.syncing:
        return Icons.cloud_upload_rounded;
      case SyncStatus.failed:
        return Icons.cloud_off_rounded;
      case SyncStatus.conflict:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SyncStatus.synced:
        return const Color(0xFF38A169);
      case SyncStatus.pending:
        return const Color(0xFFDD6B20);
      case SyncStatus.syncing:
        return const Color(0xFF3182CE);
      case SyncStatus.failed:
        return const Color(0xFFE53E3E);
      case SyncStatus.conflict:
        return const Color(0xFF805AD5);
    }
  }

  bool get isSynced => this == SyncStatus.synced;

  bool get hasError => this == SyncStatus.failed || this == SyncStatus.conflict;

  String get apiKey {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.conflict:
        return 'conflict';
    }
  }

  static SyncStatus fromApiKey(String key) {
    return SyncStatus.values.firstWhere(
      (SyncStatus s) => s.apiKey == key,
      orElse: () => SyncStatus.pending,
    );
  }
}
