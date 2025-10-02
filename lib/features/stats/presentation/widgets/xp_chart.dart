import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/stats_models.dart';

class XpChart extends StatelessWidget {
  const XpChart({super.key, required this.series});

  final List<DailyStat> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((stat) => stat.xp <= 0)) {
      return const Center(child: Text('No data yet'));
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final bars = <BarChartGroupData>[];
    final labels = <String>[];

    var maxXp = 0;
    for (var i = 0; i < series.length; i++) {
      final stat = series[i];
      labels.add(DateFormat.Md(localeTag).format(stat.date));
      final xpValue = stat.xp;
      if (xpValue > maxXp) {
        maxXp = xpValue;
      }
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: xpValue.toDouble(),
              borderRadius: BorderRadius.circular(6),
              width: 18,
              fromY: 0,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      );
    }

    final maxY = _niceCeiling(maxXp.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 12,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: math.max(maxY / 4, 1),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: bars,
              titlesData: _buildTitles(theme, labels),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x.toInt().clamp(0, series.length - 1);
                    final stat = series[index];
                    final dateText = DateFormat.yMMMd(
                      localeTag,
                    ).format(stat.date);
                    final xpText = '${stat.xp} XP';
                    final titleStyle =
                        theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(fontWeight: FontWeight.w600);
                    final bodyStyle =
                        theme.textTheme.bodySmall ??
                        const TextStyle(fontSize: 12);
                    return BarTooltipItem(
                      '$dateText\n',
                      titleStyle,
                      children: [TextSpan(text: xpText, style: bodyStyle)],
                    );
                  },
                ),
              ),
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
          color: theme.colorScheme.primary,
          label: 'XP earned',
          textStyle: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  FlTitlesData _buildTitles(ThemeData theme, List<String> labels) {
    const reservedHeight = 36.0;
    final labelCount = labels.length;
    final step = labelCount > 6 ? (labelCount / 6).ceil() : 1;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) =>
              Text(value.toInt().toString(), style: theme.textTheme.bodySmall),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reservedHeight,
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

  double _niceCeiling(double value) {
    if (value <= 0) {
      return 10;
    }
    final log10 = math.log(value) / math.ln10;
    final power = log10.floor();
    final magnitude = math.pow(10, power).toDouble();
    final scaled = value / magnitude;
    double nice;
    if (scaled <= 1) {
      nice = 1;
    } else if (scaled <= 2) {
      nice = 2;
    } else if (scaled <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
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
