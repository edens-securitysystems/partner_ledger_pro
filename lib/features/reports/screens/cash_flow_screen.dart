import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../providers/report_provider.dart';
import '../widgets/report_chart.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateReport());
  }

  void _generateReport() {
    ref.read(reportProvider.notifier).generateCashFlow(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Cash Flow Statement',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSelector(context),
                  const SizedBox(height: 16),
                  _buildNetCashFlowCard(context),
                  const SizedBox(height: 16),
                  _buildOperatingActivities(context),
                  const SizedBox(height: 16),
                  _buildInvestingActivities(context),
                  const SizedBox(height: 16),
                  _buildFinancingActivities(context),
                  const SizedBox(height: 16),
                  _buildCashFlowBarChart(context),
                  const SizedBox(height: 16),
                  _buildRunningBalanceChart(context),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'From',
                date: dateFormat.format(_startDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                    _generateReport();
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, size: 16),
            ),
            Expanded(
              child: _DateButton(
                label: 'To',
                date: dateFormat.format(_endDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                    _generateReport();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetCashFlowCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const netCashFlow = 185000.0;
    final isPositive = netCashFlow >= 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPositive
                ? [
                    AppColors.profit.withValues(alpha: 0.08),
                    AppColors.profit.withValues(alpha: 0.02),
                  ]
                : [
                    AppColors.loss.withValues(alpha: 0.08),
                    AppColors.loss.withValues(alpha: 0.02),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.profit : AppColors.loss)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isPositive ? AppColors.profit : AppColors.loss,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Net Cash Flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${isPositive ? '+' : ''}₹${_formatAmount(netCashFlow)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isPositive ? AppColors.profit : AppColors.loss,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingActivities(BuildContext context) {
    return _ActivitySection(
      title: 'Operating Activities',
      icon: Icons.business_center_rounded,
      color: AppColors.chartPalette[0],
      items: const [
        _ActivityItem('Cash from Sales', 325000, true),
        _ActivityItem('Cash from Services', 185000, true),
        _ActivityItem('Cash from Commissions', 75000, true),
        _ActivityItem('Supplier Payments', -125000, false),
        _ActivityItem('Salary Payments', -145000, false),
        _ActivityItem('Rent & Utilities', -52000, false),
        _ActivityItem('Other Operating Expenses', -28000, false),
      ],
      subtotal: 235000,
    );
  }

  Widget _buildInvestingActivities(BuildContext context) {
    return _ActivitySection(
      title: 'Investing Activities',
      icon: Icons.show_chart_rounded,
      color: AppColors.chartPalette[1],
      items: const [
        _ActivityItem('Equipment Purchase', -85000, false),
        _ActivityItem('Asset Sale', 32000, true),
        _ActivityItem('Investment Returns', 18000, true),
      ],
      subtotal: -35000,
    );
  }

  Widget _buildFinancingActivities(BuildContext context) {
    return _ActivitySection(
      title: 'Financing Activities',
      icon: Icons.account_balance_rounded,
      color: AppColors.chartPalette[4],
      items: const [
        _ActivityItem('Partner Investment', 150000, true),
        _ActivityItem('Loan Received', 85000, true),
        _ActivityItem('Loan Repayment', -65000, false),
        _ActivityItem('Partner Withdrawal', -185000, false),
      ],
      subtotal: -15000,
    );
  }

  Widget _buildCashFlowBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final operating = [38.0, 42.0, 35.0, 48.0, 40.0, 45.0];
    final investing = [-8.0, -5.0, -12.0, -3.0, -8.0, -5.0];
    final financing = [5.0, -2.0, 8.0, -5.0, 3.0, -10.0];

    return ReportChartSection(
      title: 'Monthly Cash Flow',
      subtitle: 'Cash flow by activity type',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.chartPalette[0],
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppColors.chartPalette[0],
                label: 'Operating',
              ),
              const SizedBox(width: 12),
              _LegendDot(
                color: AppColors.chartPalette[1],
                label: 'Investing',
              ),
              const SizedBox(width: 12),
              _LegendDot(
                color: AppColors.chartPalette[4],
                label: 'Financing',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60,
                minY: -20,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}K',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            months[idx],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}K',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: operating[i],
                        color: AppColors.chartPalette[0],
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: investing[i],
                        color: AppColors.chartPalette[1],
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: financing[i],
                        color: AppColors.chartPalette[4],
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningBalanceChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balance = <double>[];
    var current = 1200000.0;

    for (var i = 0; i < 30; i++) {
      current += (15000 * (i % 3 + 1)) - (12000 * ((i + 1) % 4));
      balance.add(current);
    }

    final spots = List.generate(
      balance.length,
      (i) => FlSpot(i.toDouble(), balance[i]),
    );

    final minY = balance.reduce((a, b) => a < b ? a : b);
    final maxY = balance.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return ReportChartSection(
      title: 'Running Balance',
      subtitle: 'Daily cash balance trend',
      icon: Icons.timeline_rounded,
      iconColor: AppColors.chartPalette[5],
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant
                  .withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt() + 1;
                  if (day < 1 || day > 30 || day % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      day.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 29,
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.chartPalette[5],
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.chartPalette[5].withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colorScheme.inverseSurface,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      'Day ${s.x.toInt() + 1}\n₹${_formatAmount(s.y)}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    }
    if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##0.00').format(value);
  }

  String _compact(double value) {
    final v = value.abs();
    if (v >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toInt().toString();
  }

  void _handleExport(String type) {
    final request = ReportRequest(
      startDate: _startDate,
      endDate: _endDate,
    );
    switch (type) {
      case 'pdf':
        ref.read(reportProvider.notifier).exportPDF(request: request);
      case 'excel':
        ref.read(reportProvider.notifier).exportExcel(request: request);
    }
  }
}

class _ActivitySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ActivityItem> items;
  final double subtotal;

  const _ActivitySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (subtotal >= 0 ? AppColors.profit : AppColors.loss)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${subtotal >= 0 ? '+' : ''}₹${_formatAmount(subtotal)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          subtotal >= 0 ? AppColors.profit : AppColors.loss,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => _ActivityItemTile(item: item),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0.00').format(value);
  }
}

class _ActivityItem {
  final String label;
  final double amount;
  final bool isPositive;

  const _ActivityItem(this.label, this.amount, this.isPositive);
}

class _ActivityItemTile extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: item.isPositive ? AppColors.profit : AppColors.loss,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${item.isPositive ? '+' : ''}₹${_formatAmount(item.amount.abs())}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isPositive ? AppColors.profit : AppColors.debit,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0.00').format(value);
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
