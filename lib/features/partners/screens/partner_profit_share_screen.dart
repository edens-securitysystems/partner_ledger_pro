import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/models/entities/partner.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';

class PartnerProfitShareScreen extends ConsumerStatefulWidget {
  const PartnerProfitShareScreen({super.key});

  @override
  ConsumerState<PartnerProfitShareScreen> createState() => _PartnerProfitShareScreenState();
}

class _PartnerProfitShareScreenState extends ConsumerState<PartnerProfitShareScreen> {
  Partner? _partner;
  double _totalProfit = 0;
  double _profitShare = 0;
  List<_MonthlyProfit> _monthlyProfits = [];
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
        final transactionRepo = ref.read(transactionRepositoryProvider);
        final txResponse = await transactionRepo.filterByPartner(partner.id);

        if (mounted && txResponse.success && txResponse.data != null) {
          final transactions = txResponse.data!;
          double totalIncome = 0;
          final monthlyMap = <String, double>{};

          for (final tx in transactions) {
            if (tx.type.value == 3) {
              totalIncome += tx.amount;
              final monthKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
              monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + tx.amount;
            }
          }

          final monthlyProfits = monthlyMap.entries.map((e) {
            final parts = e.key.split('-');
            return _MonthlyProfit(
              month: _monthName(int.parse(parts[1])),
              year: int.parse(parts[0]),
              amount: e.value,
            );
          }).toList();
          monthlyProfits.sort((a, b) => a.year.compareTo(b.year));

          setState(() {
            _partner = partner;
            _totalProfit = totalIncome;
            _profitShare = partner.totalInvestment(totalIncome);
            _monthlyProfits = monthlyProfits;
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profit Share'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(theme, colorScheme),
                    const SizedBox(height: 20),
                    if (_partner != null) _buildOwnershipBar(theme, colorScheme),
                    const SizedBox(height: 20),
                    if (_monthlyProfits.isNotEmpty) _buildChartCard(theme, colorScheme),
                    const SizedBox(height: 20),
                    _buildBreakdownCard(theme, colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.profit, AppColors.profit.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.profit.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            'Your Profit Share',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_profitShare.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(Colors.white, 'Ownership: ${_partner?.ownershipPercentage.toStringAsFixed(1)}%'),
              const SizedBox(width: 12),
              _chip(Colors.white, 'Total Profit: ₹${_totalProfit.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOwnershipBar(ThemeData theme, ColorScheme colorScheme) {
    final ownership = _partner!.ownershipPercentage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ownership Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: (ownership * 10).toInt(),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: ((100 - ownership) * 10).toInt(),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You: ${ownership.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Others: ${(100 - ownership).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, ColorScheme colorScheme) {
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
            'Monthly Profit Trend',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _monthlyProfits.map((m) => m.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                barGroups: _monthlyProfits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final mp = entry.value;
                  final share = mp.amount * (_partner?.ownershipPercentage ?? 0) / 100;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: share,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        color: colorScheme.primary,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < _monthlyProfits.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _monthlyProfits[idx].month.substring(0, 3),
                              style: TextStyle(
                                fontSize: 10,
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
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (_monthlyProfits.map((m) => m.amount).reduce((a, b) => a > b ? a : b) / 4),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ThemeData theme, ColorScheme colorScheme) {
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
            'Profit Calculation',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _calcRow(theme, 'Total Business Profit', '₹${_totalProfit.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _calcRow(theme, 'Your Ownership', '${_partner?.ownershipPercentage.toStringAsFixed(1)}%'),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Profit Share',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '₹${_profitShare.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.profit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }
}

class _MonthlyProfit {
  final String month;
  final int year;
  final double amount;

  _MonthlyProfit({
    required this.month,
    required this.year,
    required this.amount,
  });
}
