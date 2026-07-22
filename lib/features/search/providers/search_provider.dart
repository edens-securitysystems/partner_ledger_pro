import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/entities/business.dart';
import '../../../core/models/entities/partner.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/repositories/partner_repository.dart';
import '../../../core/repositories/transaction_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class SearchResult extends Equatable {
  final List<Partner> partners;
  final List<Transaction> transactions;
  final List<Business> businesses;

  const SearchResult({
    this.partners = const [],
    this.transactions = const [],
    this.businesses = const [],
  });

  bool get isEmpty =>
      partners.isEmpty && transactions.isEmpty && businesses.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalCount =>
      partners.length + transactions.length + businesses.length;

  SearchResult copyWith({
    List<Partner>? partners,
    List<Transaction>? transactions,
    List<Business>? businesses,
  }) {
    return SearchResult(
      partners: partners ?? this.partners,
      transactions: transactions ?? this.transactions,
      businesses: businesses ?? this.businesses,
    );
  }

  @override
  List<Object?> get props => [partners, transactions, businesses];
}

class SearchState extends Equatable {
  final bool isSearching;
  final String? error;
  final String query;
  final SearchResult results;

  const SearchState({
    this.isSearching = false,
    this.error,
    this.query = '',
    this.results = const SearchResult(),
  });

  const SearchState.initial() : this();

  SearchState copyWith({
    bool? isSearching,
    String? error,
    String? query,
    SearchResult? results,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      error: error,
      query: query ?? this.query,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [isSearching, error, query, results];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final PartnerRepository _partnerRepository;
  final TransactionRepository _transactionRepository;

  SearchNotifier(this._partnerRepository, this._transactionRepository)
      : super(const SearchState.initial());

  Future<void> search(String query) async {
    if (query.length < 2) {
      state = state.copyWith(query: query, results: const SearchResult(), isSearching: false);
      return;
    }

    state = state.copyWith(query: query, isSearching: true, error: null);
    try {
      final partnerResponse = await _partnerRepository.search(query);
      final transactionResponse = await _transactionRepository.getAll();

      final partners = partnerResponse.success && partnerResponse.data != null
          ? partnerResponse.data!
          : <Partner>[];

      List<Transaction> transactions = const [];
      if (transactionResponse.success && transactionResponse.data != null) {
        final q = query.toLowerCase();
        transactions = transactionResponse.data!
            .where((t) =>
                (t.description?.toLowerCase().contains(q) ?? false) ||
                (t.category?.toLowerCase().contains(q) ?? false))
            .toList();
      }

      state = state.copyWith(
        isSearching: false,
        results: SearchResult(partners: partners, transactions: transactions),
      );
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> searchPartners(String query) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final response = await _partnerRepository.search(query);
      if (response.success && response.data != null) {
        state = state.copyWith(
          isSearching: false,
          results: state.results.copyWith(partners: response.data),
        );
      } else {
        state = state.copyWith(isSearching: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> searchTransactions(String query) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final response = await _transactionRepository.getAll();
      if (response.success && response.data != null) {
        final q = query.toLowerCase();
        final filtered = response.data!
            .where((t) =>
                (t.description?.toLowerCase().contains(q) ?? false) ||
                (t.category?.toLowerCase().contains(q) ?? false))
            .toList();
        state = state.copyWith(
          isSearching: false,
          results: state.results.copyWith(transactions: filtered),
        );
      } else {
        state = state.copyWith(isSearching: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = const SearchState.initial();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return SearchNotifier(partnerRepo, transactionRepo);
});

final searchResultsProvider = Provider<SearchResult>((ref) {
  return ref.watch(searchProvider).results;
});

final searchQueryProvider = Provider<String>((ref) {
  return ref.watch(searchProvider).query;
});

final isSearchingProvider = Provider<bool>((ref) {
  return ref.watch(searchProvider).isSearching;
});
