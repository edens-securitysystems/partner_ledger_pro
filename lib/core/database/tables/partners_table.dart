import 'package:drift/drift.dart';

@TableIndex(name: 'idx_partners_business_id', columns: {#businessId})
@TableIndex(name: 'idx_partners_status', columns: {#status})
@TableIndex(
  name: 'idx_partners_business_status',
  columns: {#businessId, #status},
)
class Partners extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get photo => text().nullable()();
  RealColumn get capital => real().withDefault(const Constant(0.0))();
  RealColumn get ownershipPercentage =>
      real().withDefault(const Constant(0.0))();
  DateTimeColumn get joiningDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
