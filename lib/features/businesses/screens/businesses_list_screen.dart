import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/entities/business.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/forms/app_search_field.dart';
import '../providers/business_provider.dart';

class BusinessesListScreen extends ConsumerStatefulWidget {
  const BusinessesListScreen({super.key});

  @override
  ConsumerState<BusinessesListScreen> createState() =>
      _BusinessesListScreenState();
}

class _BusinessesListScreenState extends ConsumerState<BusinessesListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnimation;
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
      ref.read(businessesProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(businessesProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Businesses',
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
            ),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppSearchField(
                hint: 'Search businesses...',
                onSearch: (query) {},
                onClear: () {},
              ),
            ),
          Expanded(
            child: _buildContent(state, colorScheme),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/businesses/add'),
          icon: const Icon(Icons.business_rounded),
          label: const Text('Add Business'),
        ),
      ),
    );
  }

  Widget _buildContent(BusinessesState state, ColorScheme colorScheme) {
    if (state.isLoading && state.businesses.isEmpty) {
      return const LoadingWidget.shimmerList();
    }

    if (state.error != null && state.businesses.isEmpty) {
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
                  ref.read(businessesProvider.notifier).clearError();
                  ref.read(businessesProvider.notifier).fetchAll();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.businesses.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.business_rounded,
        title: 'No Businesses',
        subtitle: 'Start by adding your first business.',
        actionLabel: 'Add Business',
        onAction: () => context.push('/businesses/add'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(businessesProvider.notifier).fetchAll(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: state.businesses.length,
        itemBuilder: (context, index) {
          final business = state.businesses[index];
          return _BusinessCard(
            key: ValueKey(business.id),
            business: business,
            onTap: () {},
            onEdit: () => context.push('/businesses/edit/${business.id}'),
          );
        },
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const _BusinessCard({
    super.key,
    required this.business,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildLogo(colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!business.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (business.description != null &&
                        business.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          business.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.people_rounded,
                          '12 Partners',
                          colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.receipt_rounded,
                          '48 Transactions',
                          colorScheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    if (business.logo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          business.logo!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _logoPlaceholder(colorScheme),
        ),
      );
    }
    return _logoPlaceholder(colorScheme);
  }

  Widget _logoPlaceholder(ColorScheme colorScheme) {
    final initial =
        business.name.isNotEmpty ? business.name[0].toUpperCase() : 'B';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
