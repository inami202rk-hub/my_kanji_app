import 'package:flutter/material.dart';

import '../../data/stats_models.dart';

class KanjiDetailModal extends StatelessWidget {
  const KanjiDetailModal({super.key, required this.item});

  final KanjiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const badgeGlyph = 'Åö';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.char,
                  style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 64,
                      ) ??
                      const TextStyle(fontSize: 64, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeGlyph${item.stars}',
                      style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.meaning,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.hint,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModalActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onPressed: () {
                      // TODO: hook up Kanji editor.
                    },
                  ),
                  _ModalActionButton(
                    icon: Icons.volume_up_outlined,
                    label: 'Audio',
                    onPressed: () {
                      // TODO: play Kanji audio.
                    },
                  ),
                  _ModalActionButton(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    onPressed: () {
                      // TODO: open notes.
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalActionButton extends StatelessWidget {
  const _ModalActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: onPressed,
          radius: 28,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
