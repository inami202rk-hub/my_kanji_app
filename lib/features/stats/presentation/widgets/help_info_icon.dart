import 'package:flutter/material.dart';

class HelpInfoIcon extends StatefulWidget {
  const HelpInfoIcon({
    super.key,
    required this.message,
    this.dialogTitle = 'Mastery distribution',
    this.tooltipMaxWidth = 240,
    this.semanticLabel,
    this.tooltipText,
  });

  final String message;
  final String dialogTitle;
  final double tooltipMaxWidth;
  final String? semanticLabel;
  final String? tooltipText;

  @override
  State<HelpInfoIcon> createState() => _HelpInfoIconState();
}

class _HelpInfoIconState extends State<HelpInfoIcon> {
  bool _showTooltip = false;

  void _toggleTooltip() {
    setState(() {
      _showTooltip = !_showTooltip;
    });
  }

  void _hideTooltip() {
    if (!_showTooltip) {
      return;
    }
    setState(() {
      _showTooltip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: TapRegion(
        onTapOutside: (_) => _hideTooltip(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              label: widget.semanticLabel ?? 'Mastery distribution help',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: widget.semanticLabel ?? 'Mastery distribution help',
                onPressed: _toggleTooltip,
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ),
            if (_showTooltip)
              Positioned(
                right: 0,
                top: 36,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.tooltipMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.tooltipText != null) ...[
                            Text(
                              widget.tooltipText!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ] else ...[
                            Text(
                              widget.dialogTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
