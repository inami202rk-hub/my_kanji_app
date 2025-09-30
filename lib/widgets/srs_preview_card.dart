import 'package:flutter/material.dart';

class SrsPreviewCard extends StatelessWidget {
  const SrsPreviewCard({
    super.key,
    required this.again,
    required this.good,
    required this.easy,
  });

  static const previewSectionKey = Key('srsPreviewSection');

  final Duration again;
  final Duration good;
  final Duration easy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(key: previewSectionKey, height: 0, width: 0),
            Text('SRS Tuning Preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _DurationRow(label: 'Again', value: _formatDuration(again)),
            const SizedBox(height: 8),
            _DurationRow(label: 'Good', value: _formatDuration(good)),
            const SizedBox(height: 8),
            _DurationRow(label: 'Easy', value: _formatDuration(easy)),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes <= 0) {
      return '0m';
    }
    const minutesPerDay = 24 * 60;
    final days = totalMinutes ~/ minutesPerDay;
    final hours = (totalMinutes % minutesPerDay) ~/ 60;
    final minutes = totalMinutes % 60;

    final parts = <String>[];
    if (days > 0) {
      parts.add('${days}d');
    }
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (parts.isEmpty || minutes > 0) {
      parts.add('${minutes}m');
    }
    return parts.join(' ');
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
