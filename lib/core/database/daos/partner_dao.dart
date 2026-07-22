import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/partners_table.dart';
import '../enums/database_enums.dart';

part 'partner_dao.g.dart';

@DriftAccessor(tables: [Partners])
class PartnerDao extends DatabaseAccessor<AppDatabase> with _$PartnerDaoMixin {
  PartnerDao(super.db);

  Future<Partner> insertPartner(PartnersCompanion entry) async {
    await into(partners).insert(entry);
    return (select(partners)..where((p) => p.id.equals(entry.id.value)))
        .getSingle();
  }

  Future<bool> updatePartner(PartnersCompanion entry) async {
    return update(partners).replace(entry);
  }

  Future<int> deletePartner(String id) async {
    return (delete(partners)..where((p) => p.id.equals(id))).go();
  }

  Future<Partner?> getPartnerById(String id) async {
    return (select(partners)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<Partner?> watchPartnerById(String id) {
    return (select(partners)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<List<Partner>> getAllPartners() async {
    return (select(partners)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Partner>> watchAllPartners() {
    return (select(partners)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<List<Partner>> getPartnersByBusinessId(String businessId) async {
    return (select(partners)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Partner>> watchPartnersByBusinessId(String businessId) {
    return (select(partners)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<List<Partner>> getPartnersByBusinessAndStatus(
    String businessId,
    PartnerStatus status,
  ) async {
    return (select(partners)
          ..where((p) =>
              p.businessId.equals(businessId) &
              p.status.equals(status.value))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Partner>> watchPartnersByBusinessAndStatus(
    String businessId,
    PartnerStatus status,
  ) {
    return (select(partners)
          ..where((p) =>
              p.businessId.equals(businessId) &
              p.status.equals(status.value))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<List<Partner>> getActivePartnersByBusinessId(
    String businessId,
  ) async {
    return getPartnersByBusinessAndStatus(businessId, PartnerStatus.active);
  }

  Stream<List<Partner>> watchActivePartnersByBusinessId(
    String businessId,
  ) {
    return watchPartnersByBusinessAndStatus(businessId, PartnerStatus.active);
  }

  Future<List<Partner>> getPartnersByStatus(PartnerStatus status) async {
    return (select(partners)
          ..where((p) => p.status.equals(status.value))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Partner>> watchPartnersByStatus(PartnerStatus status) {
    return (select(partners)
          ..where((p) => p.status.equals(status.value))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<List<Partner>> searchPartnersByName(
    String businessId,
    String query,
  ) async {
    return (select(partners)
          ..where((p) =>
              p.businessId.equals(businessId) &
              (p.name.like('%$query%') | p.email.like('%$query%')))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  // ── Capital & Ownership ──────────────────────────────────────────────

  Future<double> getTotalCapitalByBusiness(String businessId) async {
    final sum = partners.capital.sum();
    final result = await (selectOnly(partners)
          ..addColumns([sum])
          ..where(partners.businessId.equals(businessId) &
              partners.status.equals(PartnerStatus.active.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalOwnershipByBusiness(String businessId) async {
    final sum = partners.ownershipPercentage.sum();
    final result = await (selectOnly(partners)
          ..addColumns([sum])
          ..where(partners.businessId.equals(businessId) &
              partners.status.equals(PartnerStatus.active.value)))
        .getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getCapitalByPartner(String partnerId) async {
    final result = await (select(partners)
          ..where((p) => p.id.equals(partnerId)))
        .getSingleOrNull();
    return result?.capital ?? 0.0;
  }

  Future<double> getOwnershipPercentageByPartner(String partnerId) async {
    final result = await (select(partners)
          ..where((p) => p.id.equals(partnerId)))
        .getSingleOrNull();
    return result?.ownershipPercentage ?? 0.0;
  }

  Future<int> getPartnerCountByBusiness(String businessId) async {
    final count = partners.id.count();
    final result = await (selectOnly(partners)
          ..addColumns([count])
          ..where(partners.businessId.equals(businessId)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getActivePartnerCountByBusiness(String businessId) async {
    final count = partners.id.count();
    final result = await (selectOnly(partners)
          ..addColumns([count])
          ..where(partners.businessId.equals(businessId) &
              partners.status.equals(PartnerStatus.active.value)))
        .getSingle();
    return result.read(count) ?? 0;
  }

  Future<Map<String, double>> getCapitalSummaryByBusiness(
    String businessId,
  ) async {
    final activePartners = await (select(partners)
          ..where((p) =>
              p.businessId.equals(businessId) &
              p.status.equals(PartnerStatus.active.value))
          ..orderBy([(p) => OrderingTerm.desc(p.capital)]))
        .get();

    final Map<String, double> summary = {};
    for (final partner in activePartners) {
      summary[partner.name] = partner.capital;
    }
    return summary;
  }

  Future<void> updatePartnerStatus(
    String partnerId,
    PartnerStatus status,
  ) async {
    final now = DateTime.now();
    await (update(partners)..where((p) => p.id.equals(partnerId)))
        .replace(PartnersCompanion(
      id: Value(partnerId),
      status: Value(status.value),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateCapital(
    String partnerId,
    double capital,
  ) async {
    final now = DateTime.now();
    await (update(partners)..where((p) => p.id.equals(partnerId)))
        .replace(PartnersCompanion(
      id: Value(partnerId),
      capital: Value(capital),
      updatedAt: Value(now),
    ));
  }

  Future<void> updateOwnershipPercentage(
    String partnerId,
    double percentage,
  ) async {
    final now = DateTime.now();
    await (update(partners)..where((p) => p.id.equals(partnerId)))
        .replace(PartnersCompanion(
      id: Value(partnerId),
      ownershipPercentage: Value(percentage),
      updatedAt: Value(now),
    ));
  }

  Future<void> setActiveStatus(String partnerId, bool isActive) async {
    final now = DateTime.now();
    await (update(partners)..where((p) => p.id.equals(partnerId)))
        .replace(PartnersCompanion(
      id: Value(partnerId),
      isActive: Value(isActive),
      updatedAt: Value(now),
    ));
  }

  Future<int> deletePartnersByBusinessId(String businessId) async {
    return (delete(partners)
          ..where((p) => p.businessId.equals(businessId)))
        .go();
  }
}
