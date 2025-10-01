import 'package:flutter/material.dart';

import '../../data/stats_models.dart';

class SummaryCardsRow extends StatelessWidget {
  const SummaryCardsRow({super.key, required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final accuracyText = summary.formatAccuracy(localeTag);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Words',
            primary: summary.learnedWords.toString(),
            caption: '$accuracyText correct',
            icon: Icons.menu_book_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Streak',
            primary: summary.streak.toString(),
            caption: 'Highest: ${summary.bestStreak}',
            icon: Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.primary,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String primary;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(primary, style: primaryStyle),
            const SizedBox(height: 4),
            Text(caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
