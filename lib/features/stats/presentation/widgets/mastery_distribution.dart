import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/stats_models.dart';

class MasteryDistributionBar extends StatelessWidget {
  const MasteryDistributionBar({
    super.key,
    required this.distribution,
    required this.selectedStar,
    required this.onStarSelected,
  });

  final MasteryDistribution distribution;
  final int? selectedStar;
  final ValueChanged<int> onStarSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final barRadius = BorderRadius.circular(12);

    final segments = <Widget>[];
    for (var i = 0; i < 5; i++) {
      final star = i + 1;
      final count = distribution.countForStar(star);
      final flex = math.max(count, 1);
      final isSelected = selectedStar == star;
      final segmentColor = _segmentColor(scheme, star, isSelected);
      segments.add(
        Expanded(
          flex: flex,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: i == 0 ? 0 : 4,
              end: i == 4 ? 0 : 4,
            ),
            child: _MasterySegment(
              star: star,
              count: count,
              isSelected: isSelected,
              color: segmentColor,
              onTap: () => onStarSelected(star),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: barRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(children: segments),
      ),
    );
  }

  Color _segmentColor(ColorScheme scheme, int star, bool isSelected) {
    if (isSelected) {
      return scheme.primary;
    }
    final t = (5 - star) / 6.0;
    return Color.lerp(scheme.primary, scheme.surface, t) ?? scheme.primary;
  }
}

class _MasterySegment extends StatelessWidget {
  const _MasterySegment({
    required this.star,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final int star;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final starLabel = '$star${String.fromCharCode(0x2605)}';
    final countLabel = '$count';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                countLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                starLabel,
                style: theme.textTheme.labelSmall?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state message for mastery distribution section
class MasteryEmptyMessage extends StatelessWidget {
  const MasteryEmptyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'No mastery yet — review more to see progress.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
