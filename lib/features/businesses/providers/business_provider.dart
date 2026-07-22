import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/sheets_config.dart';
import '../../../core/models/entities/business.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/google_sheets_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

class BusinessesState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Business> businesses;
  final Business? selectedBusiness;

  const BusinessesState({
    this.isLoading = false,
    this.error,
    this.businesses = const [],
    this.selectedBusiness,
  });

  const BusinessesState.initial() : this();

  BusinessesState copyWith({
    bool? isLoading,
    String? error,
    List<Business>? businesses,
    Business? selectedBusiness,
    bool clearSelected = false,
  }) {
    return BusinessesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      businesses: businesses ?? this.businesses,
      selectedBusiness:
          clearSelected == true ? null : (selectedBusiness ?? this.selectedBusiness),
    );
  }

  @override
  List<Object?> get props => [isLoading, error, businesses, selectedBusiness];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

Business _fromRow(Map<String, dynamic> row, GoogleSheetsService sheets) {
  return Business(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    description: row['description'] as String?,
    logo: row['logo'] as String?,
    ownerEmail: row['ownerEmail'] as String? ?? '',
    address: row['address'] as String?,
    phone: row['phone'] as String?,
    email: row['email'] as String?,
    website: row['website'] as String?,
    currency: row['currency'] as String? ?? 'INR',
    taxId: row['taxId'] as String?,
    createdAt: sheets.parseDate(row['createdAt']),
    updatedAt: sheets.parseDate(row['updatedAt']),
    isActive: sheets.parseBool(row['isActive']),
  );
}

Map<String, dynamic> _toRow(Business business) {
  return {
    'id': business.id,
    'name': business.name,
    'description': business.description,
    'logo': business.logo,
    'ownerEmail': business.ownerEmail,
    'address': business.address,
    'phone': business.phone,
    'email': business.email,
    'website': business.website,
    'currency': business.currency,
    'taxId': business.taxId,
    'createdAt': business.createdAt.toIso8601String(),
    'updatedAt': business.updatedAt.toIso8601String(),
    'isActive': business.isActive,
  };
}

class BusinessesNotifier extends StateNotifier<BusinessesState> {
  final GoogleSheetsService _sheets;

  BusinessesNotifier(this._sheets) : super(const BusinessesState.initial());

  Future<void> fetchAll({String? ownerEmail}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _sheets.getAll(SheetsConfig.sheetBusinesses);
      if (response.success && response.data != null) {
        var businesses = response.data!.map((row) => _fromRow(row, _sheets)).toList();
        if (ownerEmail != null) {
          businesses = businesses.where((b) => b.ownerEmail == ownerEmail).toList();
        }
        state = state.copyWith(isLoading: false, businesses: businesses);
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> add({
    required String name,
    required String ownerEmail,
    String? description,
    String? currency,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final business = Business(
        id: _sheets.generateId(),
        name: name,
        description: description,
        ownerEmail: ownerEmail,
        currency: currency ?? 'INR',
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      if (_sheets.isConfigured) {
        final response = await _sheets.create(
          SheetsConfig.sheetBusinesses,
          _toRow(business),
        );
        if (response.success) {
          state = state.copyWith(
            isLoading: false,
            businesses: [...state.businesses, business],
          );
          return;
        }
        state = state.copyWith(isLoading: false, error: response.message);
      } else {
        state = state.copyWith(
          isLoading: false,
          businesses: [...state.businesses, business],
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update({
    required String id,
    String? name,
    String? description,
    String? currency,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final existing = state.businesses.firstWhere((b) => b.id == id);
      final updated = existing.copyWith(
        name: name,
        description: description,
        currency: currency,
        updatedAt: DateTime.now(),
      );

      if (_sheets.isConfigured) {
        final response = await _sheets.update(
          SheetsConfig.sheetBusinesses,
          id,
          _toRow(updated),
        );
        if (response.success) {
          state = state.copyWith(
            isLoading: false,
            businesses: state.businesses.map((b) => b.id == id ? updated : b).toList(),
            selectedBusiness: state.selectedBusiness?.id == id ? updated : state.selectedBusiness,
          );
          return;
        }
        state = state.copyWith(isLoading: false, error: response.message);
      } else {
        state = state.copyWith(
          isLoading: false,
          businesses: state.businesses.map((b) => b.id == id ? updated : b).toList(),
          selectedBusiness: state.selectedBusiness?.id == id ? updated : state.selectedBusiness,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_sheets.isConfigured) {
        final response = await _sheets.delete(SheetsConfig.sheetBusinesses, id);
        if (response.success) {
          state = state.copyWith(
            isLoading: false,
            businesses: state.businesses.where((b) => b.id != id).toList(),
            selectedBusiness: state.selectedBusiness?.id == id ? null : state.selectedBusiness,
          );
          return;
        }
        state = state.copyWith(isLoading: false, error: response.message);
      } else {
        state = state.copyWith(
          isLoading: false,
          businesses: state.businesses.where((b) => b.id != id).toList(),
          selectedBusiness: state.selectedBusiness?.id == id ? null : state.selectedBusiness,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectBusiness(Business? business) {
    state = state.copyWith(selectedBusiness: business);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final businessesProvider =
    StateNotifierProvider<BusinessesNotifier, BusinessesState>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  return BusinessesNotifier(sheets);
});

final selectedBusinessProvider = Provider<Business?>((ref) {
  return ref.watch(businessesProvider).selectedBusiness;
});

final businessesListProvider = Provider<List<Business>>((ref) {
  return ref.watch(businessesProvider).businesses;
});

final currentBusinessIdProvider = Provider<String?>((ref) {
  return ref.watch(businessesProvider).selectedBusiness?.id;
});
