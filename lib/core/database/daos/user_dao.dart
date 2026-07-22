import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';
import '../enums/database_enums.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<User> insertUser(UsersCompanion entry) async {
    await into(users).insert(entry);
    return (select(users)..where((u) => u.id.equals(entry.id.value)))
        .getSingle();
  }

  Future<bool> updateUser(UsersCompanion entry) async {
    return update(users).replace(entry);
  }

  Future<int> deleteUser(String id) async {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }

  Future<User?> getUserById(String id) async {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) async {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  Stream<User?> watchUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<User?> watchUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email)))
        .watchSingleOrNull();
  }

  Future<List<User>> getAllUsers() async {
    return select(users).get();
  }

  Stream<List<User>> watchAllUsers() {
    return select(users).watch();
  }

  Future<List<User>> getUsersByBusinessId(String businessId) async {
    return (select(users)..where((u) => u.businessId.equals(businessId)))
        .get();
  }

  Stream<List<User>> watchUsersByBusinessId(String businessId) {
    return (select(users)..where((u) => u.businessId.equals(businessId)))
        .watch();
  }

  Future<List<User>> getActiveUsers() async {
    return (select(users)..where((u) => u.isActive.equals(true))).get();
  }

  Stream<List<User>> watchActiveUsers() {
    return (select(users)..where((u) => u.isActive.equals(true))).watch();
  }

  Future<List<User>> getUsersByRole(UserRole role) async {
    return (select(users)..where((u) => u.role.equals(role.value))).get();
  }

  Stream<List<User>> watchUsersByRole(UserRole role) {
    return (select(users)..where((u) => u.role.equals(role.value))).watch();
  }

  Future<List<User>> searchUsersByName(String query) async {
    return (select(users)
          ..where((u) => u.name.like('%$query%') | u.email.like('%$query%')))
        .get();
  }

  Future<void> updateLastLogin(String userId) async {
    final now = DateTime.now();
    await (update(users)..where((u) => u.id.equals(userId)))
        .replace(UsersCompanion(
      id: Value(userId),
      lastLogin: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> updatePin(String userId, String? pin) async {
    final now = DateTime.now();
    await (update(users)..where((u) => u.id.equals(userId)))
        .replace(UsersCompanion(
      id: Value(userId),
      pin: Value(pin),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateBiometricEnabled(String userId, bool enabled) async {
    final now = DateTime.now();
    await (update(users)..where((u) => u.id.equals(userId)))
        .replace(UsersCompanion(
      id: Value(userId),
      biometricEnabled: Value(enabled),
      updatedAt: Value(now),
    ));
  }

  Future<void> setActiveStatus(String userId, bool isActive) async {
    final now = DateTime.now();
    await (update(users)..where((u) => u.id.equals(userId)))
        .replace(UsersCompanion(
      id: Value(userId),
      isActive: Value(isActive),
      updatedAt: Value(now),
    ));
  }

  Future<int> getUserCount() async {
    final count = users.id.count();
    final result = await (selectOnly(users)..addColumns([count])).getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getActiveUserCount() async {
    final count = users.id.count();
    final result = await (selectOnly(users)
          ..addColumns([count])
          ..where(users.isActive.equals(true)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> deleteAllUsers() async {
    await delete(users).go();
  }

  Future<void> softDeleteUser(String userId) async {
    final now = DateTime.now();
    await (update(users)..where((u) => u.id.equals(userId)))
        .replace(UsersCompanion(
      id: Value(userId),
      isActive: Value(false),
      updatedAt: Value(now),
    ));
  }
}
