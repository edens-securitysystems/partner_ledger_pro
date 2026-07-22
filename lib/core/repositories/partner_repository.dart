import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/dto/partner_dto.dart';
import '../models/entities/partner.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class PartnerRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  PartnerRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  Partner _fromRow(Map<String, dynamic> row) {
    return Partner(
      id: '${row['id'] ?? ''}',
      businessId: '${row['businessId'] ?? ''}',
      name: '${row['name'] ?? ''}',
      email: row['email']?.toString(),
      phone: row['phone']?.toString(),
      photo: row['photo']?.toString(),
      capital: _sheets.parseDouble(row['capital']),
      ownershipPercentage: _sheets.parseDouble(row['ownershipPercentage']),
      joiningDate: _sheets.parseDate(row['joiningDate']?.toString()),
      status: PartnerStatus.fromValue(_sheets.parseInt(row['status'])),
      description: row['description']?.toString(),
      createdAt: _sheets.parseDate(row['createdAt']?.toString()),
      updatedAt: _sheets.parseDate(row['updatedAt']?.toString()),
      isActive: _sheets.parseBool(row['isActive']),
    );
  }

  Map<String, dynamic> _toRow(Partner partner) {
    return {
      'id': partner.id,
      'businessId': partner.businessId,
      'name': partner.name,
      'email': partner.email,
      'phone': partner.phone,
      'photo': partner.photo,
      'capital': partner.capital,
      'ownershipPercentage': partner.ownershipPercentage,
      'joiningDate': partner.joiningDate.toIso8601String(),
      'status': partner.status.value,
      'description': partner.description,
      'createdAt': partner.createdAt.toIso8601String(),
      'updatedAt': partner.updatedAt.toIso8601String(),
      'isActive': partner.isActive,
    };
  }

  Future<ApiResponse<List<Partner>>> getAll({
    String? businessId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetPartners);

    if (response.success && response.data != null) {
      var partners = response.data!.map(_fromRow).toList();

      if (businessId != null) {
        partners = partners.where((p) => p.businessId == businessId).toList();
      }

      await _cachePartners(partners);

      final start = (page - 1) * limit;
      final end = start + limit;
      if (start < partners.length) {
        final paginated = partners.sublist(
          start,
          end > partners.length ? partners.length : end,
        );
        return ApiResponse.success(data: paginated);
      }

      return ApiResponse.success(data: partners);
    }

    return ApiResponse.success(data: await _getCachedPartners());
  }

  Future<ApiResponse<Partner>> getById(String id) async {
    final response = await _sheets.getById(SheetsConfig.sheetPartners, id);

    if (response.success && response.data != null) {
      final partner = _fromRow(response.data!);
      return ApiResponse.success(data: partner);
    }

    return ApiResponse.error(message: 'Partner not found');
  }

  Future<ApiResponse<Partner>> create(CreatePartnerRequest request) async {
    final now = DateTime.now();
    final partner = Partner(
      id: _sheets.generateId(),
      businessId: '',
      name: request.name,
      email: request.email,
      phone: request.phone,
      photo: request.photo,
      capital: request.capital,
      ownershipPercentage: request.ownershipPercentage,
      joiningDate: request.joiningDate,
      status: request.status,
      description: request.description,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetPartners,
        _toRow(partner),
      );

      if (result.success) {
        return ApiResponse.success(data: partner);
      }

      return ApiResponse<Partner>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCachedPartners();
    cached.add(partner);
    await _cachePartners(cached);

    return ApiResponse.success(data: partner);
  }

  Future<ApiResponse<Partner>> update(String id, UpdatePartnerRequest request) async {
    final existing = await getById(id);
    if (!existing.success || existing.data == null) {
      return ApiResponse.error(message: 'Partner not found');
    }

    final updated = existing.data!.copyWith(
      name: request.name,
      email: request.email,
      phone: request.phone,
      photo: request.photo,
      capital: request.capital,
      ownershipPercentage: request.ownershipPercentage,
      joiningDate: request.joiningDate,
      status: request.status,
      description: request.description,
      isActive: request.isActive,
      updatedAt: DateTime.now(),
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetPartners,
        id,
        _toRow(updated),
      );

      if (result.success) {
        return ApiResponse.success(data: updated);
      }

      return ApiResponse<Partner>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCachedPartners();
    final index = cached.indexWhere((p) => p.id == id);
    if (index >= 0) cached[index] = updated;
    await _cachePartners(cached);

    return ApiResponse.success(data: updated);
  }

  Future<ApiResponse<void>> delete(String id) async {
    if (_sheets.isConfigured) {
      final result = await _sheets.delete(SheetsConfig.sheetPartners, id);
      if (result.success) {
        return ApiResponse.success(data: null);
      }
      return ApiResponse.error(message: result.message);
    }

    final cached = await _getCachedPartners();
    cached.removeWhere((p) => p.id == id);
    await _cachePartners(cached);

    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<List<Partner>>> search(String query) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.search(SheetsConfig.sheetPartners, query);
      if (response.success && response.data != null) {
        final partners = response.data!.map(_fromRow).toList();
        return ApiResponse.success(data: partners);
      }
    }

    final cached = await _getCachedPartners();
    final filtered = cached.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        (p.email?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
    return ApiResponse.success(data: filtered);
  }

  Future<ApiResponse<List<Partner>>> filterByBusiness(String businessId) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getByField(
        SheetsConfig.sheetPartners,
        'businessId',
        businessId,
      );
      if (response.success && response.data != null) {
        final partners = response.data!.map(_fromRow).toList();
        return ApiResponse.success(data: partners);
      }
    }

    final cached = await _getCachedPartners();
    return ApiResponse.success(
      data: cached.where((p) => p.businessId == businessId).toList(),
    );
  }

  Future<ApiResponse<List<Partner>>> filterByStatus(PartnerStatus status) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getAll(SheetsConfig.sheetPartners);
      if (response.success && response.data != null) {
        final partners = response.data!
            .map(_fromRow)
            .where((p) => p.status == status)
            .toList();
        return ApiResponse.success(data: partners);
      }
    }

    final cached = await _getCachedPartners();
    return ApiResponse.success(
      data: cached.where((p) => p.status == status).toList(),
    );
  }

  Future<List<Partner>> _getCachedPartners() async {
    final data = await _storage.getPref('cached_partners');
    if (data == null) return [];
    try {
      final list = (data as List<dynamic>);
      return list
          .map((e) => Partner.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cachePartners(List<Partner> partners) async {
    final json = partners.map((p) => p.toMap()).toList();
    await _storage.setPref('cached_partners', json.toString());
  }
}
