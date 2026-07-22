import 'dart:convert';

import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/entities/partner.dart';
import '../models/entities/partner_approval.dart';
import '../models/entities/partner_update_request.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class PartnerApprovalRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  PartnerApprovalRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  PartnerUpdateRequest _fromUpdateRequestRow(Map<String, dynamic> row) {
    return PartnerUpdateRequest.fromMap({
      'id': row['id'] ?? '',
      'businessId': row['businessId'] ?? '',
      'partnerId': row['partnerId'] ?? '',
      'requestedByUserId': row['requestedByUserId'] ?? '',
      'requestedByEmail': row['requestedByEmail'] ?? '',
      'requestedByName': row['requestedByName'] ?? '',
      'proposedChanges': row['proposedChanges']?.toString() ?? '{}',
      'currentValues': row['currentValues']?.toString(),
      'reason': row['reason']?.toString(),
      'status': _sheets.parseInt(row['status']),
      'totalApprovers': _sheets.parseInt(row['totalApprovers']),
      'approvedCount': _sheets.parseInt(row['approvedCount']),
      'rejectedCount': _sheets.parseInt(row['rejectedCount']),
      'createdAt': row['createdAt']?.toString() ?? '',
      'updatedAt': row['updatedAt']?.toString() ?? '',
      'resolvedAt': row['resolvedAt']?.toString(),
    });
  }

  PartnerApproval _fromApprovalRow(Map<String, dynamic> row) {
    return PartnerApproval.fromMap({
      'id': row['id'] ?? '',
      'updateRequestId': row['updateRequestId'] ?? '',
      'partnerId': row['partnerId'] ?? '',
      'partnerName': row['partnerName'] ?? '',
      'partnerEmail': row['partnerEmail'] ?? '',
      'decision': _sheets.parseInt(row['decision']),
      'comment': row['comment']?.toString(),
      'createdAt': row['createdAt']?.toString() ?? '',
      'updatedAt': row['updatedAt']?.toString() ?? '',
      'decidedAt': row['decidedAt']?.toString(),
    });
  }

  // ── Create Update Request ──────────────────────────────────────────────

  Future<ApiResponse<PartnerUpdateRequest>> createUpdateRequest({
    required String businessId,
    required String partnerId,
    required Partner currentPartner,
    required Map<String, dynamic> proposedChanges,
    required String requestedByUserId,
    required String requestedByEmail,
    required String requestedByName,
    String? reason,
    required List<Partner> allActivePartners,
  }) async {
    final now = DateTime.now();
    final id = _sheets.generateId();

    // Compute current values for the changed fields only
    final currentMap = currentPartner.toMap();
    final currentValuesMap = <String, dynamic>{};
    for (final key in proposedChanges.keys) {
      if (currentMap.containsKey(key)) {
        currentValuesMap[key] = currentMap[key];
      }
    }

    // Count approvers: active partners excluding requester
    final approvers = allActivePartners
        .where((p) => p.email != requestedByEmail)
        .toList();

    final request = PartnerUpdateRequest(
      id: id,
      businessId: businessId,
      partnerId: partnerId,
      requestedByUserId: requestedByUserId,
      requestedByEmail: requestedByEmail,
      requestedByName: requestedByName,
      proposedChanges: jsonEncode(proposedChanges),
      currentValues: jsonEncode(currentValuesMap),
      reason: reason,
      status: UpdateRequestStatus.pending,
      totalApprovers: approvers.length,
      approvedCount: 0,
      rejectedCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetUpdateRequests,
        request.toMap(),
      );
      if (!result.success) {
        return ApiResponse.error(message: result.message);
      }
    }

    // Create approval records for each approver
    final approvals = <PartnerApproval>[];
    for (final partner in approvers) {
      final approval = PartnerApproval(
        id: _sheets.generateId(),
        updateRequestId: id,
        partnerId: partner.id,
        partnerName: partner.name,
        partnerEmail: partner.email ?? '',
        decision: ApprovalDecision.pending,
        createdAt: now,
        updatedAt: now,
      );
      approvals.add(approval);

      if (_sheets.isConfigured) {
        await _sheets.create(
          SheetsConfig.sheetApprovals,
          approval.toMap(),
        );
      }
    }

    // Cache locally
    await _cacheUpdateRequest(request);
    await _cacheApprovals(id, approvals);

    return ApiResponse.success(data: request);
  }

  // ── Get Pending Requests for a Business ────────────────────────────────

  Future<ApiResponse<List<PartnerUpdateRequest>>> getPendingRequests({
    required String businessId,
  }) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getAll(SheetsConfig.sheetUpdateRequests);
      if (response.success && response.data != null) {
        final requests = response.data!
            .map(_fromUpdateRequestRow)
            .where((r) =>
                r.businessId == businessId &&
                r.status == UpdateRequestStatus.pending)
            .toList();
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ApiResponse.success(data: requests);
      }
    }

    final cached = await _getCachedUpdateRequests();
    final filtered = cached
        .where((r) =>
            r.businessId == businessId &&
            r.status == UpdateRequestStatus.pending)
        .toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ApiResponse.success(data: filtered);
  }

  // ── Get Requests Where I Need to Approve ───────────────────────────────

  Future<ApiResponse<List<PartnerUpdateRequest>>> getMyPendingApprovals({
    required String myPartnerId,
    required String businessId,
  }) async {
    if (_sheets.isConfigured) {
      final reqResponse = await _sheets.getAll(SheetsConfig.sheetUpdateRequests);
      final approvalResponse = await _sheets.getAll(SheetsConfig.sheetApprovals);

      if (reqResponse.success && reqResponse.data != null) {
        final allRequests = reqResponse.data!.map(_fromUpdateRequestRow).toList();

        // Find request IDs where I have a pending approval
        final myPendingApprovalIds = <String>{};
        if (approvalResponse.success && approvalResponse.data != null) {
          for (final row in approvalResponse.data!) {
            final approval = _fromApprovalRow(row);
            if (approval.partnerId == myPartnerId &&
                approval.isPending &&
                allRequests.any((r) =>
                    r.id == approval.updateRequestId &&
                    r.status == UpdateRequestStatus.pending)) {
              myPendingApprovalIds.add(approval.updateRequestId);
            }
          }
        }

        final myPending = allRequests
            .where((r) =>
                r.businessId == businessId &&
                r.status == UpdateRequestStatus.pending &&
                myPendingApprovalIds.contains(r.id))
            .toList();
        myPending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ApiResponse.success(data: myPending);
      }
    }

    return ApiResponse.success(data: <PartnerUpdateRequest>[]);
  }

  // ── Get Approvals for a Request ────────────────────────────────────────

  Future<ApiResponse<List<PartnerApproval>>> getApprovalsForRequest({
    required String updateRequestId,
  }) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getAll(SheetsConfig.sheetApprovals);
      if (response.success && response.data != null) {
        final approvals = response.data!
            .map(_fromApprovalRow)
            .where((a) => a.updateRequestId == updateRequestId)
            .toList();
        approvals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return ApiResponse.success(data: approvals);
      }
    }

    final cached = await _getCachedApprovals(updateRequestId);
    return ApiResponse.success(data: cached);
  }

  // ── Approve ────────────────────────────────────────────────────────────

  Future<ApiResponse<void>> approve({
    required String updateRequestId,
    required String approvalId,
    String? comment,
  }) async {
    final now = DateTime.now();

    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetApprovals,
        approvalId,
        {
          'decision': ApprovalDecision.approved.value,
          'comment': comment,
          'updatedAt': now.toIso8601String(),
          'decidedAt': now.toIso8601String(),
        },
      );
      if (!result.success) {
        return ApiResponse.error(message: result.message);
      }

      // Update the request counts
      final reqResponse =
          await _sheets.getById(SheetsConfig.sheetUpdateRequests, updateRequestId);
      if (reqResponse.success && reqResponse.data != null) {
        final newApprovedCount =
            (_sheets.parseInt(reqResponse.data!['approvedCount'])) + 1;
        final totalApprovers =
            _sheets.parseInt(reqResponse.data!['totalApprovers']);

        await _sheets.update(
          SheetsConfig.sheetUpdateRequests,
          updateRequestId,
          {
            'approvedCount': newApprovedCount,
            'updatedAt': now.toIso8601String(),
          },
        );

        // Check if fully approved
        if (newApprovedCount >= totalApprovers && totalApprovers > 0) {
          await _sheets.update(
            SheetsConfig.sheetUpdateRequests,
            updateRequestId,
            {
              'status': UpdateRequestStatus.approved.value,
              'resolvedAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            },
          );
        }
      }
    }

    return ApiResponse.success(data: null);
  }

  // ── Reject ─────────────────────────────────────────────────────────────

  Future<ApiResponse<void>> reject({
    required String updateRequestId,
    required String approvalId,
    String? comment,
  }) async {
    final now = DateTime.now();

    if (_sheets.isConfigured) {
      await _sheets.update(
        SheetsConfig.sheetApprovals,
        approvalId,
        {
          'decision': ApprovalDecision.rejected.value,
          'comment': comment,
          'updatedAt': now.toIso8601String(),
          'decidedAt': now.toIso8601String(),
        },
      );

      // Mark request as rejected (any rejection = rejected)
      final reqResponse =
          await _sheets.getById(SheetsConfig.sheetUpdateRequests, updateRequestId);
      final currentRejected = reqResponse.success && reqResponse.data != null
          ? _sheets.parseInt(reqResponse.data!['rejectedCount'])
          : 0;

      await _sheets.update(
        SheetsConfig.sheetUpdateRequests,
        updateRequestId,
        {
          'rejectedCount': currentRejected + 1,
          'status': UpdateRequestStatus.rejected.value,
          'resolvedAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
    }

    return ApiResponse.success(data: null);
  }

  // ── Get Request By ID ──────────────────────────────────────────────────

  Future<ApiResponse<PartnerUpdateRequest>> getRequestById(String id) async {
    if (_sheets.isConfigured) {
      final response = await _sheets.getById(SheetsConfig.sheetUpdateRequests, id);
      if (response.success && response.data != null) {
        return ApiResponse.success(data: _fromUpdateRequestRow(response.data!));
      }
    }

    final cached = await _getCachedUpdateRequests();
    try {
      final req = cached.firstWhere((r) => r.id == id);
      return ApiResponse.success(data: req);
    } catch (_) {
      return ApiResponse.error(message: 'Update request not found');
    }
  }

  // ── Caching ────────────────────────────────────────────────────────────

  Future<void> _cacheUpdateRequest(PartnerUpdateRequest request) async {
    final cached = await _getCachedUpdateRequests();
    cached.removeWhere((r) => r.id == request.id);
    cached.add(request);
    final json = cached.map((r) => r.toMap()).toList();
    await _storage.setPref('cached_update_requests', jsonEncode(json));
  }

  Future<List<PartnerUpdateRequest>> _getCachedUpdateRequests() async {
    final data = await _storage.getPref('cached_update_requests');
    if (data == null) return [];
    try {
      final list = (jsonDecode(data.toString()) as List<dynamic>);
      return list
          .map((e) => PartnerUpdateRequest.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheApprovals(
      String requestId, List<PartnerApproval> approvals) async {
    final key = 'cached_approvals_$requestId';
    final json = approvals.map((a) => a.toMap()).toList();
    await _storage.setPref(key, jsonEncode(json));
  }

  Future<List<PartnerApproval>> _getCachedApprovals(String requestId) async {
    final data = await _storage.getPref('cached_approvals_$requestId');
    if (data == null) return [];
    try {
      final list = (jsonDecode(data.toString()) as List<dynamic>);
      return list
          .map((e) => PartnerApproval.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
