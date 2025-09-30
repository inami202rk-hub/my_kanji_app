import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/srs_preview.dart';
import '../utils/duration_format.dart';

class SrsPreviewCard extends StatefulWidget {
  const SrsPreviewCard({
    super.key,
    required this.draft,
    required this.result,
    required this.onChanged,
    required this.onReset,
    required this.onSave,
    required this.saveEnabled,
    this.fieldErrors = const {},
  });

  final SrsPreviewInput draft;
  final SrsPreviewResult? result;
  final void Function(SrsPreviewInput) onChanged;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool saveEnabled;
  final Map<String, String?> fieldErrors;

  @override
  State<SrsPreviewCard> createState() => _SrsPreviewCardState();
}

class _SrsPreviewCardState extends State<SrsPreviewCard> {
  late final TextEditingController _againController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _againController = TextEditingController();
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant SrsPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.againInterval != widget.draft.againInterval ||
        oldWidget.draft.minInterval != widget.draft.minInterval ||
        oldWidget.draft.maxInterval != widget.draft.maxInterval) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _againController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _againController.text = widget.draft.againInterval.inMinutes.toString();
    _minController.text = widget.draft.minInterval.inMinutes.toString();
    _maxController.text = widget.draft.maxInterval.inMinutes.toString();
  }

  void _updateDraft({
    Duration? again,
    Duration? min,
    Duration? max,
    double? ease,
  }) {
    widget.onChanged(
      widget.draft.copyWith(
        againInterval: again,
        minInterval: min,
        maxInterval: max,
        easeFactor: ease,
      ),
    );
  }

  void _handleMinutesChange(
    TextEditingController controller,
    void Function(Duration duration) apply,
  ) {
    final value = int.tryParse(controller.text);
    if (value == null) {
      return;
    }
    apply(Duration(minutes: value));
  }

  void _incrementField(
    TextEditingController controller,
    void Function(Duration duration) apply,
    int delta,
  ) {
    final value = int.tryParse(controller.text) ?? 0;
    final next = (value + delta).clamp(1, 365 * 24 * 60).toInt();
    controller.text = next.toString();
    apply(Duration(minutes: next));
  }

  void _applyAgain(Duration duration) => _updateDraft(again: duration);
  void _applyMin(Duration duration) => _updateDraft(min: duration);
  void _applyMax(Duration duration) => _updateDraft(max: duration);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('SRS Tuning Preview', style: theme.textTheme.titleMedium),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Draft',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OutcomeTile(
                  label: 'Again',
                  interval: result?.nextAfterAgain,
                  stage: result?.stageAfterAgain,
                ),
                _OutcomeTile(
                  label: 'Good',
                  interval: result?.nextAfterGood,
                  stage: result?.stageAfterGood,
                ),
                _OutcomeTile(
                  label: 'Easy',
                  interval: result?.nextAfterEasy,
                  stage: result?.stageAfterEasy,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEaseControl(context),
            const SizedBox(height: 16),
            _buildMinutesField(
              context,
              label: 'Again interval (minutes)',
              controller: _againController,
              apply: _applyAgain,
              errorText: widget.fieldErrors['again'],
            ),
            const SizedBox(height: 12),
            _buildMinutesField(
              context,
              label: 'Min review interval (minutes)',
              controller: _minController,
              apply: _applyMin,
              errorText: widget.fieldErrors['min'],
            ),
            const SizedBox(height: 12),
            _buildMinutesField(
              context,
              label: 'Max review interval (minutes)',
              controller: _maxController,
              apply: _applyMax,
              errorText: widget.fieldErrors['max'],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onReset,
                  child: const Text('Reset'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: widget.saveEnabled ? widget.onSave : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEaseControl(BuildContext context) {
    final theme = Theme.of(context);
    final ease = widget.draft.easeFactor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('Ease factor'), Text(ease.toStringAsFixed(2))],
        ),
        Slider(
          value: ease.clamp(1.3, 3.0),
          min: 1.3,
          max: 3.0,
          divisions: 17,
          label: ease.toStringAsFixed(2),
          onChanged: (value) => _updateDraft(ease: value),
        ),
        if (widget.fieldErrors['ease'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.fieldErrors['ease']!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMinutesField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required void Function(Duration duration) apply,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Row(
          children: [
            _StepperButton(
              icon: Icons.remove,
              onPressed: () => _incrementField(controller, apply, -1),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onEditingComplete: () {
                  _handleMinutesChange(controller, apply);
                  FocusScope.of(context).unfocus();
                },
                onSubmitted: (_) => _handleMinutesChange(controller, apply),
                onChanged: (_) => _handleMinutesChange(controller, apply),
              ),
            ),
            _StepperButton(
              icon: Icons.add,
              onPressed: () => _incrementField(controller, apply, 1),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({required this.label, this.interval, this.stage});

  final String label;
  final Duration? interval;
  final String? stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intervalLabel = interval != null ? formatCompact(interval!) : '...';
    final stageLabel = stage ?? '?';
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(intervalLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              stageLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), onPressed: onPressed);
  }
}
