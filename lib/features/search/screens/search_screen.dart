import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/entities/business.dart';
import '../../../core/models/entities/partner.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../providers/search_provider.dart';

enum _SearchTab { all, partners, transactions, businesses }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  _SearchTab _selectedTab = _SearchTab.all;
  Timer? _debounce;
  final List<String> _recentSearches = [
    'John Doe',
    'ABC Traders',
    'Invoice #1234',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clearSearch();
  }

  void _addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search partners, transactions...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: _onSearchChanged,
          onSubmitted: (query) {
            _addRecentSearch(query);
            ref.read(searchProvider.notifier).search(query);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(theme, colorScheme),
          Expanded(
            child: _buildContent(
              theme,
              colorScheme,
              state,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'All',
            isSelected: _selectedTab == _SearchTab.all,
            onTap: () => setState(() => _selectedTab = _SearchTab.all),
          ),
          _TabItem(
            label: 'Partners',
            isSelected: _selectedTab == _SearchTab.partners,
            onTap: () =>
                setState(() => _selectedTab = _SearchTab.partners),
          ),
          _TabItem(
            label: 'Transactions',
            isSelected: _selectedTab == _SearchTab.transactions,
            onTap: () =>
                setState(() => _selectedTab = _SearchTab.transactions),
          ),
          _TabItem(
            label: 'Businesses',
            isSelected: _selectedTab == _SearchTab.businesses,
            onTap: () =>
                setState(() => _selectedTab = _SearchTab.businesses),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ColorScheme colorScheme,
    SearchState state,
  ) {
    if (state.isSearching) {
      return const LoadingWidget.shimmerList();
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(searchProvider.notifier).clearError();
                },
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.query.isEmpty) {
      return _buildRecentSearches(theme, colorScheme);
    }

    if (state.results.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'No results match "${state.query}". Try a different search term.',
      );
    }

    return _buildSearchResults(state, theme, colorScheme);
  }

  Widget _buildRecentSearches(ThemeData theme, ColorScheme colorScheme) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search Everything',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for partners, transactions, businesses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (_, index) {
              final query = _recentSearches[index];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _removeRecentSearch(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  ref.read(searchProvider.notifier).search(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    SearchState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(searchProvider.notifier).search(state.query);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (_selectedTab == _SearchTab.all ||
              _selectedTab == _SearchTab.partners)
            if (state.results.partners.isNotEmpty) ...[
              _buildCategoryHeader(
                theme,
                colorScheme,
                'Partners',
                Icons.people_rounded,
                state.results.partners.length,
              ),
              ...state.results.partners
                  .map(
                    (p) => _buildPartnerResult(p, colorScheme),
                  ),
              const SizedBox(height: 8),
            ],
          if (_selectedTab == _SearchTab.all ||
              _selectedTab == _SearchTab.transactions)
            if (state.results.transactions.isNotEmpty) ...[
              _buildCategoryHeader(
                theme,
                colorScheme,
                'Transactions',
                Icons.receipt_long_rounded,
                state.results.transactions.length,
              ),
              ...state.results.transactions
                  .map(
                    (t) => _buildTransactionResult(t, colorScheme),
                  ),
              const SizedBox(height: 8),
            ],
          if (_selectedTab == _SearchTab.all ||
              _selectedTab == _SearchTab.businesses)
            if (state.results.businesses.isNotEmpty) ...[
              _buildCategoryHeader(
                theme,
                colorScheme,
                'Businesses',
                Icons.business_rounded,
                state.results.businesses.length,
              ),
              ...state.results.businesses
                  .map(
                    (b) => _buildBusinessResult(b, colorScheme),
                  ),
              const SizedBox(height: 8),
            ],
          if (_selectedTab == _SearchTab.all &&
              state.results.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerResult(Partner partner, ColorScheme colorScheme) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          partner.name.isNotEmpty
              ? partner.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(partner.name),
      subtitle: Text(partner.email ?? partner.phone ?? ''),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.push('/partners/${partner.id}'),
    );
  }

  Widget _buildTransactionResult(
    Transaction transaction,
    ColorScheme colorScheme,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.receipt_rounded,
          size: 18,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(transaction.description ?? 'Transaction'),
      subtitle: Text(
        transaction.amount.toStringAsFixed(2),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.push('/transactions/${transaction.id}'),
    );
  }

  Widget _buildBusinessResult(Business business, ColorScheme colorScheme) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.business_rounded,
          size: 18,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
      title: Text(business.name),
      subtitle: Text(business.ownerEmail),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.push('/businesses/${business.id}'),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
