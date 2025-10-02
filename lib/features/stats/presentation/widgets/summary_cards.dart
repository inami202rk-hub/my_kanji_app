import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/stats_models.dart';

enum _SummaryCardState { loading, empty, error, data }

class SummaryCardsRow extends StatelessWidget {
  const SummaryCardsRow({
    super.key,
    required this.loading,
    this.summary,
    this.error,
  });

  final bool loading;
  final StatsSummary? summary;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final state = loading
        ? _SummaryCardState.loading
        : error != null
        ? _SummaryCardState.error
        : summary == null
        ? _SummaryCardState.empty
        : _SummaryCardState.data;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final percentFormatter = NumberFormat.decimalPattern(localeTag)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    final accuracyPrimary = summary != null
        ? '${percentFormatter.format(summary!.totalAccuracy * 100)}%'
        : null;

    final streakCaption = summary != null
        ? 'Highest: ${summary!.bestStreak}'
        : null;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Words',
            icon: Icons.menu_book_outlined,
            state: state,
            primary: summary?.learnedWords.toString(),
            caption: 'Lifetime total',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Accuracy',
            icon: Icons.check_circle_outline,
            state: state,
            primary: accuracyPrimary,
            caption: 'Overall accuracy',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Streak',
            icon: Icons.local_fire_department_outlined,
            state: state,
            primary: summary?.streak.toString(),
            caption: streakCaption,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.state,
    this.primary,
    this.caption,
  });

  final String title;
  final IconData icon;
  final _SummaryCardState state;
  final String? primary;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget body;
    switch (state) {
      case _SummaryCardState.loading:
        body = const _SummaryStateContainer(child: CircularProgressIndicator());
        break;
      case _SummaryCardState.error:
        body = const _SummaryStateContainer(child: Text('Error'));
        break;
      case _SummaryCardState.empty:
        body = const _SummaryStateContainer(child: Text('No data'));
        break;
      case _SummaryCardState.data:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primary ?? '--',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (caption != null)
              Text(caption!, style: theme.textTheme.bodySmall),
          ],
        );
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

class _SummaryStateContainer extends StatelessWidget {
  const _SummaryStateContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 48, child: Center(child: child));
  }
}
