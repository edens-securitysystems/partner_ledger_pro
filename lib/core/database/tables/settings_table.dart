import 'package:drift/drift.dart';

@TableIndex(name: 'idx_settings_user_id', columns: {#userId})
@TableIndex(
  name: 'idx_settings_user_key',
  columns: {#userId, #key},
  unique: true,
)
class Settings extends Table {
  TextColumn get id => text()();
  TextColumn get key => text().withLength(min: 1, max: 255)();
  TextColumn get value => text()();
  TextColumn get userId => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
