import '../config/sheets_config.dart';
import '../models/dto/api_response.dart';
import '../models/dto/report_dto.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class ReportRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  ReportRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  Future<ApiResponse<ReportResponse>> getProfitLossReport({
    required DateTime startDate,
    required DateTime endDate,
    String? partnerId,
    String? category,
  }) async {
    try {
      final response = await _sheets.getAll(SheetsConfig.sheetTransactions);

      if (response.success && response.data != null) {
        var transactions = response.data!;

        if (partnerId != null) {
          transactions = transactions.where((t) => t['partnerId'] == partnerId).toList();
        }
        if (category != null) {
          transactions = transactions.where((t) => t['category'] == category).toList();
        }

        transactions = transactions.where((t) {
          final date = DateTime.tryParse(t['date'] as String? ?? '') ?? DateTime.now();
          return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
              (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
        }).toList();

        double totalIncome = 0, totalExpense = 0;
        final monthlyMap = <String, MonthlyReport>{};

        for (final t in transactions) {
          final amount = _sheets.parseDouble(t['amount']);
          final type = _sheets.parseInt(t['type']);
          final date = DateTime.tryParse(t['date'] as String? ?? '') ?? DateTime.now();
          final key = '${date.year}-${date.month}';
          final isIncome = type >= 3 && type <= 4;

          if (isIncome) {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }

          monthlyMap.update(
            key,
            (existing) => MonthlyReport(
              year: date.year,
              month: date.month,
              income: isIncome ? existing.income + amount : existing.income,
              expense: isIncome ? existing.expense : existing.expense + amount,
              profit: 0,
              transactionCount: existing.transactionCount + 1,
            ),
            ifAbsent: () => MonthlyReport(
              year: date.year,
              month: date.month,
              income: isIncome ? amount : 0,
              expense: isIncome ? 0 : amount,
              profit: 0,
              transactionCount: 1,
            ),
          );
        }

        for (final key in monthlyMap.keys) {
          final m = monthlyMap[key]!;
          monthlyMap[key] = m.copyWith(profit: m.income - m.expense);
        }

        final report = ReportResponse(
          request: ReportRequest(startDate: startDate, endDate: endDate),
          monthlyReports: monthlyMap.values.toList()
            ..sort((a, b) {
              final cmp = a.year.compareTo(b.year);
              return cmp != 0 ? cmp : a.month.compareTo(b.month);
            }),
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalProfit: totalIncome - totalExpense,
          generatedAt: DateTime.now(),
        );

        await _cacheReport('profit_loss', report);
        return ApiResponse.success(data: report);
      }

      return ApiResponse.error(message: 'Failed to generate report');
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to generate report',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<ReportResponse>> getBalanceSheet({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getProfitLossReport(startDate: startDate, endDate: endDate);
  }

  Future<ApiResponse<ReportResponse>> getPartnerLedgerReport({
    required String partnerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getProfitLossReport(
      startDate: startDate,
      endDate: endDate,
      partnerId: partnerId,
    );
  }

  Future<ApiResponse<ReportResponse>> getTransactionHistoryReport({
    required DateTime startDate,
    required DateTime endDate,
    String? partnerId,
    String? category,
  }) async {
    return getProfitLossReport(
      startDate: startDate,
      endDate: endDate,
      partnerId: partnerId,
      category: category,
    );
  }

  Future<ApiResponse<ReportResponse>> generateLocally({
    required List<Map<String, dynamic>> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      double totalIncome = 0, totalExpense = 0;
      final monthlyMap = <String, MonthlyReport>{};

      for (final t in transactions) {
        final amount = (t['amount'] as num).toDouble();
        final type = t['type'] as String;
        final date = DateTime.parse(t['date'] as String);
        final key = '${date.year}-${date.month}';
        final isIncome = type == 'income' || type == 'investment';

        if (isIncome) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }

        monthlyMap.update(
          key,
          (existing) => MonthlyReport(
            year: date.year,
            month: date.month,
            income: isIncome ? existing.income + amount : existing.income,
            expense: isIncome ? existing.expense : existing.expense + amount,
            profit: 0,
            transactionCount: existing.transactionCount + 1,
          ),
          ifAbsent: () => MonthlyReport(
            year: date.year,
            month: date.month,
            income: isIncome ? amount : 0,
            expense: isIncome ? 0 : amount,
            profit: 0,
            transactionCount: 1,
          ),
        );
      }

      for (final key in monthlyMap.keys) {
        final m = monthlyMap[key]!;
        monthlyMap[key] = m.copyWith(profit: m.income - m.expense);
      }

      final report = ReportResponse(
        request: ReportRequest(startDate: startDate, endDate: endDate),
        monthlyReports: monthlyMap.values.toList()
          ..sort((a, b) {
            final cmp = a.year.compareTo(b.year);
            return cmp != 0 ? cmp : a.month.compareTo(b.month);
          }),
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalIncome - totalExpense,
        generatedAt: DateTime.now(),
      );

      return ApiResponse.success(data: report);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to generate report locally',
        error: e.toString(),
      );
    }
  }

  Future<void> _cacheReport(String key, ReportResponse report) async {
    await _storage.setPref('cached_report_$key', report.toJson());
  }

}
