import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/entities/ledger_entry.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class LedgerRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  LedgerRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  LedgerEntry _fromRow(Map<String, dynamic> row) {
    return LedgerEntry(
      id: '${row['id'] ?? ''}',
      partnerId: '${row['partnerId'] ?? ''}',
      businessId: '${row['businessId'] ?? ''}',
      transactionId: '${row['transactionId'] ?? ''}',
      type: TransactionType.fromValue(_sheets.parseInt(row['type'])),
      amount: _sheets.parseDouble(row['amount']),
      balance: _sheets.parseDouble(row['balance']),
      description: row['description']?.toString(),
      date: _sheets.parseDate(row['date']?.toString()),
      createdAt: _sheets.parseDate(row['createdAt']?.toString()),
    );
  }

  Map<String, dynamic> _toRow(LedgerEntry entry) {
    return {
      'id': entry.id,
      'partnerId': entry.partnerId,
      'businessId': entry.businessId,
      'transactionId': entry.transactionId,
      'type': entry.type.value,
      'amount': entry.amount,
      'balance': entry.balance,
      'description': entry.description,
      'date': entry.date.toIso8601String(),
      'createdAt': entry.createdAt.toIso8601String(),
    };
  }

  Future<ApiResponse<List<LedgerEntry>>> getPartnerLedger(
    String partnerId, {
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _sheets.getByField(
      SheetsConfig.sheetLedgerEntries,
      'partnerId',
      partnerId,
    );

    if (response.success && response.data != null) {
      var entries = response.data!.map(_fromRow).toList();

      entries.sort((a, b) => a.date.compareTo(b.date));

      if (startDate != null) {
        entries = entries.where((e) => e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate)).toList();
      }
      if (endDate != null) {
        entries = entries.where((e) => e.date.isBefore(endDate) || e.date.isAtSameMomentAs(endDate)).toList();
      }

      entries = calculateRunningBalance(entries);

      await _cacheLedger(partnerId, entries);

      final start = (page - 1) * limit;
      final end = start + limit;
      if (start < entries.length) {
        final paginated = entries.sublist(
          start,
          end > entries.length ? entries.length : end,
        );
        return ApiResponse.success(data: paginated.reversed.toList());
      }

      return ApiResponse.success(data: entries.reversed.toList());
    }

    return ApiResponse.success(data: await _getCachedLedger(partnerId));
  }

  Future<ApiResponse<LedgerEntry>> addEntry({
    required String partnerId,
    required String transactionId,
    required double amount,
    required String type,
    String? description,
  }) async {
    final now = DateTime.now();
    final entry = LedgerEntry(
      id: _sheets.generateId(),
      partnerId: partnerId,
      businessId: '',
      transactionId: transactionId,
      type: TransactionType.fromValue(
        type == 'income' || type == 'investment' ? 3 : 0,
      ),
      amount: amount,
      balance: 0,
      description: description,
      date: now,
      createdAt: now,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetLedgerEntries,
        _toRow(entry),
      );

      if (result.success) {
        return ApiResponse.success(data: entry);
      }

      return ApiResponse<LedgerEntry>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCachedLedger(partnerId);
    cached.add(entry);
    await _cacheLedger(partnerId, cached);

    return ApiResponse.success(data: entry);
  }

  Future<ApiResponse<List<LedgerEntry>>> getLedgerEntries({
    int page = 1,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetLedgerEntries);

    if (response.success && response.data != null) {
      var entries = response.data!.map(_fromRow).toList();

      entries.sort((a, b) => b.date.compareTo(a.date));

      if (startDate != null) {
        entries = entries.where((e) => e.date.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        entries = entries.where((e) => e.date.isBefore(endDate)).toList();
      }

      return ApiResponse.success(data: entries);
    }

    return ApiResponse.error(message: 'Failed to load ledger entries');
  }

  Future<ApiResponse<double>> getRunningBalance(String partnerId) async {
    final cached = await _getCachedLedger(partnerId);
    if (cached.isNotEmpty) {
      return ApiResponse.success(data: cached.last.balance);
    }

    final response = await _sheets.getByField(
      SheetsConfig.sheetLedgerEntries,
      'partnerId',
      partnerId,
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      final entries = response.data!.map(_fromRow).toList();
      final balanced = calculateRunningBalance(entries);
      if (balanced.isNotEmpty) {
        return ApiResponse.success(data: balanced.last.balance);
      }
    }

    return ApiResponse.success(data: 0.0);
  }

  List<LedgerEntry> calculateRunningBalance(List<LedgerEntry> entries) {
    if (entries.isEmpty) return entries;

    entries.sort((a, b) => a.date.compareTo(b.date));

    var runningBalance = 0.0;
    return entries.map((entry) {
      final updated = entry.isCredit
          ? entry.copyWith(balance: runningBalance + entry.amount)
          : entry.copyWith(balance: runningBalance - entry.amount);
      runningBalance = updated.balance;
      return updated;
    }).toList();
  }

  Future<ApiResponse<void>> deleteEntry(String entryId) async {
    if (_sheets.isConfigured) {
      final result = await _sheets.delete(SheetsConfig.sheetLedgerEntries, entryId);
      if (result.success) {
        return ApiResponse.success(data: null);
      }
      return ApiResponse.error(message: result.message);
    }

    return ApiResponse.success(data: null);
  }

  Future<void> _cacheLedger(String partnerId, List<LedgerEntry> entries) async {
    final json = entries.map((e) => e.toMap()).toList();
    await _storage.setPref('cached_ledger_$partnerId', json.toString());
  }

  Future<List<LedgerEntry>> _getCachedLedger(String partnerId) async {
    final cached = await _storage.getPref('cached_ledger_$partnerId');
    if (cached == null) return [];
    try {
      final list = (cached as List<dynamic>);
      final entries = list
          .map((e) => LedgerEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      return calculateRunningBalance(entries);
    } catch (_) {
      return [];
    }
  }
}
