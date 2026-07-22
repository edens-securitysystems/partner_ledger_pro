import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../providers/report_provider.dart';
import '../widgets/report_chart.dart';
import '../widgets/report_summary.dart';

class YearlyReportScreen extends ConsumerStatefulWidget {
  const YearlyReportScreen({super.key});

  @override
  ConsumerState<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends ConsumerState<YearlyReportScreen> {
  int _selectedYear = DateTime.now().year;

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).generateYearly(_selectedYear);
    });
  }

  void _generateReport() {
    ref.read(reportProvider.notifier).generateYearly(_selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Yearly Report',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareReport,
          ),
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
                  _buildYearSelector(context),
                  const SizedBox(height: 16),
                  ReportSummary(stats: _buildYearStats()),
                  const SizedBox(height: 16),
                  _buildMonthlyComparisonChart(context),
                  const SizedBox(height: 16),
                  _buildQuarterlyBreakdown(context),
                  const SizedBox(height: 16),
                  _buildTopPartners(context),
                  const SizedBox(height: 16),
                  _buildYearOverYearComparison(context),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _selectedYear > 2020
                  ? () {
                      setState(() => _selectedYear--);
                      _generateReport();
                    }
                  : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _selectedYear.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Financial Year',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _selectedYear < DateTime.now().year
                  ? () {
                      setState(() => _selectedYear++);
                      _generateReport();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  List<ReportStat> _buildYearStats() {
    return [
      const ReportStat(
        title: 'Total Income',
        value: '₹32.40L',
        icon: Icons.trending_up_rounded,
        color: AppColors.profit,
        subtitle: 'Year total',
      ),
      const ReportStat(
        title: 'Total Expense',
        value: '₹21.60L',
        icon: Icons.trending_down_rounded,
        color: AppColors.debit,
        subtitle: 'Year total',
      ),
      const ReportStat(
        title: 'Net Profit',
        value: '₹10.80L',
        icon: Icons.account_balance_rounded,
        color: AppColors.profit,
        subtitle: '33.3% margin',
      ),
      ReportStat(
        title: 'Transactions',
        value: '${12 * 47}',
        icon: Icons.receipt_long_rounded,
        color: AppColors.chartPalette[4],
        subtitle: 'Year total',
      ),
    ];
  }

  Widget _buildMonthlyComparisonChart(BuildContext context) {
    final theme = Theme.of(context);
    final incomeData = [
      2.2, 2.5, 2.8, 2.6, 3.0, 2.9, 3.2, 3.1, 2.7, 3.0, 3.2, 3.2,
    ];
    final expenseData = [
      1.5, 1.6, 1.8, 1.7, 2.0, 1.9, 2.1, 2.0, 1.8, 1.9, 2.0, 2.3,
    ];

    return ReportChartSection(
      title: 'Monthly Comparison',
      subtitle: 'Income vs Expense by month',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.chartPalette[0],
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 4,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n₹${rod.toY.toStringAsFixed(1)}L',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _monthAbbr.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _monthAbbr[idx],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  '₹${value.toInt()}L',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant
                  .withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: incomeData[i],
                  color: AppColors.profit,
                  width: 8,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: expenseData[i],
                  color: AppColors.debit,
                  width: 8,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildQuarterlyBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quarters = [
      _QuarterData('Q1 (Jan-Mar)', 7.5, 4.9),
      _QuarterData('Q2 (Apr-Jun)', 8.5, 5.6),
      _QuarterData('Q3 (Jul-Sep)', 9.0, 5.9),
      _QuarterData('Q4 (Oct-Dec)', 9.4, 6.2),
    ];

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
                    color: AppColors.chartPalette[2]
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    size: 18,
                    color: AppColors.chartPalette[2],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Quarterly Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...quarters.map(
            (q) => _QuarterTile(data: q),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTopPartners(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partners = [
      _PartnerProfit('Rajesh Kumar', 380000, 25.0),
      _PartnerProfit('Priya Sharma', 290000, 20.0),
      _PartnerProfit('Amit Patel', 225000, 15.0),
      _PartnerProfit('Sneha Reddy', 195000, 12.0),
      _PartnerProfit('Vikram Singh', 150000, 10.0),
    ];

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
                    color: AppColors.chartPalette[4]
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 18,
                    color: AppColors.chartPalette[4],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Top Partners by Profit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(partners.length, (i) {
            final p = partners[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.chartPalette[
                        i % AppColors.chartPalette.length]
                    .withValues(alpha: 0.15),
                child: Text(
                  (i + 1).toString(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.chartPalette[
                        i % AppColors.chartPalette.length],
                  ),
                ),
              ),
              title: Text(
                p.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${p.ownership}% ownership',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                '₹${_formatAmount(p.profit)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.profit,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildYearOverYearComparison(BuildContext context) {
    return ReportChartSection(
      title: 'Year-over-Year Comparison',
      subtitle: 'Revenue trend over the years',
      icon: Icons.compare_arrows_rounded,
      iconColor: AppColors.chartPalette[5],
      height: 220,
      child: _YoYLineChart(currentYear: _selectedYear),
    );
  }

  String _formatAmount(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0.00').format(value);
  }

  void _shareReport() {
    Share.share(
      'Yearly Report - $_selectedYear\n'
      'Income: ₹32.40L | Expense: ₹21.60L | Profit: ₹10.80L',
      subject: 'Yearly Report - $_selectedYear',
    );
  }

  void _handleExport(String type) {
    final request = ReportRequest(
      startDate: DateTime(_selectedYear, 1, 1),
      endDate: DateTime(_selectedYear, 12, 31),
    );
    switch (type) {
      case 'pdf':
        ref.read(reportProvider.notifier).exportPDF(request: request);
      case 'excel':
        ref.read(reportProvider.notifier).exportExcel(request: request);
    }
  }
}

class _QuarterData {
  final String label;
  final double income;
  final double expense;

  const _QuarterData(this.label, this.income, this.expense);

  double get profit => income - expense;
  double get margin => income > 0 ? (profit / income) * 100 : 0;
}

class _QuarterTile extends StatelessWidget {
  final _QuarterData data;

  const _QuarterTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹${data.income.toStringAsFixed(1)}L',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.profit,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${data.expense.toStringAsFixed(1)}L',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.debit,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.profit.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.margin.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.profit,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: data.income > 0 ? data.profit / data.income : 0,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: AppColors.profit,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerProfit {
  final String name;
  final double profit;
  final double ownership;

  const _PartnerProfit(this.name, this.profit, this.ownership);
}

class _YoYLineChart extends StatelessWidget {
  final int currentYear;

  const _YoYLineChart({required this.currentYear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final years = List.generate(5, (i) => currentYear - 4 + i);
    final incomeSpots = [
      FlSpot(0, 18),
      FlSpot(1, 22),
      FlSpot(2, 26),
      FlSpot(3, 29),
      FlSpot(4, 32.4),
    ];
    final profitSpots = [
      FlSpot(0, 5.4),
      FlSpot(1, 6.6),
      FlSpot(2, 7.8),
      FlSpot(3, 8.7),
      FlSpot(4, 10.8),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.chartPalette[0], label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.chartPalette[1], label: 'Profit'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 8,
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
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= years.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          years[idx].toString(),
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
                    reservedSize: 36,
                    interval: 8,
                    getTitlesWidget: (value, meta) => Text(
                      '₹${value.toInt()}L',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 4,
              minY: 0,
              maxY: 36,
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: AppColors.chartPalette[0],
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.chartPalette[0],
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: profitSpots,
                  isCurved: true,
                  color: AppColors.chartPalette[1],
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.chartPalette[1],
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          '₹${s.y.toStringAsFixed(1)}L',
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
        ),
      ],
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
