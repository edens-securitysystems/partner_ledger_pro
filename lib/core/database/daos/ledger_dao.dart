import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ledger_entries_table.dart';
import '../enums/database_enums.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [LedgerEntries])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  Future<LedgerEntry> insertLedgerEntry(LedgerEntriesCompanion entry) async {
    await into(ledgerEntries).insert(entry);
    return (select(ledgerEntries)
          ..where((l) => l.id.equals(entry.id.value)))
        .getSingle();
  }

  Future<bool> updateLedgerEntry(LedgerEntriesCompanion entry) async {
    return update(ledgerEntries).replace(entry);
  }

  Future<int> deleteLedgerEntry(String id) async {
    return (delete(ledgerEntries)..where((l) => l.id.equals(id))).go();
  }

  Future<LedgerEntry?> getLedgerEntryById(String id) async {
    return (select(ledgerEntries)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<LedgerEntry?> watchLedgerEntryById(String id) {
    return (select(ledgerEntries)..where((l) => l.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<List<LedgerEntry>> getAllEntries() async {
    return (select(ledgerEntries)
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  Stream<List<LedgerEntry>> watchAllEntries() {
    return (select(ledgerEntries)
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch();
  }

  // ── Partner-wise Queries ─────────────────────────────────────────────

  Future<List<LedgerEntry>> getEntriesByPartnerId(
    String partnerId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(ledgerEntries)
      ..where((l) => l.partnerId.equals(partnerId))
      ..orderBy([(l) => OrderingTerm.desc(l.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<LedgerEntry>> watchEntriesByPartnerId(
    String partnerId, {
    int? limit,
    int? offset,
  }) {
    final query = select(ledgerEntries)
      ..where((l) => l.partnerId.equals(partnerId))
      ..orderBy([(l) => OrderingTerm.desc(l.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.watch();
  }

  Future<List<LedgerEntry>> getEntriesByPartnerAndDateRange(
    String partnerId,
    DateTime start,
    DateTime end,
  ) async {
    return (select(ledgerEntries)
          ..where((l) =>
              l.partnerId.equals(partnerId) &
              l.date.isBetweenValues(start, end))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  Stream<List<LedgerEntry>> watchEntriesByPartnerAndDateRange(
    String partnerId,
    DateTime start,
    DateTime end,
  ) {
    return (select(ledgerEntries)
          ..where((l) =>
              l.partnerId.equals(partnerId) &
              l.date.isBetweenValues(start, end))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch();
  }

  Future<List<LedgerEntry>> getEntriesByPartnerAndType(
    String partnerId,
    TransactionType type,
  ) async {
    return (select(ledgerEntries)
          ..where((l) =>
              l.partnerId.equals(partnerId) & l.type.equals(type.value))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  // ── Business-wise Queries ────────────────────────────────────────────

  Future<List<LedgerEntry>> getEntriesByBusinessId(
    String businessId, {
    int? limit,
    int? offset,
  }) async {
    final query = select(ledgerEntries)
      ..where((l) => l.businessId.equals(businessId))
      ..orderBy([(l) => OrderingTerm.desc(l.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<LedgerEntry>> watchEntriesByBusinessId(
    String businessId, {
    int? limit,
    int? offset,
  }) {
    final query = select(ledgerEntries)
      ..where((l) => l.businessId.equals(businessId))
      ..orderBy([(l) => OrderingTerm.desc(l.date)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.watch();
  }

  Future<List<LedgerEntry>> getEntriesByBusinessAndPartner(
    String businessId,
    String partnerId,
  ) async {
    return (select(ledgerEntries)
          ..where((l) =>
              l.businessId.equals(businessId) &
              l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  Stream<List<LedgerEntry>> watchEntriesByBusinessAndPartner(
    String businessId,
    String partnerId,
  ) {
    return (select(ledgerEntries)
          ..where((l) =>
              l.businessId.equals(businessId) &
              l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .watch();
  }

  // ── Transaction Link ─────────────────────────────────────────────────

  Future<List<LedgerEntry>> getEntriesByTransactionId(
    String transactionId,
  ) async {
    return (select(ledgerEntries)
          ..where((l) => l.transactionId.equals(transactionId))
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .get();
  }

  // ── Running Balance ──────────────────────────────────────────────────

  Future<List<LedgerEntry>> getEntriesWithRunningBalance(
    String partnerId,
  ) async {
    final entries = await (select(ledgerEntries)
          ..where((l) => l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .get();

    if (entries.isEmpty) return entries;

    double runningBalance = 0.0;
    final List<LedgerEntry> result = [];

    for (final entry in entries) {
      if (entry.type == TransactionType.investment.value ||
          entry.type == TransactionType.income.value) {
        runningBalance += entry.amount;
      } else if (entry.type == TransactionType.withdrawal.value ||
          entry.type == TransactionType.expense.value ||
          entry.type == TransactionType.loan.value) {
        runningBalance -= entry.amount;
      }

      result.add(LedgerEntry(
        id: entry.id,
        partnerId: entry.partnerId,
        businessId: entry.businessId,
        transactionId: entry.transactionId,
        type: entry.type,
        amount: entry.amount,
        balance: runningBalance,
        description: entry.description,
        date: entry.date,
        createdAt: entry.createdAt,
      ));
    }

    return result.reversed.toList();
  }

  Stream<List<LedgerEntry>> watchEntriesWithRunningBalance(
    String partnerId,
  ) {
    return (select(ledgerEntries)
          ..where((l) => l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .watch()
        .map((entries) {
      if (entries.isEmpty) return entries;

      double runningBalance = 0.0;
      final List<LedgerEntry> result = [];

      for (final entry in entries) {
        if (entry.type == TransactionType.investment.value ||
            entry.type == TransactionType.income.value) {
          runningBalance += entry.amount;
        } else if (entry.type == TransactionType.withdrawal.value ||
            entry.type == TransactionType.expense.value ||
            entry.type == TransactionType.loan.value) {
          runningBalance -= entry.amount;
        }

        result.add(LedgerEntry(
          id: entry.id,
          partnerId: entry.partnerId,
          businessId: entry.businessId,
          transactionId: entry.transactionId,
          type: entry.type,
          amount: entry.amount,
          balance: runningBalance,
          description: entry.description,
          date: entry.date,
          createdAt: entry.createdAt,
        ));
      }

      return result.reversed.toList();
    });
  }

  Future<double> getCurrentBalance(String partnerId) async {
    final query = select(ledgerEntries)
      ..where((l) => l.partnerId.equals(partnerId))
      ..orderBy([(l) => OrderingTerm.desc(l.date)])
      ..limit(1);
    final entries = await query.get();

    if (entries.isEmpty) return 0.0;
    return entries.first.balance;
  }

  Future<LedgerEntry?> getLatestEntry(String partnerId) async {
    return (select(ledgerEntries)
          ..where((l) => l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .getSingleOrNull();
  }

  // ── Summaries ────────────────────────────────────────────────────────

  Future<double> getTotalCreditByPartner(String partnerId) async {
    final sum = ledgerEntries.amount.sum();
    final result = await (selectOnly(ledgerEntries)
          ..addColumns([sum])
          ..where(ledgerEntries.partnerId.equals(partnerId) &
              ledgerEntries.type.isIn([
                TransactionType.investment.value,
                TransactionType.income.value,
              ])))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalDebitByPartner(String partnerId) async {
    final sum = ledgerEntries.amount.sum();
    final result = await (selectOnly(ledgerEntries)
          ..addColumns([sum])
          ..where(ledgerEntries.partnerId.equals(partnerId) &
              ledgerEntries.type.isIn([
                TransactionType.withdrawal.value,
                TransactionType.expense.value,
                TransactionType.loan.value,
              ])))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<int> getEntryCountByPartner(String partnerId) async {
    final count = ledgerEntries.id.count();
    final result = await (selectOnly(ledgerEntries)
          ..addColumns([count])
          ..where(ledgerEntries.partnerId.equals(partnerId)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getEntryCountByBusiness(String businessId) async {
    final count = ledgerEntries.id.count();
    final result = await (selectOnly(ledgerEntries)
          ..addColumns([count])
          ..where(ledgerEntries.businessId.equals(businessId)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> deleteEntriesByPartnerId(String partnerId) async {
    return (delete(ledgerEntries)
          ..where((l) => l.partnerId.equals(partnerId)))
        .go();
  }

  Future<int> deleteEntriesByBusinessId(String businessId) async {
    return (delete(ledgerEntries)
          ..where((l) => l.businessId.equals(businessId)))
        .go();
  }

  Future<int> deleteEntriesByTransactionId(String transactionId) async {
    return (delete(ledgerEntries)
          ..where((l) => l.transactionId.equals(transactionId)))
        .go();
  }
}
