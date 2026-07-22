import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/partner_dto.dart';
import '../../../core/models/entities/partner_invite.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/invite_repository.dart';
import '../../../core/repositories/partner_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum InviteProcessStatus {
  initial,
  loading,
  loaded,
  creating,
  accepting,
  error,
}

class InviteState extends Equatable {
  final InviteProcessStatus status;
  final PartnerInvite? currentInvite;
  final List<PartnerInvite> invites;
  final String? error;
  final bool acceptSuccess;

  const InviteState({
    this.status = InviteProcessStatus.initial,
    this.currentInvite,
    this.invites = const [],
    this.error,
    this.acceptSuccess = false,
  });

  const InviteState.initial() : this();
  const InviteState.loading() : this(status: InviteProcessStatus.loading);
  const InviteState.loaded(List<PartnerInvite> invites)
      : this(status: InviteProcessStatus.loaded, invites: invites);
  const InviteState.error(String error)
      : this(status: InviteProcessStatus.error, error: error);

  InviteState copyWith({
    InviteProcessStatus? status,
    PartnerInvite? currentInvite,
    List<PartnerInvite>? invites,
    String? error,
    bool? acceptSuccess,
  }) {
    return InviteState(
      status: status ?? this.status,
      currentInvite: currentInvite ?? this.currentInvite,
      invites: invites ?? this.invites,
      error: error,
      acceptSuccess: acceptSuccess ?? this.acceptSuccess,
    );
  }

  @override
  List<Object?> get props => [status, currentInvite, invites, error, acceptSuccess];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class InviteNotifier extends StateNotifier<InviteState> {
  final InviteRepository _inviteRepo;
  final PartnerRepository _partnerRepo;

  InviteNotifier({
    required InviteRepository inviteRepo,
    required PartnerRepository partnerRepo,
  })  : _inviteRepo = inviteRepo,
        _partnerRepo = partnerRepo,
        super(const InviteState.initial());

  Future<void> createInvite({
    required String businessId,
    required String businessName,
    required String createdByUserId,
    required String createdByEmail,
    int expiryHours = 48,
  }) async {
    state = state.copyWith(status: InviteProcessStatus.creating, error: null);
    final response = await _inviteRepo.create(
      businessId: businessId,
      businessName: businessName,
      createdByUserId: createdByUserId,
      createdByEmail: createdByEmail,
      expiryHours: expiryHours,
    );

    if (response.success && response.data != null) {
      state = state.copyWith(
        status: InviteProcessStatus.loaded,
        currentInvite: response.data,
        invites: [...state.invites, response.data!],
      );
    } else {
      state = state.copyWith(
        status: InviteProcessStatus.error,
        error: response.message,
      );
    }
  }

  Future<void> validateToken(String token) async {
    state = state.copyWith(status: InviteProcessStatus.loading, error: null);
    final response = await _inviteRepo.getByToken(token);

    if (response.success && response.data != null) {
      state = state.copyWith(
        status: InviteProcessStatus.loaded,
        currentInvite: response.data,
      );
    } else {
      state = state.copyWith(
        status: InviteProcessStatus.error,
        error: response.message,
      );
    }
  }

  Future<bool> acceptInvite({
    required String inviteId,
    required String userId,
    required String userEmail,
    required String partnerId,
  }) async {
    state = state.copyWith(status: InviteProcessStatus.accepting, error: null);

    final inviteResponse = await _inviteRepo.accept(
      inviteId: inviteId,
      acceptedByUserId: userId,
      acceptedByEmail: userEmail,
      acceptedByPartnerId: partnerId,
    );

    if (!inviteResponse.success || inviteResponse.data == null) {
      state = state.copyWith(
        status: InviteProcessStatus.error,
        error: inviteResponse.message,
      );
      return false;
    }

    final invite = inviteResponse.data!;
    final partnerResponse = await _partnerRepo.getById(invite.businessId);
    if (partnerResponse.success && partnerResponse.data != null) {
      final updatedPartner = partnerResponse.data!.copyWith(
        userId: userId,
        updatedAt: DateTime.now(),
      );
      await _partnerRepo.update(updatedPartner.id, UpdatePartnerRequest(
        name: updatedPartner.name,
        email: updatedPartner.email,
        phone: updatedPartner.phone,
        photo: updatedPartner.photo,
        capital: updatedPartner.capital,
        ownershipPercentage: updatedPartner.ownershipPercentage,
        joiningDate: updatedPartner.joiningDate,
        status: updatedPartner.status,
        description: updatedPartner.description,
        isActive: updatedPartner.isActive,
      ));
    }

    state = state.copyWith(
      status: InviteProcessStatus.loaded,
      currentInvite: invite,
      acceptSuccess: true,
    );
    return true;
  }

  Future<void> loadInvites(String businessId) async {
    state = state.copyWith(status: InviteProcessStatus.loading, error: null);
    final response = await _inviteRepo.getByBusiness(businessId);

    if (response.success && response.data != null) {
      state = state.copyWith(
        status: InviteProcessStatus.loaded,
        invites: response.data!,
      );
    } else {
      state = state.copyWith(
        status: InviteProcessStatus.error,
        error: response.message,
      );
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    final response = await _inviteRepo.revoke(inviteId);
    if (response.success && response.data != null) {
      final updated = state.invites.map((i) =>
          i.id == inviteId ? response.data! : i).toList();
      state = state.copyWith(
        invites: updated,
        currentInvite: state.currentInvite?.id == inviteId
            ? response.data
            : state.currentInvite,
      );
    }
  }

  void clearAcceptSuccess() {
    state = state.copyWith(acceptSuccess: false);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final inviteProvider = StateNotifierProvider<InviteNotifier, InviteState>((ref) {
  return InviteNotifier(
    inviteRepo: ref.watch(inviteRepositoryProvider),
    partnerRepo: ref.watch(partnerRepositoryProvider),
  );
});
