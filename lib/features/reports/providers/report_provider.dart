import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/report_dto.dart';

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
  ReportNotifier() : super(const ReportState.initial());

  Future<void> generateMonthly({required int year, required int month}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // final report = await _reportService.generateMonthlyReport(year, month);
      // state = state.copyWith(isLoading: false, reportData: report);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> generateYearly(int year) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // final report = await _reportService.generateYearlyReport(year);
      // state = state.copyWith(isLoading: false, reportData: report);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false);
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
      // final report = await _reportService.generatePartnerReport(partnerId, startDate, endDate);
      // state = state.copyWith(isLoading: false, reportData: report);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false);
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
      // final report = await _reportService.generateCashFlowReport(startDate, endDate);
      // state = state.copyWith(isLoading: false, reportData: report);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> exportPDF({required ReportRequest request}) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      // final path = await _exportService.exportToPdf(request);
      // state = state.copyWith(isExporting: false, exportedFilePath: path);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isExporting: false);
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> exportExcel({required ReportRequest request}) async {
    state = state.copyWith(isExporting: true, error: null);
    try {
      // final path = await _exportService.exportToExcel(request);
      // state = state.copyWith(isExporting: false, exportedFilePath: path);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isExporting: false);
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
  return ReportNotifier();
});
