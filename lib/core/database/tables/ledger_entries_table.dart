import 'package:drift/drift.dart';

@TableIndex(name: 'idx_ledger_partner_id', columns: {#partnerId})
@TableIndex(name: 'idx_ledger_business_id', columns: {#businessId})
@TableIndex(name: 'idx_ledger_transaction_id', columns: {#transactionId})
@TableIndex(
  name: 'idx_ledger_partner_date',
  columns: {#partnerId, #date},
)
@TableIndex(
  name: 'idx_ledger_business_partner_date',
  columns: {#businessId, #partnerId, #date},
)
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get partnerId => text()();
  TextColumn get businessId => text()();
  TextColumn get transactionId => text()();
  IntColumn get type => integer()();
  RealColumn get amount => real()();
  RealColumn get balance => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
