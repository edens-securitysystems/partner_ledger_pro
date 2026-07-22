import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'native_database_helper_export.dart';

import 'tables/users_table.dart';
import 'tables/businesses_table.dart';
import 'tables/partners_table.dart';
import 'tables/transactions_table.dart';
import 'tables/ledger_entries_table.dart';
import 'tables/notifications_table.dart';
import 'tables/settings_table.dart';
import 'enums/database_enums.dart';
import 'daos/user_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/partner_dao.dart';
import 'daos/ledger_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Businesses,
    Partners,
    Transactions,
    LedgerEntries,
    Notifications,
    Settings,
  ],
  daos: [
    UserDao,
    TransactionDao,
    PartnerDao,
    LedgerDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  static const int _schemaVersion = 1;
  static const _uuid = Uuid();

  @override
  int get schemaVersion => _schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _addNotificationsTable(m);
          }
          if (from < 3) {
            await _addSettingsTable(m);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _addNotificationsTable(Migrator m) async {
    await m.createTable(notifications);
  }

  Future<void> _addSettingsTable(Migrator m) async {
    await m.createTable(settings);
  }

  // ── Users CRUD ──────────────────────────────────────────────────────

  Future<String> createUser({
    required String email,
    required String name,
    String? phone,
    String? photo,
    UserRole role = UserRole.viewer,
    String? businessId,
    String? pin,
    bool biometricEnabled = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(users).insert(
      UsersCompanion.insert(
        id: id,
        email: email,
        name: name,
        phone: Value(phone),
        photo: Value(photo),
        role: Value(role.value),
        businessId: Value(businessId),
        createdAt: Value(now),
        updatedAt: Value(now),
        isActive: const Value(true),
        pin: Value(pin),
        biometricEnabled: Value(biometricEnabled),
      ),
    );
    return id;
  }

  Future<bool> updateUser(User user) async {
    return update(users).replace(user);
  }

  Future<void> updateUserById({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? photo,
    UserRole? role,
    String? businessId,
    String? pin,
    bool? biometricEnabled,
  }) async {
    final now = DateTime.now();
    final companion = UsersCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      email: email != null ? Value(email) : const Value.absent(),
      phone: Value(phone),
      photo: Value(photo),
      role: role != null ? Value(role.value) : const Value.absent(),
      businessId: Value(businessId),
      pin: Value(pin),
      biometricEnabled:
          biometricEnabled != null ? Value(biometricEnabled) : const Value.absent(),
      updatedAt: Value(now),
    );
    await (update(users)..where((u) => u.id.equals(id))).replace(companion);
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

  Future<List<User>> getAllUsers() async => select(users).get();

  Future<List<User>> getUsersByBusinessId(String businessId) async {
    return (select(users)..where((u) => u.businessId.equals(businessId)))
        .get();
  }

  // ── Businesses CRUD ─────────────────────────────────────────────────

  Future<String> createBusiness({
    required String name,
    required String ownerEmail,
    String? description,
    String? logo,
    String? address,
    String? phone,
    String? email,
    String? website,
    String currency = 'INR',
    String? taxId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(businesses).insert(
      BusinessesCompanion.insert(
        id: id,
        name: name,
        description: Value(description),
        logo: Value(logo),
        ownerEmail: ownerEmail,
        address: Value(address),
        phone: Value(phone),
        email: Value(email),
        website: Value(website),
        currency: Value(currency),
        taxId: Value(taxId),
        createdAt: Value(now),
        updatedAt: Value(now),
        isActive: const Value(true),
      ),
    );
    return id;
  }

  Future<bool> updateBusiness(Business business) async {
    return update(businesses).replace(business);
  }

  Future<void> updateBusinessById({
    required String id,
    String? name,
    String? description,
    String? logo,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? currency,
    String? taxId,
  }) async {
    final now = DateTime.now();
    final companion = BusinessesCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description: Value(description),
      logo: Value(logo),
      address: Value(address),
      phone: Value(phone),
      email: Value(email),
      website: Value(website),
      currency: currency != null ? Value(currency) : const Value.absent(),
      taxId: Value(taxId),
      updatedAt: Value(now),
    );
    await (update(businesses)..where((b) => b.id.equals(id)))
        .replace(companion);
  }

  Future<int> deleteBusiness(String id) async {
    return (delete(businesses)..where((b) => b.id.equals(id))).go();
  }

  Future<Business?> getBusinessById(String id) async {
    return (select(businesses)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Business>> getAllBusinesses() async =>
      select(businesses).get();

  Future<List<Business>> getBusinessesByOwnerEmail(String email) async {
    return (select(businesses)
          ..where((b) => b.ownerEmail.equals(email)))
        .get();
  }

  Future<List<Business>> getActiveBusinesses() async {
    return (select(businesses)
          ..where((b) => b.isActive.equals(true)))
        .get();
  }

  // ── Partners CRUD ───────────────────────────────────────────────────

  Future<String> createPartner({
    required String businessId,
    required String name,
    String? email,
    String? phone,
    String? photo,
    double capital = 0.0,
    double ownershipPercentage = 0.0,
    DateTime? joiningDate,
    PartnerStatus status = PartnerStatus.active,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(partners).insert(
      PartnersCompanion.insert(
        id: id,
        businessId: businessId,
        name: name,
        email: Value(email),
        phone: Value(phone),
        photo: Value(photo),
        capital: Value(capital),
        ownershipPercentage: Value(ownershipPercentage),
        joiningDate: Value(joiningDate ?? now),
        status: Value(status.value),
        description: Value(description),
        createdAt: Value(now),
        updatedAt: Value(now),
        isActive: const Value(true),
      ),
    );
    return id;
  }

  Future<bool> updatePartner(Partner partner) async {
    return update(partners).replace(partner);
  }

  Future<void> updatePartnerById({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? photo,
    double? capital,
    double? ownershipPercentage,
    PartnerStatus? status,
    String? description,
  }) async {
    final now = DateTime.now();
    final companion = PartnersCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      email: Value(email),
      phone: Value(phone),
      photo: Value(photo),
      capital: capital != null ? Value(capital) : const Value.absent(),
      ownershipPercentage: ownershipPercentage != null
          ? Value(ownershipPercentage)
          : const Value.absent(),
      status: status != null ? Value(status.value) : const Value.absent(),
      description: Value(description),
      updatedAt: Value(now),
    );
    await (update(partners)..where((p) => p.id.equals(id))).replace(companion);
  }

  Future<int> deletePartner(String id) async {
    return (delete(partners)..where((p) => p.id.equals(id))).go();
  }

  Future<Partner?> getPartnerById(String id) async {
    return (select(partners)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Partner>> getPartnersByBusinessId(String businessId) async {
    return (select(partners)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Future<List<Partner>> getActivePartnersByBusinessId(
    String businessId,
  ) async {
    return (select(partners)
          ..where((p) =>
              p.businessId.equals(businessId) &
              p.status.equals(PartnerStatus.active.value))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  // ── Transactions CRUD ───────────────────────────────────────────────

  Future<String> createTransaction({
    required String businessId,
    required String partnerId,
    required TransactionType type,
    required double amount,
    String? category,
    String? description,
    required DateTime date,
    String? time,
    String? attachmentPath,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: id,
        businessId: businessId,
        partnerId: partnerId,
        type: type.value,
        amount: amount,
        category: Value(category),
        description: Value(description),
        date: date,
        time: Value(time),
        attachmentPath: Value(attachmentPath),
        createdBy: createdBy,
        updatedBy: Value(createdBy),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        syncStatus: Value(SyncStatus.pendingCreate.value),
      ),
    );
    return id;
  }

  Future<bool> updateTransactionRecord(Transaction transaction) async {
    return update(transactions).replace(transaction);
  }

  Future<int> deleteTransaction(String id) async {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<Transaction?> getTransactionById(String id) async {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Transaction>> getTransactionsByBusinessId(
    String businessId,
  ) async {
    return (select(transactions)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByPartnerId(
    String partnerId,
  ) async {
    return (select(transactions)
          ..where((t) => t.partnerId.equals(partnerId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // ── Ledger Entries CRUD ─────────────────────────────────────────────

  Future<String> createLedgerEntry({
    required String partnerId,
    required String businessId,
    required String transactionId,
    required TransactionType type,
    required double amount,
    required double balance,
    String? description,
    required DateTime date,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(ledgerEntries).insert(
      LedgerEntriesCompanion.insert(
        id: id,
        partnerId: partnerId,
        businessId: businessId,
        transactionId: transactionId,
        type: type.value,
        amount: amount,
        balance: balance,
        description: Value(description),
        date: date,
        createdAt: Value(now),
      ),
    );
    return id;
  }

  Future<bool> updateLedgerEntryRecord(LedgerEntry entry) async {
    return update(ledgerEntries).replace(entry);
  }

  Future<int> deleteLedgerEntry(String id) async {
    return (delete(ledgerEntries)..where((l) => l.id.equals(id))).go();
  }

  Future<LedgerEntry?> getLedgerEntryById(String id) async {
    return (select(ledgerEntries)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<LedgerEntry>> getLedgerEntriesByPartnerId(
    String partnerId,
  ) async {
    return (select(ledgerEntries)
          ..where((l) => l.partnerId.equals(partnerId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  Future<List<LedgerEntry>> getLedgerEntriesByBusinessId(
    String businessId,
  ) async {
    return (select(ledgerEntries)
          ..where((l) => l.businessId.equals(businessId))
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
  }

  // ── Notifications CRUD ──────────────────────────────────────────────

  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? data,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await into(notifications).insert(
      NotificationsCompanion.insert(
        id: id,
        userId: userId,
        title: title,
        message: message,
        type: Value(type.value),
        isRead: const Value(false),
        data: Value(data),
        createdAt: Value(now),
      ),
    );
    return id;
  }

  Future<int> deleteNotification(String id) async {
    return (delete(notifications)..where((n) => n.id.equals(id))).go();
  }

  Future<int> markNotificationAsRead(String id) async {
    return (update(notifications)..where((n) => n.id.equals(id))).write(
      NotificationsCompanion(isRead: const Value(true)),
    );
  }

  Future<int> markAllNotificationsAsRead(String userId) async {
    return (update(notifications)
          ..where((n) => n.userId.equals(userId) & n.isRead.equals(false)))
        .write(
      NotificationsCompanion(isRead: const Value(true)),
    );
  }

  Future<List<Notification>> getNotificationsByUserId(String userId) async {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  Stream<List<Notification>> watchNotificationsByUserId(String userId) {
    return (select(notifications)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final count = notifications.id.count();
    final result = await (selectOnly(notifications)
          ..addColumns([count])
          ..where(notifications.userId.equals(userId) &
              notifications.isRead.equals(false)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  // ── Settings CRUD ───────────────────────────────────────────────────

  Future<String> setSetting({
    required String key,
    required String value,
    required String userId,
  }) async {
    final existing = await (select(settings)
          ..where((s) => s.key.equals(key) & s.userId.equals(userId)))
        .getSingleOrNull();

    final now = DateTime.now();

    if (existing != null) {
      await (update(settings)..where((s) => s.id.equals(existing.id))).write(
        SettingsCompanion(
          value: Value(value),
          updatedAt: Value(now),
        ),
      );
      return existing.id;
    }

    final id = _uuid.v4();
    await into(settings).insert(
      SettingsCompanion.insert(
        id: id,
        key: key,
        value: value,
        userId: userId,
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  Future<String?> getSetting(String key, String userId) async {
    final result = await (select(settings)
          ..where((s) => s.key.equals(key) & s.userId.equals(userId)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<List<Setting>> getAllSettingsByUserId(String userId) async {
    return (select(settings)..where((s) => s.userId.equals(userId))).get();
  }

  Stream<List<Setting>> watchAllSettingsByUserId(String userId) {
    return (select(settings)..where((s) => s.userId.equals(userId))).watch();
  }

  Future<int> deleteSetting(String id) async {
    return (delete(settings)..where((s) => s.id.equals(id))).go();
  }

  Future<int> deleteSettingsByUserId(String userId) async {
    return (delete(settings)..where((s) => s.userId.equals(userId))).go();
  }

  // ── Utility ─────────────────────────────────────────────────────────

  Future<void> deleteAllData() async {
    await transaction(() async {
      await delete(users).go();
      await delete(businesses).go();
      await delete(partners).go();
      await delete(transactions).go();
      await delete(ledgerEntries).go();
      await delete(notifications).go();
      await delete(settings).go();
    });
  }

  Future<void> deleteBusinessData(String businessId) async {
    await transaction(() async {
      await (delete(transactions)
            ..where((t) => t.businessId.equals(businessId)))
          .go();
      await (delete(ledgerEntries)
            ..where((l) => l.businessId.equals(businessId)))
          .go();
      await (delete(partners)
            ..where((p) => p.businessId.equals(businessId)))
          .go();
      await (delete(businesses)..where((b) => b.id.equals(businessId)))
          .go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      if (kIsWeb) {
        return NativeDatabase.memory();
      }
      return _openNativeDatabase();
    } catch (e) {
      return NativeDatabase.memory();
    }
  });
}

Future<QueryExecutor> _openNativeDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/partner_ledger_pro.sqlite';
  return NativeDatabaseHelper.openFile(path);
}
