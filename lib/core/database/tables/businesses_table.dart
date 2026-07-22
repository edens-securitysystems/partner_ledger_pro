import 'package:drift/drift.dart';

@DataClassName('Business')
@TableIndex(name: 'idx_businesses_owner_email', columns: {#ownerEmail})
@TableIndex(name: 'idx_businesses_name', columns: {#name})
class Businesses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get logo => text().nullable()();
  TextColumn get ownerEmail => text().withLength(min: 1, max: 255)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('INR'))();
  TextColumn get taxId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
