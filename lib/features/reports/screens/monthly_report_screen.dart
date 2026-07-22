import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/enums.dart';
import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../providers/report_provider.dart';
import '../widgets/report_chart.dart';
import '../widgets/report_summary.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).generateMonthly(
            year: _selectedYear,
            month: _selectedMonth,
          );
    });
  }

  void _generateReport() {
    ref.read(reportProvider.notifier).generateMonthly(
          year: _selectedYear,
          month: _selectedMonth,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Monthly Report',
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
                  _buildMonthSelector(context),
                  const SizedBox(height: 16),
                  ReportSummary(
                    stats: _buildSummaryStats(),
                  ),
                  const SizedBox(height: 16),
                  _buildIncomeBreakdown(context),
                  const SizedBox(height: 16),
                  _buildExpenseBreakdown(context),
                  const SizedBox(height: 16),
                  _buildDailyProfitChart(context),
                  const SizedBox(height: 16),
                  _buildTransactionList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
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
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
                _generateReport();
              },
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _monthNames[_selectedMonth - 1],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _selectedYear.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: (_selectedYear < DateTime.now().year ||
                      (_selectedYear == DateTime.now().year &&
                          _selectedMonth < DateTime.now().month))
                  ? () {
                      setState(() {
                        if (_selectedMonth == 12) {
                          _selectedMonth = 1;
                          _selectedYear++;
                        } else {
                          _selectedMonth++;
                        }
                      });
                      _generateReport();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  List<ReportStat> _buildSummaryStats() {
    final monthly = _getMockMonthlyData();
    return [
      ReportStat(
        title: 'Total Income',
        value: '₹${_formatAmount(monthly.income)}',
        icon: Icons.trending_up_rounded,
        color: AppColors.profit,
        subtitle: 'Monthly earnings',
      ),
      ReportStat(
        title: 'Total Expense',
        value: '₹${_formatAmount(monthly.expense)}',
        icon: Icons.trending_down_rounded,
        color: AppColors.debit,
        subtitle: 'Monthly spending',
      ),
      ReportStat(
        title: 'Net Profit',
        value: '₹${_formatAmount(monthly.profit)}',
        icon: Icons.account_balance_rounded,
        color: monthly.profit >= 0 ? AppColors.profit : AppColors.loss,
        subtitle: monthly.profit >= 0 ? 'Profitable' : 'Loss',
      ),
      ReportStat(
        title: 'Transactions',
        value: monthly.transactionCount.toString(),
        icon: Icons.receipt_long_rounded,
        color: AppColors.chartPalette[4],
        subtitle: 'This month',
      ),
    ];
  }

  Widget _buildIncomeBreakdown(BuildContext context) {
    return ReportChartSection(
      title: 'Income Breakdown',
      subtitle: 'Category-wise income distribution',
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.profit,
      height: 240,
      child: ReportPieChart(
        sections: [
          ReportPieData(
            label: 'Sales',
            value: 125000,
            color: AppColors.chartPalette[1],
            icon: Icons.shopping_cart_rounded,
          ),
          ReportPieData(
            label: 'Services',
            value: 85000,
            color: AppColors.chartPalette[0],
            icon: Icons.build_rounded,
          ),
          ReportPieData(
            label: 'Commission',
            value: 45000,
            color: AppColors.chartPalette[5],
            icon: Icons.percent_rounded,
          ),
          ReportPieData(
            label: 'Other',
            value: 25000,
            color: AppColors.chartPalette[2],
            icon: Icons.more_horiz_rounded,
          ),
        ],
        centerLabel: 'Income',
      ),
    );
  }

  Widget _buildExpenseBreakdown(BuildContext context) {
    return ReportChartSection(
      title: 'Expense Breakdown',
      subtitle: 'Category-wise expense distribution',
      icon: Icons.trending_down_rounded,
      iconColor: AppColors.debit,
      height: 240,
      child: ReportPieChart(
        sections: [
          ReportPieData(
            label: 'Salaries',
            value: 95000,
            color: AppColors.chartPalette[3],
            icon: Icons.people_rounded,
          ),
          ReportPieData(
            label: 'Rent',
            value: 35000,
            color: AppColors.chartPalette[4],
            icon: Icons.home_rounded,
          ),
          ReportPieData(
            label: 'Utilities',
            value: 18000,
            color: AppColors.chartPalette[5],
            icon: Icons.bolt_rounded,
          ),
          ReportPieData(
            label: 'Supplies',
            value: 22000,
            color: AppColors.chartPalette[2],
            icon: Icons.inventory_2_rounded,
          ),
          ReportPieData(
            label: 'Other',
            value: 15000,
            color: AppColors.chartPalette[0],
            icon: Icons.more_horiz_rounded,
          ),
        ],
        centerLabel: 'Expense',
      ),
    );
  }

  Widget _buildDailyProfitChart(BuildContext context) {
    return ReportChartSection(
      title: 'Daily Profit Trend',
      subtitle: 'Profit across the month',
      icon: Icons.show_chart_rounded,
      iconColor: AppColors.chartPalette[0],
      height: 220,
      child: _DailyProfitLineChart(
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = _getMockTransactions();

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
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${transactions.length} transactions this month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 56,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return _TransactionTile(
                title: txn['title'] as String,
                amount: txn['amount'] as double,
                date: txn['date'] as DateTime,
                type: txn['type'] as TransactionType,
              );
            },
          ),
        ],
      ),
    );
  }

  MonthlyReport _getMockMonthlyData() {
    return MonthlyReport(
      year: _selectedYear,
      month: _selectedMonth,
      income: 280000,
      expense: 185000,
      profit: 95000,
      transactionCount: 47,
    );
  }

  List<Map<String, dynamic>> _getMockTransactions() {
    final now = DateTime(_selectedYear, _selectedMonth, 15);
    return [
      {
        'title': 'Client Payment - Project Alpha',
        'amount': 75000.0,
        'date': now,
        'type': TransactionType.income,
      },
      {
        'title': 'Monthly Salaries',
        'amount': -45000.0,
        'date': now.subtract(const Duration(days: 2)),
        'type': TransactionType.expense,
      },
      {
        'title': 'Office Rent',
        'amount': -35000.0,
        'date': now.subtract(const Duration(days: 3)),
        'type': TransactionType.expense,
      },
      {
        'title': 'Partner Investment - Raj',
        'amount': 50000.0,
        'date': now.subtract(const Duration(days: 5)),
        'type': TransactionType.investment,
      },
      {
        'title': 'Service Revenue',
        'amount': 32000.0,
        'date': now.subtract(const Duration(days: 7)),
        'type': TransactionType.income,
      },
    ];
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

  void _shareReport() {
    Share.share(
      'Monthly Report - ${_monthNames[_selectedMonth - 1]} $_selectedYear\n'
      'Income: ₹2,80,000 | Expense: ₹1,85,000 | Profit: ₹95,000',
      subject:
          'Monthly Report - ${_monthNames[_selectedMonth - 1]} $_selectedYear',
    );
  }

  void _handleExport(String type) {
    final request = ReportRequest(
      startDate: DateTime(_selectedYear, _selectedMonth, 1),
      endDate: DateTime(_selectedYear, _selectedMonth + 1, 0),
    );
    switch (type) {
      case 'pdf':
        ref.read(reportProvider.notifier).exportPDF(request: request);
      case 'excel':
        ref.read(reportProvider.notifier).exportExcel(request: request);
    }
  }
}

class _DailyProfitLineChart extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;

  const _DailyProfitLineChart({
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final spots = List.generate(daysInMonth, (i) {
      final value = (i * 3200) + (1500 * (i % 7) - 2000);
      return FlSpot(i.toDouble(), value.toDouble());
    });

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.4),
            strokeWidth: 1,
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
              reservedSize: 24,
              interval: (daysInMonth / 6).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    day.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY > 0 ? (maxY / 4) : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compact(value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (daysInMonth - 1).toDouble(),
        minY: minY < 0 ? minY * 1.2 : 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.chartPalette[0],
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.chartPalette[0].withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                Theme.of(context).colorScheme.inverseSurface,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '₹${_formatAmount(s.y)}',
                    TextStyle(
                      color:
                          Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _compact(double value) {
    final v = value.abs();
    if (v >= 100000) return '${(value / 100000).toStringAsFixed(0)}L';
    if (v >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toInt().toString();
  }

  String _formatAmount(double value) {
    return NumberFormat('#,##0').format(value);
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;

  const _TransactionTile({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCredit = amount >= 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(type.icon, size: 18, color: type.color),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy').format(date),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}₹${NumberFormat('#,##0.00').format(amount.abs())}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isCredit ? AppColors.credit : AppColors.debit,
        ),
      ),
    );
  }
}
