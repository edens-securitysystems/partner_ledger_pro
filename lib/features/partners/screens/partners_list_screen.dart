import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner.dart';
import '../../../widgets/cards/partner_card.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/forms/app_search_field.dart';
import '../providers/partner_provider.dart';

enum _SortOption { name, capital, ownership, joiningDate }

class PartnersListScreen extends ConsumerStatefulWidget {
  const PartnersListScreen({super.key});

  @override
  ConsumerState<PartnersListScreen> createState() => _PartnersListScreenState();
}

class _PartnersListScreenState extends ConsumerState<PartnersListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnimation;

  bool _isGridView = false;
  _SortOption _sortOption = _SortOption.name;
  bool _sortAscending = true;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    _fabAnimController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnersProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  List<Partner> _sortPartners(List<Partner> partners) {
    final sorted = List<Partner>.from(partners);
    switch (_sortOption) {
      case _SortOption.name:
        sorted.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
      case _SortOption.capital:
        sorted.sort((a, b) => _sortAscending
            ? a.capital.compareTo(b.capital)
            : b.capital.compareTo(a.capital));
      case _SortOption.ownership:
        sorted.sort((a, b) => _sortAscending
            ? a.ownershipPercentage.compareTo(b.ownershipPercentage)
            : b.ownershipPercentage.compareTo(a.ownershipPercentage));
      case _SortOption.joiningDate:
        sorted.sort((a, b) => _sortAscending
            ? a.joiningDate.compareTo(b.joiningDate)
            : b.joiningDate.compareTo(a.joiningDate));
    }
    return sorted;
  }

  void _selectSort(_SortOption option) {
    setState(() {
      if (_sortOption == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortOption = option;
        _sortAscending = true;
      }
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(partnersProvider);
    final filteredPartners = ref.watch(filteredPartnersProvider);
    final sortedPartners = _sortPartners(filteredPartners);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Partners',
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) => _selectSort(option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortOption.name,
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: _SortOption.capital,
                child: Text('Sort by Capital'),
              ),
              const PopupMenuItem(
                value: _SortOption.ownership,
                child: Text('Sort by Ownership'),
              ),
              const PopupMenuItem(
                value: _SortOption.joiningDate,
                child: Text('Sort by Joining Date'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppSearchField(
                hint: 'Search partners...',
                onSearch: (query) {
                  ref.read(partnersProvider.notifier).search(query);
                },
                onClear: () {
                  ref.read(partnersProvider.notifier).search('');
                },
              ),
            ),
          _buildFilterChips(colorScheme),
          Expanded(
            child: _buildContent(state, sortedPartners, colorScheme),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/partners/add'),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Partner'),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    final state = ref.watch(partnersProvider);
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _FilterChip(
            label: 'All',
            selected: state.statusFilter == null,
            onPressed: () {
              ref.read(partnersProvider.notifier).filterByStatus(null);
            },
          ),
          _FilterChip(
            label: 'Active',
            selected: state.statusFilter == PartnerStatus.active,
            onPressed: () {
              ref.read(partnersProvider.notifier).filterByStatus(
                    PartnerStatus.active,
                  );
            },
          ),
          _FilterChip(
            label: 'Inactive',
            selected: state.statusFilter == PartnerStatus.inactive,
            onPressed: () {
              ref.read(partnersProvider.notifier).filterByStatus(
                    PartnerStatus.inactive,
                  );
            },
          ),
          _FilterChip(
            label: 'Suspended',
            selected: state.statusFilter == PartnerStatus.suspended,
            onPressed: () {
              ref.read(partnersProvider.notifier).filterByStatus(
                    PartnerStatus.suspended,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    PartnersState state,
    List<Partner> partners,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && partners.isEmpty) {
      return const LoadingWidget.shimmerList();
    }

    if (state.error != null && partners.isEmpty) {
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
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(partnersProvider.notifier).clearError();
                  ref.read(partnersProvider.notifier).fetchAll();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (partners.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.group_rounded,
        title: 'No Partners Found',
        subtitle: state.searchQuery != null && state.searchQuery!.isNotEmpty
            ? 'No partners match your search criteria.'
            : 'Start by adding your first business partner.',
        actionLabel:
            state.searchQuery == null || state.searchQuery!.isEmpty
                ? 'Add Partner'
                : null,
        onAction: state.searchQuery == null || state.searchQuery!.isEmpty
            ? () => context.push('/partners/add')
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(partnersProvider.notifier).fetchAll(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isGridView
            ? _buildGridView(partners, colorScheme)
            : _buildListView(partners),
      ),
    );
  }

  Widget _buildListView(List<Partner> partners) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: partners.length,
      itemBuilder: (context, index) {
        final partner = partners[index];
        return PartnerCard(
          key: ValueKey(partner.id),
          partner: partner,
          onTap: () => context.push('/partners/${partner.id}'),
        );
      },
    );
  }

  Widget _buildGridView(List<Partner> partners, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12).copyWith(bottom: 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: partners.length,
          itemBuilder: (context, index) {
            final partner = partners[index];
            return _PartnerGridCard(
              key: ValueKey(partner.id),
              partner: partner,
              onTap: () => context.push('/partners/${partner.id}'),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onPressed(),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          side: BorderSide(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

class _PartnerGridCard extends StatelessWidget {
  final Partner partner;
  final VoidCallback? onTap;

  const _PartnerGridCard({
    super.key,
    required this.partner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat('#,##0.00');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(context),
              const SizedBox(height: 10),
              Text(
                partner.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '\u20B9${currencyFormat.format(partner.capital)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${partner.ownershipPercentage.toStringAsFixed(1)}% ownership',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial =
        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 28,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (partner.status) {
      case PartnerStatus.active:
        bgColor = const Color(0xFFC6F6D5);
        textColor = const Color(0xFF38A169);
      case PartnerStatus.inactive:
        bgColor = const Color(0xFFEDF2F7);
        textColor = const Color(0xFFA0AEC0);
      case PartnerStatus.pending:
        bgColor = const Color(0xFFFEEBC8);
        textColor = const Color(0xFFDD6B20);
      case PartnerStatus.suspended:
        bgColor = const Color(0xFFFED7D7);
        textColor = const Color(0xFFE53E3E);
      case PartnerStatus.withdrawn:
        bgColor = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF718096);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        partner.statusDisplay,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
