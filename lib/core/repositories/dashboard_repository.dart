import '../config/sheets_config.dart';
import '../models/dto/api_response.dart';
import '../models/dto/dashboard_dto.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class DashboardRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  DashboardRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  Future<ApiResponse<DashboardData>> getDashboard() async {
    try {
      final transactionsResp = await _sheets.getAll(SheetsConfig.sheetTransactions);
      final partnersResp = await _sheets.getAll(SheetsConfig.sheetPartners);

      final transactions = transactionsResp.success && transactionsResp.data != null
          ? transactionsResp.data!
          : <Map<String, dynamic>>[];

      final partners = partnersResp.success && partnersResp.data != null
          ? partnersResp.data!
          : <Map<String, dynamic>>[];

      double totalIncome = 0;
      double totalExpense = 0;

      for (final t in transactions) {
        final amount = _sheets.parseDouble(t['amount']);
        final type = _sheets.parseInt(t['type']);
        if (type >= 3 && type <= 4) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      final stats = DashboardStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalPartners: partners.length,
        totalTransactions: transactions.length,
      );

      final profitSummary = ProfitSummary(
        currentMonthProfit: totalIncome - totalExpense,
      );

      final sorted = transactions.toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse('${a['date'] ?? ''}') ?? DateTime.now();
          final dateB = DateTime.tryParse('${b['date'] ?? ''}') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

      final data = DashboardData(
        stats: stats,
        profitSummary: profitSummary,
        recentTransactions: sorted.take(10).toList(),
        partnerSummaries: partners.take(5).toList(),
      );

      await _cacheDashboard(data);
      return ApiResponse.success(data: data);
    } catch (_) {
      final cached = await _getCachedDashboard();
      if (cached != null) {
        return ApiResponse.success(data: cached);
      }
      return ApiResponse.error(message: 'Failed to load dashboard');
    }
  }

  Future<ApiResponse<DashboardStats>> getStats() async {
    try {
      final transactionsResp = await _sheets.getAll(SheetsConfig.sheetTransactions);
      final partnersResp = await _sheets.getAll(SheetsConfig.sheetPartners);

      double income = 0, expense = 0;
      int txCount = 0;

      if (transactionsResp.success && transactionsResp.data != null) {
        txCount = transactionsResp.data!.length;
        for (final t in transactionsResp.data!) {
          final amount = _sheets.parseDouble(t['amount']);
          final type = _sheets.parseInt(t['type']);
          if (type >= 3 && type <= 4) {
            income += amount;
          } else {
            expense += amount;
          }
        }
      }

      final partnerCount = (partnersResp.success && partnersResp.data != null)
          ? partnersResp.data!.length
          : 0;

      return ApiResponse.success(
        data: DashboardStats(
          totalIncome: income,
          totalExpense: expense,
          totalPartners: partnerCount,
          totalTransactions: txCount,
        ),
      );
    } catch (_) {
      return ApiResponse.error(message: 'Failed to load stats');
    }
  }

  Future<ApiResponse<ProfitSummary>> getProfitSummary() async {
    try {
      final response = await _sheets.getAll(SheetsConfig.sheetTransactions);

      if (response.success && response.data != null) {
        double income = 0, expense = 0;

        for (final t in response.data!) {
          final amount = _sheets.parseDouble(t['amount']);
          final type = _sheets.parseInt(t['type']);
          if (type >= 3 && type <= 4) {
            income += amount;
          } else {
            expense += amount;
          }
        }

        return ApiResponse.success(
          data: ProfitSummary(
            currentMonthProfit: income - expense,
          ),
        );
      }

      return ApiResponse.error(message: 'Failed to load profit summary');
    } catch (_) {
      return ApiResponse.error(message: 'Failed to load profit summary');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentTransactions({
    int limit = 10,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetTransactions);

    if (response.success && response.data != null) {
      final sorted = response.data!.toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse('${a['date'] ?? ''}') ?? DateTime.now();
          final dateB = DateTime.tryParse('${b['date'] ?? ''}') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
      return ApiResponse.success(data: sorted.take(limit).toList());
    }

    return ApiResponse.error(message: 'Failed to load recent transactions');
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getTopPartners({
    int limit = 5,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetPartners);

    if (response.success && response.data != null) {
      final sorted = response.data!.toList()
        ..sort((a, b) {
          final capA = _sheets.parseDouble(a['capital']);
          final capB = _sheets.parseDouble(b['capital']);
          return capB.compareTo(capA);
        });
      return ApiResponse.success(data: sorted.take(limit).toList());
    }

    return ApiResponse.error(message: 'Failed to load top partners');
  }

  Future<void> _cacheDashboard(DashboardData data) async {
    await _storage.setPref('cached_dashboard', data.toJson());
  }

  Future<DashboardData?> _getCachedDashboard() async {
    final cached = await _storage.getPref('cached_dashboard');
    if (cached == null) return null;
    try {
      return DashboardData.fromJson(cached);
    } catch (_) {
      return null;
    }
  }
}
