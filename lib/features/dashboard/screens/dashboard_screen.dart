import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/models/dto/dashboard_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/profit_trend_chart.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_activity.dart';
import '../widgets/stats_grid.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: state.isLoading && state.data == null
          ? const _DashboardShimmer()
          : state.error != null && state.data == null
              ? _DashboardError(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).fetchDashboardData(),
                )
              : _DashboardContent(
                  onRefresh: () =>
                      ref.read(dashboardProvider.notifier).refreshDashboard(),
                ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final Future<void> Function() onRefresh;

  const _DashboardContent({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final hasData = state.data != null;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1200;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _WelcomeHeader(
              userName: 'Partner',
              lastFetched: state.lastFetched,
            ),
          ),
          if (!hasData && state.isLoading)
            const SliverToBoxAdapter(child: _DashboardShimmerContent())
          else if (!hasData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.dashboard_rounded,
                title: 'Welcome to Partner Ledger Pro',
                subtitle:
                    'Start by adding your first transaction or partner to see your dashboard come alive.',
                actionLabel: 'Get Started',
                onAction: () {},
              ),
            )
          else ...[
            if (isDesktop)
              SliverToBoxAdapter(
                child: _DesktopLayout(
                  child: _buildDesktopContent(context, ref, stats),
                ),
              )
            else
              ..._buildMobileSlivers(context, ref, stats),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 0 : 16,
                  8,
                  isDesktop ? 0 : 16,
                  24,
                ),
                child: QuickActions(
                  onAddTransaction: () {},
                  onAddPartner: () {},
                  onViewReports: () {},
                  onExport: () {},
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMobileSlivers(
    BuildContext context,
    WidgetRef ref,
    DashboardStats? stats,
  ) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: const SliverToBoxAdapter(child: StatsGrid()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: const SliverToBoxAdapter(child: ProfitTrendChart()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: _buildChartsRow(context, ref),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: const SliverToBoxAdapter(child: CashFlowChart()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: _buildSummaryCards(context, ref),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: const SliverToBoxAdapter(child: RecentActivity()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildChartsRow(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: IncomeExpenseChart()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildInvestmentSummary(context, ref),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            const IncomeExpenseChart(),
            const SizedBox(height: 12),
            _buildInvestmentSummary(context, ref),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Row(
      children: [
        Expanded(
          child: _CreditDebitCard(
            title: 'Credit',
            amount: stats?.totalIncome ?? 0.0,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.credit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CreditDebitCard(
            title: 'Debit',
            amount: stats?.totalExpense ?? 0.0,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.debit,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentSummary(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.investment.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 18,
                    color: AppColors.investment,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Investment Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InvestmentRow(
              label: 'Total Balance',
              value: stats?.totalBalance ?? 0.0,
              color: AppColors.investment,
            ),
            const SizedBox(height: 12),
            _InvestmentRow(
              label: 'Total Partners',
              value: (stats?.totalPartners ?? 0).toDouble(),
              isCount: true,
              color: AppColors.income,
            ),
            const SizedBox(height: 12),
            _InvestmentRow(
              label: 'Active Partners',
              value: (stats?.activePartners ?? 0).toDouble(),
              isCount: true,
              color: AppColors.profit,
            ),
            const SizedBox(height: 12),
            _InvestmentRow(
              label: 'Transactions',
              value: (stats?.totalTransactions ?? 0).toDouble(),
              isCount: true,
              color: AppColors.transfer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    WidgetRef ref,
    DashboardStats? stats,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const StatsGrid(),
              const SizedBox(height: 12),
              const ProfitTrendChart(),
              const SizedBox(height: 12),
              _buildChartsRow(context, ref),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const RecentActivity(),
              const SizedBox(height: 12),
              _buildSummaryCards(context, ref),
              const SizedBox(height: 12),
              _buildInvestmentSummary(context, ref),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;

  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String userName;
  final DateTime? lastFetched;

  const _WelcomeHeader({
    required this.userName,
    this.lastFetched,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final greeting = _getGreeting(now);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width >= 1200 ? 24 : 16,
        16,
        MediaQuery.sizeOf(context).width >= 1200 ? 24 : 16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $userName',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (lastFetched != null) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_timeAgo(lastFetched!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CreditDebitCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _CreditDebitCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatAmount(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    }
    if (value.abs() >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    }
    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${NumberFormat('#,##0.00').format(value)}';
  }
}

class _InvestmentRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isCount;
  final Color color;

  const _InvestmentRow({
    required this.label,
    required this.value,
    this.isCount = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isCount ? value.toInt().toString() : _formatAmount(value),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    }
    if (value.abs() >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)}L';
    }
    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${NumberFormat('#,##0.00').format(value)}';
  }
}

class _DashboardError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _DashboardError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.loss,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade50;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: 220,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 160,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: List.generate(
              6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardShimmerContent extends StatelessWidget {
  const _DashboardShimmerContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade50;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: List.generate(
                6,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
