import 'dart:convert';

import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final DashboardStats stats;
  final ProfitSummary profitSummary;
  final List<Map<String, dynamic>> recentTransactions;
  final List<Map<String, dynamic>> partnerSummaries;

  const DashboardData({
    required this.stats,
    required this.profitSummary,
    this.recentTransactions = const [],
    this.partnerSummaries = const [],
  });

  DashboardData copyWith({
    DashboardStats? stats,
    ProfitSummary? profitSummary,
    List<Map<String, dynamic>>? recentTransactions,
    List<Map<String, dynamic>>? partnerSummaries,
  }) {
    return DashboardData(
      stats: stats ?? this.stats,
      profitSummary: profitSummary ?? this.profitSummary,
      recentTransactions:
          recentTransactions ?? this.recentTransactions,
      partnerSummaries: partnerSummaries ?? this.partnerSummaries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stats': stats.toMap(),
      'profitSummary': profitSummary.toMap(),
      'recentTransactions': recentTransactions,
      'partnerSummaries': partnerSummaries,
    };
  }

  factory DashboardData.fromMap(Map<String, dynamic> map) {
    return DashboardData(
      stats: DashboardStats.fromMap(map['stats'] as Map<String, dynamic>),
      profitSummary: ProfitSummary.fromMap(
        map['profitSummary'] as Map<String, dynamic>,
      ),
      recentTransactions: List<Map<String, dynamic>>.from(
        (map['recentTransactions'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      ),
      partnerSummaries: List<Map<String, dynamic>>.from(
        (map['partnerSummaries'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DashboardData.fromJson(String source) {
    return DashboardData.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        profitSummary,
        recentTransactions,
        partnerSummaries,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardData &&
        other.stats == stats &&
        other.profitSummary == profitSummary;
  }

  @override
  int get hashCode => Object.hash(stats, profitSummary);

  @override
  String toString() {
    return 'DashboardData(stats: $stats, profitSummary: $profitSummary)';
  }
}

class DashboardStats extends Equatable {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double monthlyIncome;
  final double monthlyExpense;
  final int totalPartners;
  final int activePartners;
  final int totalTransactions;
  final int pendingSyncCount;

  const DashboardStats({
    this.totalBalance = 0.0,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyIncome = 0.0,
    this.monthlyExpense = 0.0,
    this.totalPartners = 0,
    this.activePartners = 0,
    this.totalTransactions = 0,
    this.pendingSyncCount = 0,
  });

  double get totalProfit => totalIncome - totalExpense;
  double get monthlyProfit => monthlyIncome - monthlyExpense;
  double get profitMargin =>
      totalIncome > 0 ? (totalProfit / totalIncome) * 100 : 0.0;

  DashboardStats copyWith({
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    double? monthlyIncome,
    double? monthlyExpense,
    int? totalPartners,
    int? activePartners,
    int? totalTransactions,
    int? pendingSyncCount,
  }) {
    return DashboardStats(
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      totalPartners: totalPartners ?? this.totalPartners,
      activePartners: activePartners ?? this.activePartners,
      totalTransactions:
          totalTransactions ?? this.totalTransactions,
      pendingSyncCount:
          pendingSyncCount ?? this.pendingSyncCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBalance': totalBalance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
      'totalPartners': totalPartners,
      'activePartners': activePartners,
      'totalTransactions': totalTransactions,
      'pendingSyncCount': pendingSyncCount,
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalBalance:
          (map['totalBalance'] as num?)?.toDouble() ?? 0.0,
      totalIncome:
          (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense:
          (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      monthlyIncome:
          (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      monthlyExpense:
          (map['monthlyExpense'] as num?)?.toDouble() ?? 0.0,
      totalPartners: map['totalPartners'] as int? ?? 0,
      activePartners: map['activePartners'] as int? ?? 0,
      totalTransactions:
          map['totalTransactions'] as int? ?? 0,
      pendingSyncCount:
          map['pendingSyncCount'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DashboardStats.fromJson(String source) {
    return DashboardStats.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        totalBalance,
        totalIncome,
        totalExpense,
        monthlyIncome,
        monthlyExpense,
        totalPartners,
        activePartners,
        totalTransactions,
        pendingSyncCount,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStats &&
        other.totalBalance == totalBalance &&
        other.totalIncome == totalIncome &&
        other.totalExpense == totalExpense &&
        other.monthlyIncome == monthlyIncome &&
        other.monthlyExpense == monthlyExpense &&
        other.totalPartners == totalPartners &&
        other.activePartners == activePartners &&
        other.totalTransactions == totalTransactions &&
        other.pendingSyncCount == pendingSyncCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalBalance,
      totalIncome,
      totalExpense,
      monthlyIncome,
      monthlyExpense,
      totalPartners,
      activePartners,
      totalTransactions,
      pendingSyncCount,
    );
  }

  @override
  String toString() {
    return 'DashboardStats(totalBalance: $totalBalance, '
        'totalProfit: $totalProfit, totalPartners: $totalPartners)';
  }
}

class ProfitSummary extends Equatable {
  final double currentMonthProfit;
  final double lastMonthProfit;
  final double currentYearProfit;
  final double lastYearProfit;
  final List<Map<String, dynamic>> monthlyBreakdown;

  const ProfitSummary({
    this.currentMonthProfit = 0.0,
    this.lastMonthProfit = 0.0,
    this.currentYearProfit = 0.0,
    this.lastYearProfit = 0.0,
    this.monthlyBreakdown = const [],
  });

  double get monthOverMonthChange =>
      lastMonthProfit != 0
          ? ((currentMonthProfit - lastMonthProfit) /
                  lastMonthProfit.abs()) *
              100
          : 0.0;

  double get yearOverYearChange =>
      lastYearProfit != 0
          ? ((currentYearProfit - lastYearProfit) /
                  lastYearProfit.abs()) *
              100
          : 0.0;

  bool get isMonthOverMonthPositive => monthOverMonthChange > 0;
  bool get isYearOverYearPositive => yearOverYearChange > 0;

  ProfitSummary copyWith({
    double? currentMonthProfit,
    double? lastMonthProfit,
    double? currentYearProfit,
    double? lastYearProfit,
    List<Map<String, dynamic>>? monthlyBreakdown,
  }) {
    return ProfitSummary(
      currentMonthProfit:
          currentMonthProfit ?? this.currentMonthProfit,
      lastMonthProfit:
          lastMonthProfit ?? this.lastMonthProfit,
      currentYearProfit:
          currentYearProfit ?? this.currentYearProfit,
      lastYearProfit: lastYearProfit ?? this.lastYearProfit,
      monthlyBreakdown:
          monthlyBreakdown ?? this.monthlyBreakdown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentMonthProfit': currentMonthProfit,
      'lastMonthProfit': lastMonthProfit,
      'currentYearProfit': currentYearProfit,
      'lastYearProfit': lastYearProfit,
      'monthlyBreakdown': monthlyBreakdown,
    };
  }

  factory ProfitSummary.fromMap(Map<String, dynamic> map) {
    return ProfitSummary(
      currentMonthProfit:
          (map['currentMonthProfit'] as num?)?.toDouble() ?? 0.0,
      lastMonthProfit:
          (map['lastMonthProfit'] as num?)?.toDouble() ?? 0.0,
      currentYearProfit:
          (map['currentYearProfit'] as num?)?.toDouble() ?? 0.0,
      lastYearProfit:
          (map['lastYearProfit'] as num?)?.toDouble() ?? 0.0,
      monthlyBreakdown: List<Map<String, dynamic>>.from(
        (map['monthlyBreakdown'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>) ??
            [],
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ProfitSummary.fromJson(String source) {
    return ProfitSummary.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        currentMonthProfit,
        lastMonthProfit,
        currentYearProfit,
        lastYearProfit,
        monthlyBreakdown,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfitSummary &&
        other.currentMonthProfit == currentMonthProfit &&
        other.lastMonthProfit == lastMonthProfit &&
        other.currentYearProfit == currentYearProfit &&
        other.lastYearProfit == lastYearProfit;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentMonthProfit,
      lastMonthProfit,
      currentYearProfit,
      lastYearProfit,
    );
  }

  @override
  String toString() {
    return 'ProfitSummary(currentMonth: $currentMonthProfit, '
        'currentYear: $currentYearProfit)';
  }
}
