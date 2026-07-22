import 'package:drift/drift.dart';

@TableIndex(name: 'idx_users_email', columns: {#email}, unique: true)
@TableIndex(name: 'idx_users_business_id', columns: {#businessId})
@TableIndex(name: 'idx_users_role', columns: {#role})
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().withLength(min: 1, max: 255)();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get photo => text().nullable()();
  IntColumn get role => integer().withDefault(const Constant(4))();
  TextColumn get businessId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get pin => text().nullable()();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
