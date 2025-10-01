import 'package:flutter/material.dart';

class StatsCoachmark extends StatelessWidget {
  const StatsCoachmark({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome to your Kanji Journey',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Track your progress and master kanji over time.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label: 'Dismiss coachmark',
                      button: true,
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        child: const Text('Got it'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
