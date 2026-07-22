import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/transaction_dto.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/cards/transaction_card.dart';
import '../providers/transaction_provider.dart';
import '../../partners/providers/partner_provider.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'filter_screen.dart';

enum _SortField { date, amount, type }

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  TransactionType? _selectedType;
  _SortField _sortField = _SortField.date;
  bool _sortDescending = true;
  String? _selectedPartnerId;
  String? _selectedCategory;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationSlow,
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsProvider.notifier).loadMore();
    }
  }

  void _loadTransactions() {
    final filter = TransactionFilter(
      type: _selectedType,
      partnerId: _selectedPartnerId,
      category: _selectedCategory,
    );
    ref.read(transactionsProvider.notifier).fetchAll(filter: filter);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppConstants.searchDebounce, () {
      setState(() {});
    });
  }

  List<Transaction> _filteredAndSorted(List<Transaction> transactions) {
    var result = List<Transaction>.from(transactions);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        return (t.category?.toLowerCase().contains(query) ?? false) ||
            (t.description?.toLowerCase().contains(query) ?? false) ||
            t.typeDisplay.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sortField) {
      case _SortField.date:
        result.sort((a, b) => _sortDescending
            ? b.date.compareTo(a.date)
            : a.date.compareTo(b.date));
        break;
      case _SortField.amount:
        result.sort((a, b) => _sortDescending
            ? b.amount.compareTo(a.amount)
            : a.amount.compareTo(b.amount));
        break;
      case _SortField.type:
        result.sort((a, b) {
          final cmp = a.type.index.compareTo(b.type.index);
          return _sortDescending ? -cmp : cmp;
        });
        break;
    }

    return result;
  }

  Map<String, double> _computeSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    return {'income': totalIncome, 'expense': totalExpense};
  }

  void _openFilterScreen() async {
    final result = await Navigator.push<TransactionFilter>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          currentFilter: ref.read(transactionsProvider).filter,
        ),
      ),
    );
    if (result != null) {
      ref.read(transactionsProvider.notifier).applyFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final txState = ref.watch(transactionsProvider);
    final partners = ref.watch(filteredPartnersProvider);
    final partnerMap = {for (final p in partners) p.id: p.name};

    ref.listen(transactionsProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.lightError,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(transactionsProvider.notifier).clearError();
      }
    });

    final filtered = _filteredAndSorted(txState.transactions);
    final summary = _computeSummary(txState.transactions);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 140,
              title: const Text('Transactions'),
              actions: [
                IconButton(
                  onPressed: _openFilterScreen,
                  icon: Badge(
                    isLabelVisible: txState.filter.hasFilters,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.tune_rounded),
                  ),
                  tooltip: 'Filters',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
                    child: Column(
                      children: [
                        _buildSearchBar(theme, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSummaryBar(theme, colorScheme, summary, filtered.length),
            ),
            SliverToBoxAdapter(
              child: _buildFilterChips(theme, colorScheme),
            ),
            SliverToBoxAdapter(
              child: _buildSortBar(theme, colorScheme),
            ),
            if (txState.isLoading && txState.transactions.isEmpty)
              const SliverFillRemaining(
                child: _ShimmerLoading(),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(theme, colorScheme),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filtered.length) return null;
                    final tx = filtered[index];
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: TransactionCard(
                        transaction: tx,
                        partnerName: partnerMap[tx.partnerId],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transactionId: tx.id),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            if (txState.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEditTransactionScreen(),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return SearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search transactions...',
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
      trailing: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            icon: const Icon(Icons.clear_rounded, size: 20),
          ),
      ],
      onChanged: _onSearchChanged,
      elevation: WidgetStateProperty.all(0.0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildSummaryBar(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, double> summary,
    int count,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Income',
              amount: currencyFormat.format(summary['income']),
              color: AppColors.profit,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Expense',
              amount: currencyFormat.format(summary['expense']),
              color: AppColors.debit,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const Gap(4),
                Text(
                  '$count',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Txns',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: TransactionType.values.length + 1,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedType == null;
            return FilterChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedType = null);
                _loadTransactions();
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            );
          }
          final type = TransactionType.values[index - 1];
          final isSelected = _selectedType == type;
          return FilterChip(
            avatar: Icon(
              _iconForType(type),
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : _colorForType(type),
            ),
            label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedType = isSelected ? null : type);
              _loadTransactions();
            },
            selectedColor: colorScheme.primaryContainer,
            checkmarkColor: colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.sort_rounded,
              size: 18, color: colorScheme.onSurfaceVariant),
          const Gap(6),
          Text(
            'Sort by:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          ..._SortField.values.map((field) {
            final isActive = _sortField == field;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ChoiceChip(
                label: Text(_sortFieldLabel(field)),
                selected: isActive,
                onSelected: (_) {
                  setState(() {
                    if (_sortField == field) {
                      _sortDescending = !_sortDescending;
                    } else {
                      _sortField = field;
                      _sortDescending = true;
                    }
                  });
                },
                avatar: isActive
                    ? Icon(
                        _sortDescending
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                      )
                    : null,
                selectedColor: colorScheme.secondaryContainer,
                side: BorderSide(
                  color: isActive
                      ? colorScheme.secondary
                      : Colors.transparent,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(20),
            Text(
              'No transactions found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              'Try adjusting your filters or add a new transaction',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditTransactionScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  static String _sortFieldLabel(_SortField field) {
    switch (field) {
      case _SortField.date:
        return 'Date';
      case _SortField.amount:
        return 'Amount';
      case _SortField.type:
        return 'Type';
    }
  }

  static IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.investment:
        return Icons.account_balance_rounded;
      case TransactionType.withdrawal:
        return Icons.payments_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.loan:
        return Icons.handshake_rounded;
      case TransactionType.loanRepayment:
        return Icons.replay_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
      case TransactionType.profitDistribution:
        return Icons.emoji_events_rounded;
      case TransactionType.lossAllocation:
        return Icons.warning_rounded;
    }
  }

  static Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.investment:
        return AppColors.investment;
      case TransactionType.withdrawal:
        return AppColors.withdrawal;
      case TransactionType.transfer:
        return AppColors.transfer;
      case TransactionType.loan:
      case TransactionType.loanRepayment:
        return AppColors.loan;
      case TransactionType.adjustment:
        return AppColors.adjustment;
      case TransactionType.profitDistribution:
        return AppColors.profit;
      case TransactionType.lossAllocation:
        return AppColors.loss;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(4),
        Text(
          amount,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(6),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 14,
                    width: 70,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Gap(6),
                  Container(
                    height: 12,
                    width: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
