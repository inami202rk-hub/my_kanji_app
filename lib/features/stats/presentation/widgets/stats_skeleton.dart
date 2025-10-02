import 'package:flutter/material.dart';

/// A lightweight skeleton widget for loading states in stats cards
class StatsCardSkeleton extends StatefulWidget {
  const StatsCardSkeleton({
    super.key,
    this.height = 140,
  });

  final double height;

  @override
  State<StatsCardSkeleton> createState() => _StatsCardSkeletonState();
}

class _StatsCardSkeletonState extends State<StatsCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _animation.value,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simulate chart bars/lines with animated containers
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final height = (index % 3 + 1) * 20.0;
                      return Container(
                        width: 12,
                        height: height,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(
                            alpha: _animation.value * 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Simulate axis labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    return Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(
                          alpha: _animation.value * 0.4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Empty state card widget for stats charts
class StatsEmptyCard extends StatelessWidget {
  const StatsEmptyCard({
    super.key,
    required this.message,
    this.icon = Icons.bar_chart,
    this.height = 140,
  });

  final String message;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
