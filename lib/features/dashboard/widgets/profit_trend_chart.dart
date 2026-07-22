import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../theme/app_colors.dart';
import '../providers/dashboard_provider.dart';

class ProfitTrendChart extends ConsumerWidget {
  const ProfitTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitSummary = ref.watch(dashboardProfitSummaryProvider);

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
                    color: AppColors.profit.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    size: 18,
                    color: AppColors.profit,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profit Trend',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'Last 12 months performance',
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
                if (profitSummary != null)
                  _ProfitBadge(
                    change: profitSummary.monthOverMonthChange,
                    isPositive: profitSummary.isMonthOverMonthPositive,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (profitSummary == null)
            const _ProfitTrendShimmer()
          else
            _ProfitTrendLine(
              breakdown: profitSummary.monthlyBreakdown,
              currentProfit: profitSummary.currentMonthProfit,
            ),
        ],
      ),
    );
  }
}

class _ProfitBadge extends StatelessWidget {
  final double change;
  final bool isPositive;

  const _ProfitBadge({required this.change, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.profit : AppColors.loss;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitTrendLine extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;
  final double currentProfit;

  const _ProfitTrendLine({
    required this.breakdown,
    required this.currentProfit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<double> values = [];
    List<String> labels = [];

    if (breakdown.isNotEmpty) {
      for (final item in breakdown) {
        final value = (item['profit'] as num?)?.toDouble() ?? 0.0;
        final label = (item['month'] as String?) ?? '';
        values.add(value);
        labels.add(label);
      }
    }

    if (values.isEmpty) {
      values = List.generate(12, (i) => currentProfit * (0.6 + (i * 0.04)));
      labels = List.generate(12, (i) {
        final month = DateTime.now().subtract(Duration(days: 30 * (11 - i)));
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return months[month.month - 1];
      });
    }

    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final yRange = (dataMax - dataMin).abs().clamp(1.0, double.infinity);
    final padding = yRange * 0.15;

    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: LineChart(
          LineChartData(
            minY: dataMin - padding,
            maxY: dataMax + padding,
            gridData: FlGridData(
              show: true,
              horizontalInterval: yRange / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.outlineVariant,
                  strokeWidth: 0.5,
                );
              },
              drawVerticalLine: false,
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
                  interval: (values.length / 6).ceil().toDouble(),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[idx],
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
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      _formatYAxis(spot.y),
                      TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.profit,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: values.length <= 12,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.profit,
                      strokeWidth: 2,
                      strokeColor: colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.profit.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatYAxis(double value) {
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _ProfitTrendShimmer extends StatelessWidget {
  const _ProfitTrendShimmer();

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
          child: CustomPaint(
            painter: _ShimmerLinePainter(),
            size: const Size(double.infinity, double.infinity),
          ),
        ),
      ),
    );
  }
}

class _ShimmerLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.6,
      size.width * 0.75,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
