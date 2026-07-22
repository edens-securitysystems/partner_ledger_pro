import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
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

  final _partnerOptions = const [
    _PartnerOption('1', 'Rajesh Kumar', 500000, 25.0),
    _PartnerOption('2', 'Priya Sharma', 350000, 20.0),
    _PartnerOption('3', 'Amit Patel', 300000, 15.0),
    _PartnerOption('4', 'Sneha Reddy', 250000, 12.0),
    _PartnerOption('5', 'Vikram Singh', 200000, 10.0),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = '1';
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateReport());
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
    final selectedPartner = _partnerOptions.firstWhere(
      (p) => p.id == _selectedPartnerId,
      orElse: () => _partnerOptions.first,
    );

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
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPartnerSelector(context),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(context),
                  const SizedBox(height: 16),
                  ReportSummary(stats: _buildPartnerStats(selectedPartner)),
                  const SizedBox(height: 16),
                  _buildCapitalVsProfitChart(context),
                  const SizedBox(height: 16),
                  _buildTransactionHistoryChart(context),
                  const SizedBox(height: 16),
                  _buildLedgerSummary(context, selectedPartner),
                  const SizedBox(height: 16),
                  _buildPartnerComparison(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPartnerSelector(BuildContext context) {
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _partnerOptions.map((partner) {
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

  List<ReportStat> _buildPartnerStats(_PartnerOption partner) {
    return [
      ReportStat(
        title: 'Capital Invested',
        value: '₹${_formatAmount(partner.capital)}',
        icon: Icons.account_balance_rounded,
        color: AppColors.investment,
        subtitle: '${partner.ownership}% ownership',
      ),
      const ReportStat(
        title: 'Total Profit Share',
        value: '₹3.80L',
        icon: Icons.trending_up_rounded,
        color: AppColors.profit,
        subtitle: 'This period',
      ),
      ReportStat(
        title: 'Total Transactions',
        value: '28',
        icon: Icons.receipt_long_rounded,
        color: AppColors.chartPalette[4],
        subtitle: 'In period',
      ),
      ReportStat(
        title: 'Current Balance',
        value: '₹4.20L',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.chartPalette[0],
        subtitle: 'Available',
      ),
    ];
  }

  Widget _buildCapitalVsProfitChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final capitalData = [50.0, 50.0, 52.0, 52.0, 55.0, 55.0];
    final profitData = [0.8, 1.2, 0.9, 1.5, 1.1, 1.3];

    return ReportChartSection(
      title: 'Capital vs Profit',
      subtitle: 'Monthly capital and profit trend',
      icon: Icons.compare_arrows_rounded,
      iconColor: AppColors.chartPalette[5],
      height: 240,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppColors.investment,
                label: 'Capital (₹K)',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppColors.profit,
                label: 'Profit (₹K)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
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
                      interval: 15,
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
                maxX: 5,
                minY: 0,
                maxY: 65,
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

  Widget _buildTransactionHistoryChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ['Sales', 'Services', 'Commission', 'Investment', 'Other'];
    final amounts = [120000.0, 85000.0, 45000.0, 50000.0, 25000.0];

    return ReportChartSection(
      title: 'Transaction History',
      subtitle: 'Category-wise transaction amounts',
      icon: Icons.history_rounded,
      iconColor: AppColors.chartPalette[2],
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 140000,
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
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      categories[idx],
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
            horizontalInterval: 35000,
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(categories.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amounts[i],
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
      BuildContext context, _PartnerOption partner) {
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
                    color: AppColors.chartPalette[5]
                        .withValues(alpha: 0.12),
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
            label: 'Opening Balance',
            value: '₹${_formatAmount(partner.capital)}',
            color: AppColors.investment,
          ),
          _LedgerRow(
            label: 'Total Credits',
            value: '₹3.80L',
            color: AppColors.credit,
          ),
          _LedgerRow(
            label: 'Total Debits',
            value: '₹1.20L',
            color: AppColors.debit,
          ),
          const Divider(indent: 16, endIndent: 16),
          _LedgerRow(
            label: 'Closing Balance',
            value: '₹4.20L',
            color: colorScheme.primary,
            isBold: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPartnerComparison(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final comparisonData = [
      _PartnerCompareData('Rajesh Kumar', 25.0, 380000, 27.0),
      _PartnerCompareData('Priya Sharma', 20.0, 290000, 21.0),
      _PartnerCompareData('Amit Patel', 15.0, 225000, 16.0),
      _PartnerCompareData('Sneha Reddy', 12.0, 195000, 14.0),
      _PartnerCompareData('Vikram Singh', 10.0, 150000, 11.0),
    ];

    final totalProfit =
        comparisonData.fold<double>(0, (sum, p) => sum + p.profitShare);

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
                    color: AppColors.chartPalette[3]
                        .withValues(alpha: 0.12),
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
          ...comparisonData.map(
            (p) => _PartnerComparisonRow(
              name: p.name,
              ownership: p.ownership,
              profitShare: p.profitShare,
              percentage: totalProfit > 0
                  ? (p.profitShare / totalProfit) * 100
                  : 0,
              isSelected: p.name ==
                  _partnerOptions
                      .firstWhere((o) => o.id == _selectedPartnerId)
                      .name,
            ),
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

class _PartnerOption {
  final String id;
  final String name;
  final double capital;
  final double ownership;

  const _PartnerOption(this.id, this.name, this.capital, this.ownership);
}

class _PartnerCompareData {
  final String name;
  final double ownership;
  final double profitShare;
  final double contribution;

  const _PartnerCompareData(
      this.name, this.ownership, this.profitShare, this.contribution);
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
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
                '$ownership% ownership',
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
                    backgroundColor:
                        colorScheme.surfaceContainerHighest,
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
