import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartDataItem {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const PieChartDataItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class PieChartWidget extends StatelessWidget {
  final List<PieChartDataItem> data;
  final double height;
  final bool showAsDonut;
  final double innerRadius;
  final String? title;
  final String? centerText;
  final double? centerValue;

  const PieChartWidget({
    super.key,
    required this.data,
    this.height = 250,
    this.showAsDonut = true,
    this.innerRadius = 0.55,
    this.title,
    this.centerText,
    this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: List.generate(
                            data.length,
                            (i) => PieChartSectionData(
                              value: data[i].value,
                              color: data[i].color,
                              radius: showAsDonut ? 28 : 35,
                              title: '',
                              badgeWidget: data[i].icon != null
                                  ? Icon(
                                      data[i].icon,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                              badgePositionPercentageOffset: 0.5,
                            ),
                          ),
                          centerSpaceRadius:
                              showAsDonut ? height * innerRadius : 0,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                      if (showAsDonut && centerText != null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerText!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (centerValue != null)
                              Text(
                                _formatValue(centerValue!),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: showAsDonut ? 3 : 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      data.length.clamp(0, 6),
                      (i) {
                        final item = data[i];
                        final percentage =
                            total > 0 ? (item.value / total) * 100 : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
