import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/stats_models.dart';
import '../../services/stats_empty_utils.dart';
import 'stats_skeleton.dart';

class AccuracyChart extends StatelessWidget {
  const AccuracyChart({
    super.key,
    required this.series,
    this.isLoading = false,
  });

  final List<DailyStat> series;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const StatsCardSkeleton(height: 220);
    }

    final timeseries = StatsTimeseries(
      series: series,
      streak: 0,
      bestStreak: 0,
    );
    if (StatsEmptyUtils.isAccuracyEmpty(timeseries)) {
      return const StatsEmptyCard(
        message: 'No answers yet — complete a session to see accuracy.',
        icon: Icons.insights_outlined,
        height: 220,
      );
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final labels = <String>[];
    final spots = <FlSpot>[];

    for (var i = 0; i < series.length; i++) {
      final stat = series[i];
      labels.add(DateFormat.Md(localeTag).format(stat.date));
      spots.add(FlSpot(i.toDouble(), stat.accuracyPercent));
    }

    final lineColor = theme.colorScheme.secondary;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: _buildTitles(theme, labels),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 80,
              dashArray: const [6, 4],
              strokeWidth: 1.5,
              color: lineColor.withValues(alpha: 0.7),
            ),
          ],
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.25),
                  lineColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.round();
                final safeIndex = index.clamp(0, series.length - 1);
                final stat = series[safeIndex];
                final dateText = DateFormat.yMMMd(localeTag).format(stat.date);
                final percentText = '${spot.y.toStringAsFixed(1)}%';
                final titleStyle =
                    theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.w600);
                final bodyStyle =
                    theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
                return LineTooltipItem(
                  '$dateText\n',
                  titleStyle,
                  children: [TextSpan(text: percentText, style: bodyStyle)],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(ThemeData theme, List<String> labels) {
    final labelCount = labels.length;
    final step = labelCount > 6 ? (labelCount / 6).ceil() : 1;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text('${value.toInt()}%', style: theme.textTheme.bodySmall);
          },
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
}
