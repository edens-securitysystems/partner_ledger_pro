import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/partner_dto.dart';
import '../../../core/models/entities/partner.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/partner_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class PartnersState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Partner> partners;
  final Partner? selectedPartner;
  final String? searchQuery;
  final PartnerStatus? statusFilter;
  final bool isSearching;

  const PartnersState({
    this.isLoading = false,
    this.error,
    this.partners = const [],
    this.selectedPartner,
    this.searchQuery,
    this.statusFilter,
    this.isSearching = false,
  });

  const PartnersState.initial() : this();

  PartnersState copyWith({
    bool? isLoading,
    String? error,
    List<Partner>? partners,
    Partner? selectedPartner,
    String? searchQuery,
    PartnerStatus? statusFilter,
    bool? isSearching,
    bool clearSelected = false,
  }) {
    return PartnersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      partners: partners ?? this.partners,
      selectedPartner: clearSelected == true ? null : (selectedPartner ?? this.selectedPartner),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  List<Partner> get filteredPartners {
    var result = partners;
    if (statusFilter != null) {
      result = result.where((p) => p.status == statusFilter).toList();
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.email?.toLowerCase().contains(query) ?? false) ||
              (p.phone?.contains(query) ?? false))
          .toList();
    }
    return result;
  }

  @override
  List<Object?> get props =>
      [isLoading, error, partners, selectedPartner, searchQuery, statusFilter, isSearching];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PartnersNotifier extends StateNotifier<PartnersState> {
  final PartnerRepository _repository;

  PartnersNotifier(this._repository) : super(const PartnersState.initial());

  Future<void> fetchAll({String? businessId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getAll(businessId: businessId);
      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, partners: response.data);
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> add({required CreatePartnerRequest request, required String businessId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.create(request);
      if (response.success && response.data != null) {
        final partner = response.data!;
        state = state.copyWith(
          isLoading: false,
          partners: [...state.partners, partner],
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update({required String id, required UpdatePartnerRequest request}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.update(id, request);
      if (response.success && response.data != null) {
        final partner = response.data!;
        state = state.copyWith(
          isLoading: false,
          partners: state.partners.map((p) => p.id == id ? partner : p).toList(),
          selectedPartner: state.selectedPartner?.id == id ? partner : state.selectedPartner,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.delete(id);
      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          partners: state.partners.where((p) => p.id != id).toList(),
          selectedPartner: state.selectedPartner?.id == id ? null : state.selectedPartner,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectPartner(Partner? partner) {
    state = state.copyWith(selectedPartner: partner);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query, isSearching: query.isNotEmpty);
  }

  void filterByStatus(PartnerStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  void clearFilters() {
    state = state.copyWith(searchQuery: null, statusFilter: null, isSearching: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final partnersProvider = StateNotifierProvider<PartnersNotifier, PartnersState>((ref) {
  final repository = ref.watch(partnerRepositoryProvider);
  return PartnersNotifier(repository);
});

final selectedPartnerProvider = Provider<Partner?>((ref) {
  return ref.watch(partnersProvider).selectedPartner;
});

final filteredPartnersProvider = Provider<List<Partner>>((ref) {
  return ref.watch(partnersProvider).filteredPartners;
});
