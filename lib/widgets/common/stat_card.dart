import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? changePercentage;
  final List<double>? sparklineData;
  final bool useGradient;
  final Color? backgroundColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.changePercentage,
    this.sparklineData,
    this.useGradient = false,
    this.backgroundColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPositive = changePercentage != null && changePercentage! >= 0;
    final changeColor = isPositive ? AppColors.profit : AppColors.loss;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: useGradient
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor ?? colorScheme.primary,
                      (backgroundColor ?? colorScheme.primary)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                )
              : null,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: useGradient
                          ? Colors.white.withValues(alpha: 0.2)
                          : (iconColor ?? colorScheme.primary)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: useGradient
                          ? Colors.white
                          : iconColor ?? colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (changePercentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 12,
                            color: changeColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${isPositive ? '+' : ''}${changePercentage!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: changeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: useGradient
                      ? Colors.white.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: useGradient
                      ? Colors.white
                      : colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sparklineData != null && sparklineData!.length >= 2) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 24,
                  child: SparklineChart(sparklineData!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SparklineChart extends StatelessWidget {
  final List<double> data;

  const SparklineChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    double findMin(List<double> list) => list.reduce((a, b) => a < b ? a : b);
    double findMax(List<double> list) => list.reduce((a, b) => a > b ? a : b);

    final dataMin = findMin(data);
    final dataMax = findMax(data);
    final range = (dataMax - dataMin).clamp(1.0, double.infinity);

    final spots = List.generate(
      data.length,
      (i) => FlSpot(
        i.toDouble(),
        (data[i] - dataMin) / range,
      ),
    );

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colorScheme.primary,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
