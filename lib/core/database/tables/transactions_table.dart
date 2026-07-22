import 'package:drift/drift.dart';

@TableIndex(name: 'idx_transactions_business_id', columns: {#businessId})
@TableIndex(name: 'idx_transactions_partner_id', columns: {#partnerId})
@TableIndex(name: 'idx_transactions_type', columns: {#type})
@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(
  name: 'idx_transactions_business_partner',
  columns: {#businessId, #partnerId},
)
@TableIndex(
  name: 'idx_transactions_business_date',
  columns: {#businessId, #date},
)
@TableIndex(
  name: 'idx_transactions_sync_status',
  columns: {#isSynced, #syncStatus},
)
@TableIndex(name: 'idx_transactions_created_by', columns: {#createdBy})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get partnerId => text()();
  IntColumn get type => integer()();
  RealColumn get amount => real()();
  TextColumn get category => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
