import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../enums/database_enums.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<Transaction> insertTransaction(TransactionsCompanion entry) async {
    await into(transactions).insert(entry);
    return (select(transactions)..where((t) => t.id.equals(entry.id.value)))
        .getSingle();
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) async {
    return update(transactions).replace(entry);
  }

  Future<int> deleteTransaction(String id) async {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<Transaction?> getTransactionById(String id) async {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<Transaction?> watchTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<List<Transaction>> getAllTransactions() async {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByBusinessId(
    String businessId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(transactions)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<Transaction>> watchTransactionsByBusinessId(
    String businessId, {
    int? limit,
    int? offset,
  }) {
    final query = select(transactions)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.watch();
  }

  Future<List<Transaction>> getTransactionsByPartnerId(
    String partnerId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(transactions)
      ..where((t) => t.partnerId.equals(partnerId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<Transaction>> watchTransactionsByPartnerId(
    String partnerId, {
    int? limit,
    int? offset,
  }) {
    final query = select(transactions)
      ..where((t) => t.partnerId.equals(partnerId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.watch();
  }

  Future<List<Transaction>> getTransactionsByType(
    TransactionType type, {
    String? businessId,
  }) async {
    final query = select(transactions)
      ..where((t) => t.type.equals(type.value));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.get();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    String businessId,
    DateTime start,
    DateTime end,
  ) async {
    return (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<Transaction>> watchTransactionsByDateRange(
    String businessId,
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByPartnerAndDateRange(
    String partnerId,
    DateTime start,
    DateTime end,
  ) async {
    return (select(transactions)
          ..where((t) =>
              t.partnerId.equals(partnerId) &
              t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getFilteredTransactions({
    required String businessId,
    String? partnerId,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final query = select(transactions)
      ..where((t) => t.businessId.equals(businessId));

    if (partnerId != null) {
      query.where((t) => t.partnerId.equals(partnerId));
    }
    if (type != null) {
      query.where((t) => t.type.equals(type.value));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (startDate != null && endDate != null) {
      query.where((t) => t.date.isBetweenValues(startDate, endDate));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((t) =>
          t.description.like('%$searchQuery%') |
          t.category.like('%$searchQuery%'));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<Transaction>> watchFilteredTransactions({
    required String businessId,
    String? partnerId,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    final query = select(transactions)
      ..where((t) => t.businessId.equals(businessId));

    if (partnerId != null) {
      query.where((t) => t.partnerId.equals(partnerId));
    }
    if (type != null) {
      query.where((t) => t.type.equals(type.value));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (startDate != null && endDate != null) {
      query.where((t) => t.date.isBetweenValues(startDate, endDate));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((t) =>
          t.description.like('%$searchQuery%') |
          t.category.like('%$searchQuery%'));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.watch();
  }

  // ── Summary Queries ──────────────────────────────────────────────────

  Future<double> getTotalAmountByType(
    String businessId,
    TransactionType type,
  ) async {
    final amount = transactions.amount;
    final sum = amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals(type.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalAmountByPartnerAndType(
    String partnerId,
    TransactionType type,
  ) async {
    final sum = transactions.amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.partnerId.equals(partnerId) &
              transactions.type.equals(type.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalInvestment(String businessId) async {
    final sum = transactions.amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals(TransactionType.investment.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalExpenses(String businessId) async {
    final sum = transactions.amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals(TransactionType.expense.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalIncome(String businessId) async {
    final sum = transactions.amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals(TransactionType.income.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalWithdrawals(String businessId) async {
    final sum = transactions.amount.sum();
    final result = await (selectOnly(transactions)
          ..addColumns([sum])
          ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals(TransactionType.withdrawal.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getNetAmount(String businessId) async {
    final income = await getTotalIncome(businessId);
    final expenses = await getTotalExpenses(businessId);
    return income - expenses;
  }

  // ── Daily / Monthly / Yearly Summaries ───────────────────────────────

  Future<List<MapEntry<DateTime, double>>> getDailyTotals(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allTxns = await (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(startDate, endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final Map<DateTime, double> dailyTotals = {};
    for (final txn in allTxns) {
      final day = DateTime(txn.date.year, txn.date.month, txn.date.day);
      final current = dailyTotals[day] ?? 0.0;
      dailyTotals[day] = current + txn.amount;
    }

    return dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  Future<List<MapEntry<DateTime, double>>> getMonthlyTotals(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allTxns = await (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(startDate, endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final Map<DateTime, double> monthlyTotals = {};
    for (final txn in allTxns) {
      final month = DateTime(txn.date.year, txn.date.month, 1);
      final current = monthlyTotals[month] ?? 0.0;
      monthlyTotals[month] = current + txn.amount;
    }

    return monthlyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  Future<List<MapEntry<DateTime, double>>> getYearlyTotals(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allTxns = await (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(startDate, endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final Map<DateTime, double> yearlyTotals = {};
    for (final txn in allTxns) {
      final year = DateTime(txn.date.year, 1, 1);
      final current = yearlyTotals[year] ?? 0.0;
      yearlyTotals[year] = current + txn.amount;
    }

    return yearlyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  Future<List<MapEntry<String, double>>> getCategoryTotals(
    String businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allTxns = await (select(transactions)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.date.isBetweenValues(startDate, endDate)))
        .get();

    final Map<String, double> categoryTotals = {};
    for (final txn in allTxns) {
      final category = txn.category ?? 'Uncategorized';
      final current = categoryTotals[category] ?? 0.0;
      categoryTotals[category] = current + txn.amount;
    }

    return categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // ── Sync ─────────────────────────────────────────────────────────────

  Future<List<Transaction>> getUnsyncedTransactions() async {
    return (select(transactions)
          ..where((t) => t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markAsSynced(List<String> ids) async {
    final now = DateTime.now();
    for (final id in ids) {
      await (update(transactions)..where((t) => t.id.equals(id)))
          .replace(TransactionsCompanion(
        id: Value(id),
        isSynced: const Value(true),
        syncStatus: const Value(0),
        updatedAt: Value(now),
      ));
    }
  }

  Future<void> markForSync(
    String id,
    SyncStatus status,
  ) async {
    final now = DateTime.now();
    await (update(transactions)..where((t) => t.id.equals(id)))
        .replace(TransactionsCompanion(
      id: Value(id),
      isSynced: const Value(false),
      syncStatus: Value(status.value),
      updatedAt: Value(now),
    ));
  }

  Future<int> getTransactionCount(String businessId) async {
    final count = transactions.id.count();
    final result = await (selectOnly(transactions)
          ..addColumns([count])
          ..where(transactions.businessId.equals(businessId)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> deleteTransactionsByBusinessId(String businessId) async {
    return (delete(transactions)
          ..where((t) => t.businessId.equals(businessId)))
        .go();
  }
}
