import 'dart:math';

import 'package:crypto/crypto.dart';

import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/entities/partner_invite.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class InviteRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  InviteRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  PartnerInvite _fromRow(Map<String, dynamic> row) {
    return PartnerInvite(
      id: '${row['id'] ?? ''}',
      businessId: '${row['businessId'] ?? ''}',
      businessName: '${row['businessName'] ?? ''}',
      createdByUserId: '${row['createdByUserId'] ?? ''}',
      createdByEmail: '${row['createdByEmail'] ?? ''}',
      token: '${row['token'] ?? ''}',
      status: InviteStatus.fromValue(
        row['status'] is int ? row['status'] as int : 0,
      ),
      acceptedByUserId: row['acceptedByUserId']?.toString(),
      acceptedByEmail: row['acceptedByEmail']?.toString(),
      acceptedByPartnerId: row['acceptedByPartnerId']?.toString(),
      expiresAt: _parseDate(row['expiresAt']?.toString()),
      createdAt: _parseDate(row['createdAt']?.toString()),
      updatedAt: _parseDate(row['updatedAt']?.toString()),
    );
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> _toRow(PartnerInvite invite) {
    return {
      'id': invite.id,
      'businessId': invite.businessId,
      'businessName': invite.businessName,
      'createdByUserId': invite.createdByUserId,
      'createdByEmail': invite.createdByEmail,
      'token': invite.token,
      'status': invite.status.value,
      'acceptedByUserId': invite.acceptedByUserId,
      'acceptedByEmail': invite.acceptedByEmail,
      'acceptedByPartnerId': invite.acceptedByPartnerId,
      'expiresAt': invite.expiresAt.toIso8601String(),
      'createdAt': invite.createdAt.toIso8601String(),
      'updatedAt': invite.updatedAt.toIso8601String(),
    };
  }

  String generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return sha256.convert(bytes).toString().substring(0, 24);
  }

  Future<ApiResponse<PartnerInvite>> create({
    required String businessId,
    required String businessName,
    required String createdByUserId,
    required String createdByEmail,
    int expiryHours = 48,
  }) async {
    final now = DateTime.now();
    final invite = PartnerInvite(
      id: _sheets.generateId(),
      businessId: businessId,
      businessName: businessName,
      createdByUserId: createdByUserId,
      createdByEmail: createdByEmail,
      token: generateToken(),
      status: InviteStatus.active,
      expiresAt: now.add(Duration(hours: expiryHours)),
      createdAt: now,
      updatedAt: now,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetPartnerInvites,
        _toRow(invite),
      );
      if (result.success) {
        return ApiResponse.success(data: invite);
      }
      return ApiResponse<PartnerInvite>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCachedInvites();
    cached.add(invite);
    await _cacheInvites(cached);
    return ApiResponse.success(data: invite);
  }

  Future<ApiResponse<PartnerInvite>> getByToken(String token) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getByField(
        SheetsConfig.sheetPartnerInvites,
        'token',
        token,
      );
      if (response.success && response.data != null) {
        final rows = response.data!;
        if (rows.isNotEmpty) {
          return ApiResponse.success(data: _fromRow(rows.first));
        }
      }
    }

    final cached = await _getCachedInvites();
    try {
      final match = cached.firstWhere((i) => i.token == token);
      return ApiResponse.success(data: match);
    } catch (_) {
      return ApiResponse.error(message: 'Invalid invite token');
    }
  }

  Future<ApiResponse<PartnerInvite>> getById(String id) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getById(SheetsConfig.sheetPartnerInvites, id);
      if (response.success && response.data != null) {
        return ApiResponse.success(data: _fromRow(response.data!));
      }
    }

    final cached = await _getCachedInvites();
    try {
      final match = cached.firstWhere((i) => i.id == id);
      return ApiResponse.success(data: match);
    } catch (_) {
      return ApiResponse.error(message: 'Invite not found');
    }
  }

  Future<ApiResponse<List<PartnerInvite>>> getByBusiness(String businessId) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getByField(
        SheetsConfig.sheetPartnerInvites,
        'businessId',
        businessId,
      );
      if (response.success && response.data != null) {
        final invites = response.data!.map(_fromRow).toList();
        invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ApiResponse.success(data: invites);
      }
    }

    final cached = await _getCachedInvites();
    final filtered = cached.where((i) => i.businessId == businessId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ApiResponse.success(data: filtered);
  }

  Future<ApiResponse<PartnerInvite>> accept({
    required String inviteId,
    required String acceptedByUserId,
    required String acceptedByEmail,
    required String acceptedByPartnerId,
  }) async {
    final existing = await getById(inviteId);
    if (!existing.success || existing.data == null) {
      return ApiResponse.error(message: 'Invite not found');
    }

    final invite = existing.data!;
    if (!invite.canBeAccepted) {
      return ApiResponse.error(message: 'This invite has expired or is no longer active');
    }

    final updated = invite.copyWith(
      status: InviteStatus.accepted,
      acceptedByUserId: acceptedByUserId,
      acceptedByEmail: acceptedByEmail,
      acceptedByPartnerId: acceptedByPartnerId,
      updatedAt: DateTime.now(),
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetPartnerInvites,
        inviteId,
        _toRow(updated),
      );
      if (result.success) {
        return ApiResponse.success(data: updated);
      }
      return ApiResponse<PartnerInvite>.error(
        message: result.message,
        error: result.error,
      );
    }

    final cached = await _getCachedInvites();
    final index = cached.indexWhere((i) => i.id == inviteId);
    if (index >= 0) cached[index] = updated;
    await _cacheInvites(cached);
    return ApiResponse.success(data: updated);
  }

  Future<ApiResponse<PartnerInvite>> revoke(String inviteId) async {
    final existing = await getById(inviteId);
    if (!existing.success || existing.data == null) {
      return ApiResponse.error(message: 'Invite not found');
    }

    final updated = existing.data!.copyWith(
      status: InviteStatus.revoked,
      updatedAt: DateTime.now(),
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetPartnerInvites,
        inviteId,
        _toRow(updated),
      );
      if (result.success) {
        return ApiResponse.success(data: updated);
      }
      return ApiResponse<PartnerInvite>.error(message: result.message);
    }

    final cached = await _getCachedInvites();
    final index = cached.indexWhere((i) => i.id == inviteId);
    if (index >= 0) cached[index] = updated;
    await _cacheInvites(cached);
    return ApiResponse.success(data: updated);
  }

  Future<void> _cacheInvites(List<PartnerInvite> invites) async {
    final json = invites.map((i) => i.toMap()).toList();
    await _storage.setPref('cached_invites', json.toString());
  }

  Future<List<PartnerInvite>> _getCachedInvites() async {
    final data = await _storage.getPref('cached_invites');
    if (data == null) return [];
    try {
      final list = (data as List<dynamic>);
      return list
          .map((e) => PartnerInvite.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
