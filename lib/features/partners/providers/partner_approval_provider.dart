import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/partner_dto.dart';
import '../../../core/models/entities/partner.dart';
import '../../../core/models/entities/partner_approval.dart';
import '../../../core/models/entities/partner_update_request.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/partner_approval_repository.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/partner_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class PartnerApprovalState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<PartnerUpdateRequest> pendingRequests;
  final List<PartnerUpdateRequest> myPendingApprovals;
  final PartnerUpdateRequest? selectedRequest;
  final List<PartnerApproval> currentApprovals;
  final String? successMessage;

  const PartnerApprovalState({
    this.isLoading = false,
    this.error,
    this.pendingRequests = const [],
    this.myPendingApprovals = const [],
    this.selectedRequest,
    this.currentApprovals = const [],
    this.successMessage,
  });

  const PartnerApprovalState.initial() : this();

  int get pendingCount => myPendingApprovals.length;

  PartnerApprovalState copyWith({
    bool? isLoading,
    String? error,
    List<PartnerUpdateRequest>? pendingRequests,
    List<PartnerUpdateRequest>? myPendingApprovals,
    PartnerUpdateRequest? selectedRequest,
    List<PartnerApproval>? currentApprovals,
    String? successMessage,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PartnerApprovalState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      myPendingApprovals: myPendingApprovals ?? this.myPendingApprovals,
      selectedRequest:
          clearSelected ? null : (selectedRequest ?? this.selectedRequest),
      currentApprovals: currentApprovals ?? this.currentApprovals,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        pendingRequests,
        myPendingApprovals,
        selectedRequest,
        currentApprovals,
        successMessage,
      ];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PartnerApprovalNotifier extends StateNotifier<PartnerApprovalState> {
  final PartnerApprovalRepository _approvalRepo;
  final PartnerRepository _partnerRepo;
  final NotificationRepository _notificationRepo;

  PartnerApprovalNotifier(
    this._approvalRepo,
    this._partnerRepo,
    this._notificationRepo,
  ) : super(const PartnerApprovalState.initial());

  // ── Submit an update request for approval ──────────────────────────────

  Future<bool> submitUpdateRequest({
    required String businessId,
    required String partnerId,
    required Partner currentPartner,
    required Map<String, dynamic> proposedChanges,
    required String currentUserId,
    required String currentUserEmail,
    required String currentUserName,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null, clearSuccess: true);

    try {
      // Fetch all active partners for this business
      final partnersResponse = await _partnerRepo.getAll(businessId: businessId);
      final allPartners = partnersResponse.success && partnersResponse.data != null
          ? partnersResponse.data!
          : <Partner>[];
      final activePartners =
          allPartners.where((p) => p.isStatusActive && p.isActive).toList();

      if (activePartners.length < 2) {
        state = state.copyWith(
          isLoading: false,
          error: 'At least 2 active partners are required for the approval workflow',
        );
        return false;
      }

      final response = await _approvalRepo.createUpdateRequest(
        businessId: businessId,
        partnerId: partnerId,
        currentPartner: currentPartner,
        proposedChanges: proposedChanges,
        requestedByUserId: currentUserId,
        requestedByEmail: currentUserEmail,
        requestedByName: currentUserName,
        reason: reason,
        allActivePartners: activePartners,
      );

      if (!response.success || response.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }

      final request = response.data!;

      // Send notifications to all approvers
      final approvers = activePartners
          .where((p) => p.email != currentUserEmail)
          .toList();

      for (final approver in approvers) {
        await _notificationRepo.create(
          userId: approver.email ?? approver.id,
          title: 'Partner Update Requires Approval',
          message:
              '$currentUserName has proposed changes to ${currentPartner.name}. '
              'Please review and approve.',
          type: NotificationType.partner,
          referenceId: request.id,
          referenceType: 'partner_update_request',
        );
      }

      // Auto-approve for the requester
      // Since the request needs approval from others only, we don't need self-approval

      state = state.copyWith(
        isLoading: false,
        pendingRequests: [...state.pendingRequests, request],
        successMessage: 'Update request submitted for approval',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit update request: ${e.toString()}',
      );
      return false;
    }
  }

  // ── Fetch pending requests for the business ────────────────────────────

  Future<void> fetchPendingRequests(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _approvalRepo.getPendingRequests(
        businessId: businessId,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          pendingRequests: response.data!,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Fetch requests where I need to approve ─────────────────────────────

  Future<void> fetchMyPendingApprovals({
    required String myPartnerId,
    required String businessId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _approvalRepo.getMyPendingApprovals(
        myPartnerId: myPartnerId,
        businessId: businessId,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          myPendingApprovals: response.data!,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Select a request to view details ───────────────────────────────────

  Future<void> selectRequest(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reqResponse = await _approvalRepo.getRequestById(requestId);
      final approvalsResponse = await _approvalRepo.getApprovalsForRequest(
        updateRequestId: requestId,
      );

      state = state.copyWith(
        isLoading: false,
        selectedRequest: reqResponse.data,
        currentApprovals:
            approvalsResponse.success ? (approvalsResponse.data ?? []) : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Approve a request ──────────────────────────────────────────────────

  Future<bool> approveRequest({
    required String updateRequestId,
    required String approvalId,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _approvalRepo.approve(
        updateRequestId: updateRequestId,
        approvalId: approvalId,
        comment: comment,
      );

      if (!response.success) {
        state = state.copyWith(isLoading: false, error: response.message);
        return false;
      }

      // Notify the requester
      final reqResponse = await _approvalRepo.getRequestById(updateRequestId);
      if (reqResponse.success && reqResponse.data != null) {
        final request = reqResponse.data!;
        await _notificationRepo.create(
          userId: request.requestedByEmail,
          title: 'Update Request Approved',
          message:
              'Your partner update request has been approved by a partner.',
          type: NotificationType.partner,
          referenceId: updateRequestId,
          referenceType: 'partner_update_request',
        );

        // If fully approved, apply the changes
        if (request.isFullyApproved) {
          await _applyApprovedChanges(request);
        }
      }

      // Refresh approvals list
      await selectRequest(updateRequestId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Request approved successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to approve: ${e.toString()}',
      );
      return false;
    }
  }

  // ── Reject a request ───────────────────────────────────────────────────

  Future<bool> rejectRequest({
    required String updateRequestId,
    required String approvalId,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _approvalRepo.reject(
        updateRequestId: updateRequestId,
        approvalId: approvalId,
        comment: comment,
      );

      if (!response.success) {
        state = state.copyWith(isLoading: false, error: response.message);
        return false;
      }

      // Notify the requester
      final reqResponse = await _approvalRepo.getRequestById(updateRequestId);
      if (reqResponse.success && reqResponse.data != null) {
        final request = reqResponse.data!;
        await _notificationRepo.create(
          userId: request.requestedByEmail,
          title: 'Update Request Rejected',
          message: comment != null && comment.isNotEmpty
              ? 'Your partner update request was rejected. Reason: $comment'
              : 'Your partner update request has been rejected.',
          type: NotificationType.partner,
          referenceId: updateRequestId,
          referenceType: 'partner_update_request',
        );
      }

      // Refresh approvals list
      await selectRequest(updateRequestId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Request rejected',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reject: ${e.toString()}',
      );
      return false;
    }
  }

  // ── Apply approved changes to partner ──────────────────────────────────

  Future<void> _applyApprovedChanges(PartnerUpdateRequest request) async {
    try {
      final changes = request.proposedChangesMap;
      final updateMap = <String, dynamic>{};

      // Map proposed changes to UpdatePartnerRequest fields
      if (changes.containsKey('name')) updateMap['name'] = changes['name'];
      if (changes.containsKey('email')) updateMap['email'] = changes['email'];
      if (changes.containsKey('phone')) updateMap['phone'] = changes['phone'];
      if (changes.containsKey('capital')) {
        updateMap['capital'] = (changes['capital'] as num?)?.toDouble();
      }
      if (changes.containsKey('ownershipPercentage')) {
        updateMap['ownershipPercentage'] =
            (changes['ownershipPercentage'] as num?)?.toDouble();
      }
      if (changes.containsKey('status')) {
        updateMap['status'] =
            PartnerStatus.fromValue(changes['status'] as int);
      }
      if (changes.containsKey('description')) {
        updateMap['description'] = changes['description'];
      }
      if (changes.containsKey('joiningDate')) {
        updateMap['joiningDate'] = DateTime.tryParse('${changes['joiningDate']}');
      }

      final partnerDto = UpdatePartnerRequest(
        name: updateMap['name'] as String?,
        email: updateMap['email'] as String?,
        phone: updateMap['phone'] as String?,
        capital: updateMap['capital'] as double?,
        ownershipPercentage: updateMap['ownershipPercentage'] as double?,
        status: updateMap['status'] as PartnerStatus?,
        description: updateMap['description'] as String?,
        joiningDate: updateMap['joiningDate'] as DateTime?,
      );

      final result = await _partnerRepo.update(request.partnerId, partnerDto);

      if (result.success) {
        // Notify all partners that changes have been applied
        final reqResponse = await _approvalRepo.getRequestById(request.id);
        if (reqResponse.success && reqResponse.data != null) {
          final req = reqResponse.data!;
          final partnersResponse =
              await _partnerRepo.getAll(businessId: req.businessId);
          if (partnersResponse.success && partnersResponse.data != null) {
            for (final partner in partnersResponse.data!) {
              if (partner.email != null && partner.email != req.requestedByEmail) {
                await _notificationRepo.create(
                  userId: partner.email!,
                  title: 'Partner Changes Applied',
                  message:
                      'Changes to partner data have been applied after full approval.',
                  type: NotificationType.partner,
                  referenceId: req.partnerId,
                  referenceType: 'partner',
                );
              }
            }
          }
        }
      }
    } catch (e) {
      // Log error but don't fail the approval flow
      state = state.copyWith(error: 'Changes approved but failed to apply: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final partnerApprovalProvider =
    StateNotifierProvider<PartnerApprovalNotifier, PartnerApprovalState>((ref) {
  final approvalRepo = ref.watch(partnerApprovalRepositoryProvider);
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return PartnerApprovalNotifier(approvalRepo, partnerRepo, notificationRepo);
});

final pendingRequestsProvider = Provider<List<PartnerUpdateRequest>>((ref) {
  return ref.watch(partnerApprovalProvider).pendingRequests;
});

final myPendingApprovalsCountProvider = Provider<int>((ref) {
  return ref.watch(partnerApprovalProvider).pendingCount;
});
