import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/entities/partner.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/stat_card.dart';

class PartnerDashboardScreen extends ConsumerStatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  ConsumerState<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends ConsumerState<PartnerDashboardScreen> {
  Partner? _partner;
  double _totalCredits = 0;
  double _totalDebits = 0;
  double _currentBalance = 0;
  int _transactionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final partnerRepo = ref.read(partnerRepositoryProvider);
      final partnerResponse = await partnerRepo.getByUserId(user.id);

      if (partnerResponse.success && partnerResponse.data != null) {
        final partner = partnerResponse.data!;
        final ledgerRepo = ref.read(ledgerRepositoryProvider);
        final transactionRepo = ref.read(transactionRepositoryProvider);

        final ledgerResponse = await ledgerRepo.getPartnerLedger(partner.id);
        final txResponse = await transactionRepo.filterByPartner(partner.id);

        if (mounted) {
          setState(() {
            _partner = partner;
            if (ledgerResponse.success && ledgerResponse.data != null) {
              final entries = ledgerResponse.data!;
              _totalCredits = entries
                  .where((e) => e.isCredit)
                  .fold(0.0, (sum, e) => sum + e.amount);
              _totalDebits = entries
                  .where((e) => !e.isCredit)
                  .fold(0.0, (sum, e) => sum + e.amount);
              _currentBalance = entries.isNotEmpty ? entries.first.balance : 0;
            }
            if (txResponse.success && txResponse.data != null) {
              _transactionCount = txResponse.data!.length;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Dashboard'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(theme, colorScheme, user),
              const SizedBox(height: 20),
              _buildStatsGrid(theme, colorScheme),
              const SizedBox(height: 20),
              _buildOwnershipCard(theme, colorScheme),
              const SizedBox(height: 20),
              _buildQuickActions(theme, colorScheme),
              const SizedBox(height: 20),
              _buildRecentTransactions(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, ColorScheme colorScheme, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  (user?.name ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Partner',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _partner?.businessId ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_partner != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _profileStat(theme, 'Balance', _formatCurrency(_currentBalance)),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _profileStat(theme, 'Ownership', '${_partner!.ownershipPercentage.toStringAsFixed(1)}%'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _profileStat(theme, 'Transactions', '$_transactionCount'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _profileStat(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
          title: 'Total Credits',
          value: _formatCurrency(_totalCredits),
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.profit,
        ),
        StatCard(
          title: 'Total Debits',
          value: _formatCurrency(_totalDebits),
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.loss,
        ),
        StatCard(
          title: 'Current Balance',
          value: _formatCurrency(_currentBalance),
          icon: Icons.account_balance_wallet_rounded,
          iconColor: colorScheme.primary,
        ),
        StatCard(
          title: 'Transactions',
          value: '$_transactionCount',
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.lightTertiary,
        ),
      ],
    );
  }

  Widget _buildOwnershipCard(ThemeData theme, ColorScheme colorScheme) {
    if (_partner == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Details',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailRow(theme, 'Investment', _formatCurrency(_partner!.capital)),
              ),
              Expanded(
                child: _detailRow(theme, 'Ownership', '${_partner!.ownershipPercentage.toStringAsFixed(1)}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailRow(theme, 'Joining Date', _formatDate(_partner!.joiningDate)),
              ),
              Expanded(
                child: _detailRow(theme, 'Status', _partner!.statusDisplay),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _partner!.ownershipPercentage / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                theme,
                colorScheme,
                Icons.receipt_long_rounded,
                'My Ledger',
                AppColors.lightPrimary,
                () => context.push('/partner-ledger-view'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                theme,
                colorScheme,
                Icons.trending_up_rounded,
                'Profit Share',
                AppColors.profit,
                () => context.push('/partner-profit-share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                theme,
                colorScheme,
                Icons.history_rounded,
                'Transactions',
                AppColors.lightTertiary,
                () => context.push('/transactions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_transactionCount == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'You have $_transactionCount transactions',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
