import 'package:flutter/material.dart';

import '../../data/stats_models.dart';

class StatsRangeSwitcher extends StatelessWidget {
  const StatsRangeSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final ranges = StatsRange.values;
    return SegmentedButton<StatsRange>(
      segments: [
        for (final range in ranges)
          ButtonSegment<StatsRange>(value: range, label: Text(range.label())),
      ],
      selected: <StatsRange>{selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
    );
  }
}
