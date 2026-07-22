import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/stat_card.dart';
import '../providers/dashboard_provider.dart';

class StatsGrid extends ConsumerWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final profitSummary = ref.watch(dashboardProfitSummaryProvider);

    if (stats == null) return const _StatsGridShimmer();

    final todayProfit = stats.monthlyProfit;
    final monthlyProfit = profitSummary?.currentMonthProfit ?? 0.0;
    final totalProfit = stats.totalProfit;
    final outstanding = stats.totalBalance;

    final items = [
      _StatItem(
        title: "Today's Profit",
        value: todayProfit,
        icon: Icons.today_rounded,
        color: AppColors.profit,
      ),
      _StatItem(
        title: 'Monthly Profit',
        value: monthlyProfit,
        icon: Icons.calendar_month_rounded,
        color: AppColors.income,
      ),
      _StatItem(
        title: 'Total Profit',
        value: totalProfit,
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.profit,
      ),
      _StatItem(
        title: 'Income',
        value: stats.totalIncome,
        icon: Icons.arrow_upward_rounded,
        color: AppColors.credit,
      ),
      _StatItem(
        title: 'Expenses',
        value: stats.totalExpense,
        icon: Icons.arrow_downward_rounded,
        color: AppColors.debit,
      ),
      _StatItem(
        title: 'Outstanding',
        value: outstanding,
        icon: Icons.receipt_long_rounded,
        color: AppColors.investment,
      ),
    ];

    return _AnimatedStatsGrid(items: items);
  }
}

class _StatItem {
  final String title;
  final double value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _AnimatedStatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _AnimatedStatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1200 ? 3 : width >= 800 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: width >= 1200 ? 1.6 : width >= 800 ? 1.4 : 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StaggeredStatCard(
          index: index,
          item: item,
        );
      },
    );
  }
}

class _StaggeredStatCard extends StatefulWidget {
  final int index;
  final _StatItem item;

  const _StaggeredStatCard({required this.index, required this.item});

  @override
  State<_StaggeredStatCard> createState() => _StaggeredStatCardState();
}

class _StaggeredStatCardState extends State<_StaggeredStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationNormal,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(milliseconds: 50 * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatCurrency(widget.item.value);
    final changePercent = widget.item.value != 0
        ? (widget.item.value > 0 ? 2.4 : -1.2)
        : null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: StatCard(
          title: widget.item.title,
          value: formatted,
          icon: widget.item.icon,
          iconColor: widget.item.color,
          changePercentage: changePercent,
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    const prefix = '₹';
    if (value.abs() >= 10000000) {
      return '$prefix${(value / 10000000).toStringAsFixed(2)}Cr';
    }
    if (value.abs() >= 100000) {
      return '$prefix${(value / 100000).toStringAsFixed(2)}L';
    }
    if (value.abs() >= 1000) {
      return '$prefix${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$prefix${value.toStringAsFixed(2)}';
  }
}

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

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
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 50,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 110,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
