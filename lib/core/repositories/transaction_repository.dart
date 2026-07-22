import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/dto/transaction_dto.dart';
import '../models/entities/transaction.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class TransactionRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  TransactionRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  Transaction _fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: '${row['id'] ?? ''}',
      businessId: '${row['businessId'] ?? ''}',
      partnerId: '${row['partnerId'] ?? ''}',
      type: TransactionType.fromValue(_sheets.parseInt(row['type'])),
      amount: _sheets.parseDouble(row['amount']),
      category: row['category']?.toString(),
      description: row['description']?.toString(),
      date: _sheets.parseDate(row['date']?.toString()),
      time: row['time']?.toString(),
      attachmentPath: row['attachmentPath']?.toString(),
      createdBy: '${row['createdBy'] ?? ''}',
      updatedBy: row['updatedBy']?.toString(),
      createdAt: _sheets.parseDate(row['createdAt']?.toString()),
      updatedAt: _sheets.parseDate(row['updatedAt']?.toString()),
      isSynced: _sheets.parseBool(row['isSynced']),
      syncStatus: SyncStatus.fromValue(
        _sheets.parseInt(row['syncStatus']),
      ),
    );
  }

  Map<String, dynamic> _toRow(Transaction t) {
    return {
      'id': t.id,
      'businessId': t.businessId,
      'partnerId': t.partnerId,
      'type': t.type.value,
      'amount': t.amount,
      'category': t.category,
      'description': t.description,
      'date': t.date.toIso8601String(),
      'time': t.time,
      'attachmentPath': t.attachmentPath,
      'createdBy': t.createdBy,
      'updatedBy': t.updatedBy,
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': t.updatedAt.toIso8601String(),
      'isSynced': t.isSynced,
      'syncStatus': t.syncStatus.value,
    };
  }

  List<Transaction> _applyFilter(List<Transaction> items, TransactionFilter? filter) {
    if (filter == null) return items;

    var result = items;

    if (filter.partnerId != null) {
      result = result.where((t) => t.partnerId == filter.partnerId).toList();
    }
    if (filter.type != null) {
      result = result.where((t) => t.type == filter.type).toList();
    }
    if (filter.startDate != null) {
      result = result.where((t) => t.date.isAfter(filter.startDate!) || t.date.isAtSameMomentAs(filter.startDate!)).toList();
    }
    if (filter.endDate != null) {
      result = result.where((t) => t.date.isBefore(filter.endDate!) || t.date.isAtSameMomentAs(filter.endDate!)).toList();
    }
    if (filter.minAmount != null) {
      result = result.where((t) => t.amount >= filter.minAmount!).toList();
    }
    if (filter.maxAmount != null) {
      result = result.where((t) => t.amount <= filter.maxAmount!).toList();
    }
    if (filter.category != null) {
      result = result.where((t) => t.category == filter.category).toList();
    }

    return result;
  }

  Future<ApiResponse<List<Transaction>>> getAll({
    TransactionFilter? filter,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetTransactions);

    if (response.success && response.data != null) {
      var transactions = response.data!.map(_fromRow).toList();
      transactions = _applyFilter(transactions, filter);

      transactions.sort((a, b) => b.date.compareTo(a.date));

      return ApiResponse.success(data: transactions);
    }

    return ApiResponse.success(data: await _getCached());
  }

  Future<ApiResponse<Transaction>> getById(String id) async {
    final response = await _sheets.getById(SheetsConfig.sheetTransactions, id);

    if (response.success && response.data != null) {
      return ApiResponse.success(data: _fromRow(response.data!));
    }

    return ApiResponse.error(message: 'Transaction not found');
  }

  Future<ApiResponse<Transaction>> create(CreateTransactionRequest request) async {
    final now = DateTime.now();
    final transaction = Transaction(
      id: _sheets.generateId(),
      businessId: '',
      partnerId: request.partnerId,
      type: request.type,
      amount: request.amount,
      category: request.category,
      description: request.description,
      date: request.date,
      time: request.time,
      attachmentPath: request.attachmentPath,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      syncStatus: SyncStatus.pendingCreate,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetTransactions,
        _toRow(transaction),
      );

      if (result.success) {
        return ApiResponse.success(
          data: transaction.copyWith(isSynced: true, syncStatus: SyncStatus.synced),
        );
      }

      return ApiResponse<Transaction>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCached();
    cached.add(transaction);
    await _cacheTransactions(cached);

    return ApiResponse.success(data: transaction);
  }

  Future<ApiResponse<Transaction>> update(String id, UpdateTransactionRequest request) async {
    final existing = await getById(id);
    if (!existing.success || existing.data == null) {
      return ApiResponse.error(message: 'Transaction not found');
    }

    final updated = existing.data!.copyWith(
      partnerId: request.partnerId,
      type: request.type,
      amount: request.amount,
      category: request.category,
      description: request.description,
      date: request.date,
      time: request.time,
      attachmentPath: request.attachmentPath,
      updatedAt: DateTime.now(),
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetTransactions,
        id,
        _toRow(updated),
      );

      if (result.success) {
        return ApiResponse.success(data: updated);
      }

      return ApiResponse<Transaction>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCached();
    final index = cached.indexWhere((t) => t.id == id);
    if (index >= 0) cached[index] = updated;
    await _cacheTransactions(cached);

    return ApiResponse.success(data: updated);
  }

  Future<ApiResponse<void>> delete(String id) async {
    if (_sheets.isConfigured) {
      final result = await _sheets.delete(SheetsConfig.sheetTransactions, id);
      if (result.success) {
        return ApiResponse.success(data: null);
      }
      return ApiResponse.error(message: result.message);
    }

    final cached = await _getCached();
    cached.removeWhere((t) => t.id == id);
    await _cacheTransactions(cached);

    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<List<Transaction>>> filterByPartner(String partnerId) async {
    return getAll(filter: TransactionFilter(partnerId: partnerId));
  }

  Future<ApiResponse<List<Transaction>>> filterByDateRange(
    DateTime start, DateTime end,
  ) async {
    return getAll(filter: TransactionFilter(startDate: start, endDate: end));
  }

  Future<ApiResponse<List<Transaction>>> filterByType(TransactionType type) async {
    return getAll(filter: TransactionFilter(type: type));
  }

  Future<ApiResponse<List<Transaction>>> filterByCategory(String category) async {
    return getAll(filter: TransactionFilter(category: category));
  }

  Future<List<Transaction>> _getCached() async {
    final data = await _storage.getPref('cached_transactions');
    if (data == null) return [];
    try {
      final list = (data as List<dynamic>);
      return list
          .map((e) => Transaction.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheTransactions(List<Transaction> transactions) async {
    final json = transactions.map((t) => t.toMap()).toList();
    await _storage.setPref('cached_transactions', json.toString());
  }
}
