import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/transaction_dto.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/repositories/transaction_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class TransactionsState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<Transaction> transactions;
  final TransactionFilter filter;
  final bool hasMore;

  const TransactionsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.transactions = const [],
    this.filter = const TransactionFilter(),
    this.hasMore = true,
  });

  const TransactionsState.initial() : this();

  TransactionsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Transaction>? transactions,
    TransactionFilter? filter,
    bool? hasMore,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isLoadingMore, error, transactions, filter, hasMore];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super(const TransactionsState.initial());

  Future<void> fetchAll({String? businessId, TransactionFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, error: null, filter: f);
    try {
      final response = await _repository.getAll(filter: f);
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          transactions: response.data,
          hasMore: response.data!.length >= f.limit,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> add({required CreateTransactionRequest request, required String businessId, required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.create(request);
      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          transactions: [response.data!, ...state.transactions],
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update({required String id, required UpdateTransactionRequest request}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.update(id, request);
      if (response.success && response.data != null) {
        final transaction = response.data!;
        state = state.copyWith(
          isLoading: false,
          transactions: state.transactions.map((t) => t.id == id ? transaction : t).toList(),
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
          transactions: state.transactions.where((t) => t.id != id).toList(),
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? businessId}) async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final nextPage = state.filter.page + 1;
      final nextFilter = state.filter.copyWith(page: nextPage);
      final response = await _repository.getAll(filter: nextFilter);
      if (response.success && response.data != null) {
        final newTransactions = response.data!;
        state = state.copyWith(
          isLoadingMore: false,
          transactions: [...state.transactions, ...newTransactions],
          filter: nextFilter,
          hasMore: newTransactions.length >= nextFilter.limit,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void applyFilter(TransactionFilter filter) {
    state = state.copyWith(filter: filter, transactions: []);
    fetchAll();
  }

  void clearFilters() {
    state = state.copyWith(filter: const TransactionFilter(), transactions: []);
    fetchAll();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionsNotifier(repository);
});

final transactionFilterProvider = Provider<TransactionFilter>((ref) {
  return ref.watch(transactionsProvider).filter;
});

final transactionListProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(transactionsProvider).transactions;
});
