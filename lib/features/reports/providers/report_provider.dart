import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/report_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class ReportState extends Equatable {
  final bool isLoading;
  final bool isExporting;
  final String? error;
  final ReportResponse? reportData;
  final String? exportedFilePath;

  const ReportState({
    this.isLoading = false,
    this.isExporting = false,
    this.error,
    this.reportData,
    this.exportedFilePath,
  });

  const ReportState.initial() : this();

  ReportState copyWith({
    bool? isLoading,
    bool? isExporting,
    String? error,
    ReportResponse? reportData,
    String? exportedFilePath,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: error,
      reportData: reportData ?? this.reportData,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isExporting, error, reportData, exportedFilePath];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _reportRepository;

  ReportNotifier(this._reportRepository) : super(const ReportState.initial());

  Future<void> generateMonthly({required int year, required int month}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final response = await _reportRepository.getProfitLossReport(
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, reportData: response.data);
      } else {
        state = state.copyWith(
            isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateYearly(int year) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      final response = await _reportRepository.getProfitLossReport(
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, reportData: response.data);
      } else {
        state = state.copyWith(
            isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generatePartnerWise({
    required String partnerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _reportRepository.getPartnerLedgerReport(
        partnerId: partnerId,
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, reportData: response.data);
      } else {
        state = state.copyWith(
            isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateCashFlow({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _reportRepository.getProfitLossReport(
        startDate: startDate,
        endDate: endDate,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, reportData: response.data);
      } else {
        state = state.copyWith(
            isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> exportPDF({required ReportRequest request}) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      await _reportRepository.getProfitLossReport(
        startDate: request.startDate,
        endDate: request.endDate,
      );
      state = state.copyWith(isExporting: false, exportedFilePath: 'report_exported');
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> exportExcel({required ReportRequest request}) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      await _reportRepository.getProfitLossReport(
        startDate: request.startDate,
        endDate: request.endDate,
      );
      state = state.copyWith(isExporting: false, exportedFilePath: 'report_exported');
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  void clearReport() {
    state = const ReportState.initial();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final reportRepository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(reportRepository);
});
