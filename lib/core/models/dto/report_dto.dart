import 'dart:convert';

import 'package:equatable/equatable.dart';

class ReportRequest extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? partnerId;
  final String? category;
  final ReportType type;
  final ReportFormat format;

  const ReportRequest({
    required this.startDate,
    required this.endDate,
    this.partnerId,
    this.category,
    this.type = ReportType.summary,
    this.format = ReportFormat.pdf,
  });

  ReportRequest copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? partnerId,
    String? category,
    ReportType? type,
    ReportFormat? format,
  }) {
    return ReportRequest(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      partnerId: partnerId ?? this.partnerId,
      category: category ?? this.category,
      type: type ?? this.type,
      format: format ?? this.format,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'partnerId': partnerId,
      'category': category,
      'type': type.index,
      'format': format.index,
    };
  }

  factory ReportRequest.fromMap(Map<String, dynamic> map) {
    return ReportRequest(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      partnerId: map['partnerId'] as String?,
      category: map['category'] as String?,
      type: ReportType.values[map['type'] as int? ?? 0],
      format: ReportFormat.values[map['format'] as int? ?? 0],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReportRequest.fromJson(String source) {
    return ReportRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        partnerId,
        category,
        type,
        format,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportRequest &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.partnerId == partnerId &&
        other.category == category &&
        other.type == type &&
        other.format == format;
  }

  @override
  int get hashCode {
    return Object.hash(
      startDate,
      endDate,
      partnerId,
      category,
      type,
      format,
    );
  }

  @override
  String toString() {
    return 'ReportRequest(startDate: $startDate, endDate: $endDate, '
        'type: $type)';
  }
}

enum ReportType {
  summary,
  detailed,
  partnerWise,
  categoryWise,
  profitLoss,
}

enum ReportFormat {
  pdf,
  excel,
  csv,
}

class ReportResponse extends Equatable {
  final ReportRequest request;
  final List<MonthlyReport> monthlyReports;
  final double totalIncome;
  final double totalExpense;
  final double totalProfit;
  final List<Map<String, dynamic>> partnerBreakdown;
  final List<Map<String, dynamic>> categoryBreakdown;
  final String? filePath;
  final DateTime generatedAt;

  const ReportResponse({
    required this.request,
    this.monthlyReports = const [],
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.totalProfit = 0.0,
    this.partnerBreakdown = const [],
    this.categoryBreakdown = const [],
    this.filePath,
    required this.generatedAt,
  });

  double get profitMargin =>
      totalIncome > 0 ? (totalProfit / totalIncome) * 100 : 0.0;

  bool get hasData =>
      totalIncome > 0 || totalExpense > 0;

  bool get isExported =>
      filePath != null && filePath!.isNotEmpty;

  ReportResponse copyWith({
    ReportRequest? request,
    List<MonthlyReport>? monthlyReports,
    double? totalIncome,
    double? totalExpense,
    double? totalProfit,
    List<Map<String, dynamic>>? partnerBreakdown,
    List<Map<String, dynamic>>? categoryBreakdown,
    String? filePath,
    DateTime? generatedAt,
  }) {
    return ReportResponse(
      request: request ?? this.request,
      monthlyReports: monthlyReports ?? this.monthlyReports,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      totalProfit: totalProfit ?? this.totalProfit,
      partnerBreakdown:
          partnerBreakdown ?? this.partnerBreakdown,
      categoryBreakdown:
          categoryBreakdown ?? this.categoryBreakdown,
      filePath: filePath ?? this.filePath,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'request': request.toMap(),
      'monthlyReports':
          monthlyReports.map((e) => e.toMap()).toList(),
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalProfit': totalProfit,
      'partnerBreakdown': partnerBreakdown,
      'categoryBreakdown': categoryBreakdown,
      'filePath': filePath,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ReportResponse.fromMap(Map<String, dynamic> map) {
    return ReportResponse(
      request: ReportRequest.fromMap(
        map['request'] as Map<String, dynamic>,
      ),
      monthlyReports: (map['monthlyReports'] as List<dynamic>?)
              ?.map(
                (e) => MonthlyReport.fromMap(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      totalIncome:
          (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense:
          (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      totalProfit:
          (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      partnerBreakdown: List<Map<String, dynamic>>.from(
        (map['partnerBreakdown'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      ),
      categoryBreakdown: List<Map<String, dynamic>>.from(
        (map['categoryBreakdown'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      ),
      filePath: map['filePath'] as String?,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReportResponse.fromJson(String source) {
    return ReportResponse.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        request,
        monthlyReports,
        totalIncome,
        totalExpense,
        totalProfit,
        partnerBreakdown,
        categoryBreakdown,
        filePath,
        generatedAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportResponse &&
        other.request == request &&
        other.totalIncome == totalIncome &&
        other.totalExpense == totalExpense &&
        other.totalProfit == totalProfit;
  }

  @override
  int get hashCode {
    return Object.hash(
      request,
      totalIncome,
      totalExpense,
      totalProfit,
    );
  }

  @override
  String toString() {
    return 'ReportResponse(income: $totalIncome, expense: $totalExpense, '
        'profit: $totalProfit)';
  }
}

class MonthlyReport extends Equatable {
  final int year;
  final int month;
  final double income;
  final double expense;
  final double profit;
  final int transactionCount;

  const MonthlyReport({
    required this.year,
    required this.month,
    this.income = 0.0,
    this.expense = 0.0,
    this.profit = 0.0,
    this.transactionCount = 0,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  double get profitMargin =>
      income > 0 ? (profit / income) * 100 : 0.0;

  MonthlyReport copyWith({
    int? year,
    int? month,
    double? income,
    double? expense,
    double? profit,
    int? transactionCount,
  }) {
    return MonthlyReport(
      year: year ?? this.year,
      month: month ?? this.month,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      transactionCount:
          transactionCount ?? this.transactionCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'income': income,
      'expense': expense,
      'profit': profit,
      'transactionCount': transactionCount,
    };
  }

  factory MonthlyReport.fromMap(Map<String, dynamic> map) {
    return MonthlyReport(
      year: map['year'] as int,
      month: map['month'] as int,
      income: (map['income'] as num?)?.toDouble() ?? 0.0,
      expense: (map['expense'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      transactionCount:
          map['transactionCount'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MonthlyReport.fromJson(String source) {
    return MonthlyReport.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        year,
        month,
        income,
        expense,
        profit,
        transactionCount,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyReport &&
        other.year == year &&
        other.month == month &&
        other.income == income &&
        other.expense == expense &&
        other.profit == profit &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      year,
      month,
      income,
      expense,
      profit,
      transactionCount,
    );
  }

  @override
  String toString() {
    return 'MonthlyReport($monthName $year: income: $income, '
        'expense: $expense, profit: $profit)';
  }
}

class YearlyReport extends Equatable {
  final int year;
  final double income;
  final double expense;
  final double profit;
  final int transactionCount;
  final List<MonthlyReport> monthlyBreakdown;

  const YearlyReport({
    required this.year,
    this.income = 0.0,
    this.expense = 0.0,
    this.profit = 0.0,
    this.transactionCount = 0,
    this.monthlyBreakdown = const [],
  });

  double get profitMargin =>
      income > 0 ? (profit / income) * 100 : 0.0;

  double get averageMonthlyProfit =>
      monthlyBreakdown.isNotEmpty
          ? profit / monthlyBreakdown.length
          : 0.0;

  YearlyReport copyWith({
    int? year,
    double? income,
    double? expense,
    double? profit,
    int? transactionCount,
    List<MonthlyReport>? monthlyBreakdown,
  }) {
    return YearlyReport(
      year: year ?? this.year,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      transactionCount:
          transactionCount ?? this.transactionCount,
      monthlyBreakdown:
          monthlyBreakdown ?? this.monthlyBreakdown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'income': income,
      'expense': expense,
      'profit': profit,
      'transactionCount': transactionCount,
      'monthlyBreakdown':
          monthlyBreakdown.map((e) => e.toMap()).toList(),
    };
  }

  factory YearlyReport.fromMap(Map<String, dynamic> map) {
    return YearlyReport(
      year: map['year'] as int,
      income: (map['income'] as num?)?.toDouble() ?? 0.0,
      expense: (map['expense'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      transactionCount:
          map['transactionCount'] as int? ?? 0,
      monthlyBreakdown:
          (map['monthlyBreakdown'] as List<dynamic>?)
                  ?.map(
                    (e) => MonthlyReport.fromMap(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
          [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory YearlyReport.fromJson(String source) {
    return YearlyReport.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        year,
        income,
        expense,
        profit,
        transactionCount,
        monthlyBreakdown,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YearlyReport &&
        other.year == year &&
        other.income == income &&
        other.expense == expense &&
        other.profit == profit &&
        other.transactionCount == transactionCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      year,
      income,
      expense,
      profit,
      transactionCount,
    );
  }

  @override
  String toString() {
    return 'YearlyReport($year: income: $income, expense: $expense, '
        'profit: $profit)';
  }
}
