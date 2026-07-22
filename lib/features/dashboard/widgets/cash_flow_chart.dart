import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';
import '../providers/dashboard_provider.dart';

class CashFlowChart extends ConsumerWidget {
  const CashFlowChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash Flow',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'Income vs Expenses',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (stats == null)
            const _CashFlowChartShimmer()
          else
            SizedBox(
              height: 220,
              child: _CashFlowBarView(
                monthlyIncome: stats.monthlyIncome,
                monthlyExpense: stats.monthlyExpense,
                totalIncome: stats.totalIncome,
                totalExpense: stats.totalExpense,
              ),
            ),
        ],
      ),
    );
  }
}

class _CashFlowBarView extends StatelessWidget {
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalIncome;
  final double totalExpense;

  const _CashFlowBarView({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxY = [monthlyIncome, monthlyExpense, totalIncome, totalExpense]
        .reduce((a, b) => a > b ? a : b);

    final incomeColor = AppColors.profit;
    final expenseColor = AppColors.debit;

    final barGroups = [
      _buildBarGroup(0, monthlyIncome, monthlyExpense, incomeColor,
          expenseColor, maxY, colorScheme),
      _buildBarGroup(1, totalIncome, totalExpense, incomeColor, expenseColor,
          maxY, colorScheme),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.3,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = groupIndex == 0 ? 'Monthly' : 'Total';
                final type = rodIndex == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label $type\n',
                  TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: _formatValue(rod.toY),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: rodIndex == 0 ? incomeColor : expenseColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final labels = ['Monthly', 'Total'];
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatYAxis(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outlineVariant,
                strokeWidth: 0.5,
              );
            },
            drawVerticalLine: false,
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double income,
    double expense,
    Color incomeColor,
    Color expenseColor,
    double maxY,
    ColorScheme colorScheme,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: income,
          color: incomeColor,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY * 1.3,
            color: colorScheme.surfaceContainerHighest,
          ),
        ),
        BarChartRodData(
          toY: expense,
          color: expenseColor,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  String _formatYAxis(double value) {
    if (value == 0) return '0';
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(0)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(0)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _CashFlowChartShimmer extends StatelessWidget {
  const _CashFlowChartShimmer();

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
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 24, 16, 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShimmerBar(height: 80),
              const SizedBox(width: 16),
              _ShimmerBar(height: 120),
              const SizedBox(width: 24),
              _ShimmerBar(height: 100),
              const SizedBox(width: 16),
              _ShimmerBar(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double height;

  const _ShimmerBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
