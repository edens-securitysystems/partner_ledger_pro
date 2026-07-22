import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/dashboard_dto.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/dashboard_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class DashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final DashboardData? data;
  final DateTime? lastFetched;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.data,
    this.lastFetched,
  });

  const DashboardState.initial() : this();

  const DashboardState.loading() : this(isLoading: true);

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardData? data,
    DateTime? lastFetched,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, data, lastFetched];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState.initial());

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getDashboard();
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          data: response.data,
          lastFetched: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getDashboard();
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          data: response.data,
          lastFetched: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repository);
});

final dashboardDataProvider = Provider<DashboardData?>((ref) {
  return ref.watch(dashboardProvider).data;
});

final dashboardStatsProvider = Provider<DashboardStats?>((ref) {
  return ref.watch(dashboardProvider).data?.stats;
});

final dashboardProfitSummaryProvider = Provider<ProfitSummary?>((ref) {
  return ref.watch(dashboardProvider).data?.profitSummary;
});

final todayProfitProvider = Provider<double>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  return stats?.monthlyProfit ?? 0.0;
});

final monthlyProfitProvider = Provider<double>((ref) {
  final profit = ref.watch(dashboardProfitSummaryProvider);
  return profit?.currentMonthProfit ?? 0.0;
});

final yearlyProfitProvider = Provider<double>((ref) {
  final profit = ref.watch(dashboardProfitSummaryProvider);
  return profit?.currentYearProfit ?? 0.0;
});

final totalIncomeProvider = Provider<double>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  return stats?.totalIncome ?? 0.0;
});

final totalExpenseProvider = Provider<double>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  return stats?.totalExpense ?? 0.0;
});

final totalPartnersProvider = Provider<int>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  return stats?.totalPartners ?? 0;
});

final activePartnersProvider = Provider<int>((ref) {
  final stats = ref.watch(dashboardStatsProvider);
  return stats?.activePartners ?? 0;
});
