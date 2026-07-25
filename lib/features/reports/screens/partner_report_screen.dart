import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../core/models/entities/partner.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../partners/providers/partner_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/report_chart.dart';
import '../widgets/report_summary.dart';

class PartnerReportScreen extends ConsumerStatefulWidget {
  const PartnerReportScreen({super.key});

  @override
  ConsumerState<PartnerReportScreen> createState() =>
      _PartnerReportScreenState();
}

class _PartnerReportScreenState extends ConsumerState<PartnerReportScreen> {
  String? _selectedPartnerId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnersProvider.notifier).fetchAll();
    });
  }

  void _generateReport() {
    if (_selectedPartnerId == null) return;
    ref.read(reportProvider.notifier).generatePartnerWise(
          partnerId: _selectedPartnerId!,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);
    final partnersState = ref.watch(partnersProvider);
    final partners = partnersState.partners;
    final reportData = state.reportData;

    if (_selectedPartnerId == null && partners.isNotEmpty) {
      _selectedPartnerId = partners.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _generateReport());
    }

    final selectedPartner = _selectedPartnerId != null
        ? partners.firstWhere(
            (p) => p.id == _selectedPartnerId,
            orElse: () => partners.first,
          )
        : null;

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Partner Report',
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
      body: state.isLoading || partnersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerSelector(context, partners),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(context),
                  const SizedBox(height: 16),
                  ReportSummary(
                      stats: _buildPartnerStats(selectedPartner, reportData)),
                  const SizedBox(height: 16),
                  if (reportData != null && reportData.monthlyReports.isNotEmpty)
                    _buildCapitalVsProfitChart(context, reportData),
                  const SizedBox(height: 16),
                  if (reportData != null && reportData.categoryBreakdown.isNotEmpty)
                    _buildTransactionHistoryChart(context, reportData),
                  const SizedBox(height: 16),
                  if (selectedPartner != null)
                    _buildLedgerSummary(context, selectedPartner, reportData),
                  const SizedBox(height: 16),
                  _buildPartnerComparison(context, partners, reportData),
                ],
              ),
            ),
    );
  }

  Widget _buildPartnerSelector(BuildContext context, List<Partner> partners) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Partner',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (partners.isEmpty)
              Text(
                'No partners found. Add partners first.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: partners.map((partner) {
                  final isSelected = partner.id == _selectedPartnerId;
                  return ChoiceChip(
                    label: Text(partner.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedPartnerId = partner.id);
                      _generateReport();
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant,
                    ),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _CompactDateButton(
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
              child: _CompactDateButton(
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

  List<ReportStat> _buildPartnerStats(
      Partner? partner, ReportResponse? reportData) {
    final capital = partner?.capital ?? 0;
    final ownership = partner?.ownershipPercentage ?? 0;
    final totalIncome = reportData?.totalIncome ?? 0;
    final totalProfit = reportData?.totalProfit ?? 0;
    final totalTxnCount =
        reportData?.monthlyReports.fold<int>(0, (sum, m) => sum + m.transactionCount) ?? 0;

    return [
      ReportStat(
        title: 'Capital Invested',
        value: '₹${_formatAmount(capital)}',
        icon: Icons.account_balance_rounded,
        color: AppColors.investment,
        subtitle: '${ownership.toStringAsFixed(1)}% ownership',
      ),
      ReportStat(
        title: 'Total Profit',
        value: '₹${_formatAmount(totalProfit)}',
        icon: Icons.trending_up_rounded,
        color: totalProfit >= 0 ? AppColors.profit : AppColors.loss,
        subtitle: 'This period',
      ),
      ReportStat(
        title: 'Total Transactions',
        value: '$totalTxnCount',
        icon: Icons.receipt_long_rounded,
        color: AppColors.chartPalette[4],
        subtitle: 'In period',
      ),
      ReportStat(
        title: 'Profit Margin',
        value: '${totalIncome > 0 ? ((totalProfit / totalIncome) * 100).toStringAsFixed(1) : '0.0'}%',
        icon: Icons.percent_rounded,
        color: AppColors.chartPalette[0],
        subtitle: 'Income margin',
      ),
    ];
  }

  Widget _buildCapitalVsProfitChart(
      BuildContext context, ReportResponse reportData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthlyReports = reportData.monthlyReports;
    final months = monthlyReports
        .map((m) => _monthAbbr(m.month))
        .toList();
    final capitalData = List.generate(
        monthlyReports.length, (i) => monthlyReports[i].income / 1000);
    final profitData = List.generate(
        monthlyReports.length, (i) => monthlyReports[i].profit / 1000);

    final maxY = [
      ...capitalData,
      ...profitData.map((v) => v.abs())
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return ReportChartSection(
      title: 'Income vs Profit',
      subtitle: 'Monthly income and profit trend',
      icon: Icons.compare_arrows_rounded,
      iconColor: AppColors.chartPalette[5],
      height: 240,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.investment, label: 'Income (₹K)'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.profit, label: 'Profit (₹K)'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                      interval: (months.length / 6).ceilToDouble().clamp(1, double.infinity),
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
                      interval: maxY > 0 ? (maxY / 4) : 1,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}K',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (months.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.2 : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      capitalData.length,
                      (i) => FlSpot(i.toDouble(), capitalData[i]),
                    ),
                    isCurved: true,
                    color: AppColors.investment,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      profitData.length,
                      (i) => FlSpot(i.toDouble(), profitData[i]),
                    ),
                    isCurved: true,
                    color: AppColors.profit,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryChart(
      BuildContext context, ReportResponse reportData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = reportData.categoryBreakdown;
    final maxVal = categories.fold<double>(
        0, (max, c) => (c['total'] as double) > max ? (c['total'] as double) : max);

    return ReportChartSection(
      title: 'Category Breakdown',
      subtitle: 'Transaction amounts by category',
      icon: Icons.history_rounded,
      iconColor: AppColors.chartPalette[2],
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.1 : 100000,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${_formatAmount(rod.toY)}',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  final label = categories[idx]['category'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label.length > 8 ? '${label.substring(0, 8)}..' : label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 25000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(categories.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: categories[i]['total'] as double,
                  color: AppColors.chartPalette[
                      i % AppColors.chartPalette.length],
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLedgerSummary(
      BuildContext context, Partner partner, ReportResponse? reportData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalIncome = reportData?.totalIncome ?? 0;
    final totalExpense = reportData?.totalExpense ?? 0;
    final totalProfit = reportData?.totalProfit ?? 0;

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
                    color: AppColors.chartPalette[5].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.book_rounded,
                    size: 18,
                    color: AppColors.chartPalette[5],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ledger Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _LedgerRow(
            label: 'Capital Invested',
            value: '₹${_formatAmount(partner.capital)}',
            color: AppColors.investment,
          ),
          _LedgerRow(
            label: 'Total Income',
            value: '₹${_formatAmount(totalIncome)}',
            color: AppColors.credit,
          ),
          _LedgerRow(
            label: 'Total Expense',
            value: '₹${_formatAmount(totalExpense)}',
            color: AppColors.debit,
          ),
          const Divider(indent: 16, endIndent: 16),
          _LedgerRow(
            label: 'Net Result',
            value: '₹${_formatAmount(totalProfit)}',
            color: totalProfit >= 0 ? AppColors.profit : AppColors.loss,
            isBold: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPartnerComparison(
      BuildContext context, List<Partner> partners, ReportResponse? reportData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalProfit = reportData?.totalProfit ?? 1;

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
                    color: AppColors.chartPalette[3].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppColors.chartPalette[3],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Partner Comparison',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...partners.map(
            (p) {
              final isSelected = p.id == _selectedPartnerId;
              final profitShare = totalProfit > 0
                  ? totalProfit * (p.ownershipPercentage / 100)
                  : 0.0;
              final percentage = totalProfit > 0 ? p.ownershipPercentage : 0.0;

              return _PartnerComparisonRow(
                name: p.name,
                ownership: p.ownershipPercentage,
                profitShare: profitShare,
                percentage: percentage,
                isSelected: isSelected,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0.00').format(value);
  }

  String _monthAbbr(int month) {
    const abbrs = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return abbrs[(month - 1).clamp(0, 11)];
  }

  void _handleExport(String type) {
    final request = ReportRequest(
      startDate: _startDate,
      endDate: _endDate,
      partnerId: _selectedPartnerId,
    );
    switch (type) {
      case 'pdf':
        ref.read(reportProvider.notifier).exportPDF(request: request);
      case 'excel':
        ref.read(reportProvider.notifier).exportExcel(request: request);
    }
  }
}

class _CompactDateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _CompactDateButton({
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _LedgerRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerComparisonRow extends StatelessWidget {
  final String name;
  final double ownership;
  final double profitShare;
  final double percentage;
  final bool isSelected;

  const _PartnerComparisonRow({
    required this.name,
    required this.ownership,
    required this.profitShare,
    required this.percentage,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: isSelected
          ? BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹${_formatAmount(profitShare)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.profit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${ownership.toStringAsFixed(1)}% ownership',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: AppColors.profit,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
