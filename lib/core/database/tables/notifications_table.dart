import 'package:drift/drift.dart';

@TableIndex(name: 'idx_notifications_user_id', columns: {#userId})
@TableIndex(name: 'idx_notifications_is_read', columns: {#isRead})
@TableIndex(
  name: 'idx_notifications_user_read',
  columns: {#userId, #isRead},
)
@TableIndex(name: 'idx_notifications_created_at', columns: {#createdAt})
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get message => text()();
  IntColumn get type => integer().withDefault(const Constant(0))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get data => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
