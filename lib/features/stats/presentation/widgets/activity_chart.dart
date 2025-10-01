import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/stats_models.dart';

class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.series});

  final List<DailyStat> series;

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

    return BarChart(
      BarChartData(
        maxY: highest.toDouble(),
        barGroups: _buildGroups(context),
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceBetween,
        barTouchData: _buildTouchData(context, localeTag),
        titlesData: _buildTitles(context, labels),
        borderData: FlBorderData(show: false),
      ),
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
    final tooltipStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);
    final bodyStyle =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final stat = series[group.x.toInt()];
          final date = DateFormat.yMMMd(localeTag).format(stat.date);
          return BarTooltipItem(
            '$date\n',
            tooltipStyle,
            children: [
              TextSpan(text: 'Reviews: ${stat.reviews}\n', style: bodyStyle),
              TextSpan(text: 'New cards: ${stat.newCards}', style: bodyStyle),
            ],
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildGroups(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorNew = colorScheme.primary;
    final colorReview = colorScheme.primaryContainer;

    return [
      for (final entry in series.asMap().entries)
        BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.reviews.toDouble(),
              borderRadius: BorderRadius.circular(6),
              rodStackItems: [
                BarChartRodStackItem(
                  0,
                  entry.value.newCards.toDouble(),
                  colorNew,
                ),
                BarChartRodStackItem(
                  entry.value.newCards.toDouble(),
                  entry.value.reviews.toDouble(),
                  colorReview,
                ),
              ],
            ),
          ],
        ),
    ];
  }
}
