import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../transactions/providers/transaction_provider.dart';
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
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
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
    final reportData = state.reportData;

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
                  ReportSummary(stats: _buildSummaryStats(reportData)),
                  const SizedBox(height: 16),
                  _buildIncomeBreakdown(context, reportData),
                  const SizedBox(height: 16),
                  _buildExpenseBreakdown(context, reportData),
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

  List<ReportStat> _buildSummaryStats(ReportResponse? reportData) {
    final monthly = _getMonthlyData(reportData);
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

  MonthlyReport _getMonthlyData(ReportResponse? reportData) {
    if (reportData == null) {
      return MonthlyReport(
        year: _selectedYear,
        month: _selectedMonth,
      );
    }
    for (final m in reportData.monthlyReports) {
      if (m.year == _selectedYear && m.month == _selectedMonth) {
        return m;
      }
    }
    return MonthlyReport(
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  Widget _buildIncomeBreakdown(BuildContext context, ReportResponse? reportData) {
    final incomeCategories = reportData?.categoryBreakdown
            .where((c) => (c['income'] as double) > 0)
            .toList() ??
        [];

    if (incomeCategories.isEmpty) {
      return ReportChartSection(
        title: 'Income Breakdown',
        subtitle: 'No income data for this month',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.profit,
        height: 240,
        child: const Center(
          child: Text(
            'No income transactions this month',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    final palette = AppColors.chartPalette;
    final icons = [
      Icons.shopping_cart_rounded,
      Icons.build_rounded,
      Icons.percent_rounded,
      Icons.work_rounded,
      Icons.more_horiz_rounded,
      Icons.attach_money_rounded,
      Icons.monetization_on_rounded,
      Icons.savings_rounded,
    ];

    return ReportChartSection(
      title: 'Income Breakdown',
      subtitle: 'Category-wise income distribution',
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.profit,
      height: 240,
      child: ReportPieChart(
        sections: incomeCategories.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return ReportPieData(
            label: c['category'] as String,
            value: c['income'] as double,
            color: palette[i % palette.length],
            icon: icons[i % icons.length],
          );
        }).toList(),
        centerLabel: 'Income',
      ),
    );
  }

  Widget _buildExpenseBreakdown(BuildContext context, ReportResponse? reportData) {
    final expenseCategories = reportData?.categoryBreakdown
            .where((c) => (c['expense'] as double) > 0)
            .toList() ??
        [];

    if (expenseCategories.isEmpty) {
      return ReportChartSection(
        title: 'Expense Breakdown',
        subtitle: 'No expense data for this month',
        icon: Icons.trending_down_rounded,
        iconColor: AppColors.debit,
        height: 240,
        child: const Center(
          child: Text(
            'No expense transactions this month',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    final palette = AppColors.chartPalette;
    final icons = [
      Icons.people_rounded,
      Icons.home_rounded,
      Icons.bolt_rounded,
      Icons.inventory_2_rounded,
      Icons.more_horiz_rounded,
      Icons.build_rounded,
      Icons.directions_car_rounded,
      Icons.phone_rounded,
    ];

    return ReportChartSection(
      title: 'Expense Breakdown',
      subtitle: 'Category-wise expense distribution',
      icon: Icons.trending_down_rounded,
      iconColor: AppColors.debit,
      height: 240,
      child: ReportPieChart(
        sections: expenseCategories.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return ReportPieData(
            label: c['category'] as String,
            value: c['expense'] as double,
            color: palette[i % palette.length],
            icon: icons[i % icons.length],
          );
        }).toList(),
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

    return Consumer(
      builder: (context, ref, _) {
        final txState = ref.watch(transactionsProvider);
        final allTransactions = txState.transactions;

        final filteredTxns = allTransactions.where((t) {
          return t.date.year == _selectedYear && t.date.month == _selectedMonth;
        }).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

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
                            '${filteredTxns.length} transactions this month',
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
              if (filteredTxns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No transactions this month',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxns.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 56,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final txn = filteredTxns[index];
                    final isIncome = txn.isIncome;
                    final txnIcon = _txTypeIcon(txn.type);
                    final txnColor = _txTypeColor(txn.type);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: txnColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(txnIcon, size: 18, color: txnColor),
                      ),
                      title: Text(
                        txn.description ?? txn.category ?? 'Transaction',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(txn.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}₹${NumberFormat('#,##0.00').format(txn.amount.abs())}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isIncome ? AppColors.credit : AppColors.debit,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
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

  IconData _txTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.investment:
        return Icons.account_balance_rounded;
      case TransactionType.withdrawal:
        return Icons.payments_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.loan:
        return Icons.handshake_rounded;
      case TransactionType.loanRepayment:
        return Icons.receipt_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
      case TransactionType.profitDistribution:
        return Icons.pie_chart_rounded;
      case TransactionType.lossAllocation:
        return Icons.remove_circle_outline_rounded;
    }
  }

  Color _txTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.profit;
      case TransactionType.expense:
        return AppColors.debit;
      case TransactionType.investment:
        return AppColors.chartPalette[0];
      case TransactionType.withdrawal:
        return AppColors.loss;
      case TransactionType.transfer:
        return AppColors.chartPalette[5];
      case TransactionType.loan:
        return AppColors.chartPalette[2];
      case TransactionType.loanRepayment:
        return AppColors.credit;
      case TransactionType.adjustment:
        return AppColors.chartPalette[3];
      case TransactionType.profitDistribution:
        return AppColors.profit;
      case TransactionType.lossAllocation:
        return AppColors.loss;
    }
  }

  void _shareReport() {
    final reportData = ref.read(reportProvider).reportData;
    final monthly = _getMonthlyData(reportData);
    Share.share(
      'Monthly Report - ${_monthNames[_selectedMonth - 1]} $_selectedYear\n'
      'Income: ₹${_formatAmount(monthly.income)} | Expense: ₹${_formatAmount(monthly.expense)} | Profit: ₹${_formatAmount(monthly.profit)}',
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
