import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/stats_models.dart';

class ActivityLegendColors {
  const ActivityLegendColors({
    required this.newColor,
    required this.reviewColor,
  });

  final Color newColor;
  final Color reviewColor;

  factory ActivityLegendColors.fromTheme(ColorScheme scheme) {
    return ActivityLegendColors(
      newColor: scheme.primary,
      reviewColor: scheme.tertiary,
    );
  }
}

class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.series, required this.palette});

  final List<DailyStat> series;
  final ActivityLegendColors palette;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No data yet'));
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final labels = [
      for (final stat in series) DateFormat.Md(localeTag).format(stat.date),
    ];
    final highest = series
        .fold<int>(
          0,
          (maxValue, stat) => stat.reviews > maxValue ? stat.reviews : maxValue,
        )
        .clamp(4, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: highest.toDouble(),
              barGroups: _buildGroups(),
              gridData: const FlGridData(show: false),
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 12,
              barTouchData: _buildTouchData(context, localeTag),
              titlesData: _buildTitles(context, labels),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(
          color: palette.newColor,
          label: 'New',
          textStyle: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: palette.reviewColor,
          label: 'Review',
          textStyle: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  FlTitlesData _buildTitles(BuildContext context, List<String> labels) {
    final theme = Theme.of(context);
    final labelCount = labels.length;
    final step = labelCount > 6 ? (labelCount / 6).ceil() : 1;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (value, meta) =>
              Text(value.toInt().toString(), style: theme.textTheme.bodySmall),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) {
              return const SizedBox.shrink();
            }
            final isEdge = index == 0 || index == labels.length - 1;
            final shouldShow = isEdge || index % step == 0;
            if (!shouldShow) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(labels[index], style: theme.textTheme.bodySmall),
            );
          },
        ),
      ),
    );
  }

  BarTouchData _buildTouchData(BuildContext context, String localeTag) {
    final theme = Theme.of(context);
    final tooltipStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);
    final bodyStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final index = group.x.toInt().clamp(0, series.length - 1);
          final stat = series[index];
          final date = DateFormat.yMMMd(localeTag).format(stat.date);
          final reviewCount = (stat.reviews - stat.newCards).clamp(
            0,
            stat.reviews,
          );
          return BarTooltipItem(
            '$date\n',
            tooltipStyle,
            children: [
              TextSpan(text: 'New: ${stat.newCards}\n', style: bodyStyle),
              TextSpan(text: 'Review: $reviewCount\n', style: bodyStyle),
              TextSpan(text: 'Total: ${stat.reviews}', style: bodyStyle),
            ],
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildGroups() {
    return [
      for (final entry in series.asMap().entries)
        BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.reviews.toDouble(),
              width: 18,
              borderRadius: BorderRadius.circular(6),
              rodStackItems: [
                BarChartRodStackItem(
                  0,
                  entry.value.newCards.toDouble(),
                  palette.newColor,
                ),
                BarChartRodStackItem(
                  entry.value.newCards.toDouble(),
                  entry.value.reviews.toDouble(),
                  palette.reviewColor,
                ),
              ],
            ),
          ],
        ),
    ];
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textStyle,
  });

  final Color color;
  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}
