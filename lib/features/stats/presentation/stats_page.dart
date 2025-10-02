import 'dart:async';

import 'package:flutter/material.dart';

import '../data/stats_models.dart';
import '../data/stats_service.dart';
import '../services/onboarding_service.dart';
import 'widgets/accuracy_chart.dart';
import 'widgets/xp_chart.dart';
import 'widgets/mastery_distribution.dart';
import 'widgets/mastery_learned_grid.dart';
import 'widgets/stats_coachmark.dart';
import 'widgets/help_info_icon.dart';
import 'widgets/activity_chart.dart';
import 'widgets/range_switcher.dart';
import 'widgets/summary_cards.dart';

class StatsPage extends StatefulWidget {
  StatsPage({
    super.key,
    StatsService? service,
    OnboardingService? onboardingService,
  }) : _service = service ?? MockStatsService(),
       _onboardingService = onboardingService ?? OnboardingService();

  final StatsService _service;
  final OnboardingService _onboardingService;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsSummary? _summary;
  StatsTimeseries? _timeseries;
  MasteryDistribution? _masteryDistribution;
  StatsRange _range = StatsRange.d30;

  bool _loadingSummary = true;
  bool _loadingTimeseries = true;
  bool _loadingMastery = true;
  bool _showCoachmark = false;
  String? _summaryError;
  String? _masteryError;
  int? _selectedStar;
  String? _timeseriesError;

  final Map<StatsRange, StatsTimeseries> _cache = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadMastery();
    _loadTimeseries(_range, immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowCoachmark();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final summary = await widget._service.loadSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryError = null;
        _loadingSummary = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _summaryError = 'Error';
        _loadingSummary = false;
      });
    }
  }

  Future<void> _loadMastery() async {
    setState(() {
      _loadingMastery = true;
      _masteryError = null;
    });
    try {
      final mastery = await widget._service.loadMasteryDistribution();
      if (!mounted) return;
      setState(() {
        _masteryDistribution = mastery;
        _selectedStar = null;
        _loadingMastery = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _masteryDistribution = null;
        _selectedStar = null;
        _masteryError = error.toString();
        _loadingMastery = false;
      });
    }
  }

  Future<void> _maybeShowCoachmark() async {
    final seen = await widget._onboardingService.isStatsCoachmarkSeen();
    if (!mounted) {
      return;
    }
    if (!seen) {
      setState(() {
        _showCoachmark = true;
      });
    }
  }

  void _dismissCoachmark() {
    setState(() {
      _showCoachmark = false;
    });
    unawaited(widget._onboardingService.setStatsCoachmarkSeen(true));
  }

  void _loadTimeseries(StatsRange range, {bool immediate = false}) {
    _debounce?.cancel();
    setState(() {
      _range = range;
      _loadingTimeseries = !_cache.containsKey(range);
      _timeseriesError = null;
      if (_cache.containsKey(range)) {
        _timeseries = _cache[range];
      }
    });

    Future<void> fetch() async {
      try {
        final result = await widget._service.loadTimeseries(range: range);
        if (!mounted) return;
        setState(() {
          _cache[range] = result;
          if (_range == range) {
            _timeseries = result;
            _loadingTimeseries = false;
          }
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          if (_range == range) {
            _timeseriesError = error.toString();
            _loadingTimeseries = false;
          }
        });
      }
    }

    if (immediate) {
      unawaited(fetch());
    } else {
      _debounce = Timer(
        const Duration(milliseconds: 250),
        () => unawaited(fetch()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadSummary();
            await _loadMastery();
            _cache.clear();
            _loadTimeseries(_range, immediate: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryCardsRow(
                  loading: _loadingSummary,
                  summary: _summary,
                  error: _summaryError,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    StatsRangeSwitcher(
                      selected: _range,
                      onChanged: (range) => _loadTimeseries(range),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActivityLegend(context),
                const SizedBox(height: 12),
                _buildActivityCard(context),
                const SizedBox(height: 24),
                Text(
                  'Accuracy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildLegend(context, [
                  _LegendEntry(
                    color: Theme.of(context).colorScheme.secondary,
                    label: 'Accuracy',
                  ),
                ]),
                const SizedBox(height: 12),
                _buildAccuracyCard(context),
                const SizedBox(height: 24),
                Text('XP', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildLegend(context, [
                  _LegendEntry(
                    color: Theme.of(context).colorScheme.primary,
                    label: 'XP earned',
                  ),
                ]),
                const SizedBox(height: 12),
                _buildXpCard(context),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mastery distribution',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const HelpInfoIcon(
                      message:
                          "This bar shows how many kanji you've reviewed at each mastery level.",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMasteryCard(context),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (_showCoachmark) StatsCoachmark(onDismiss: _dismissCoachmark),
      ],
    );
  }

  Widget _buildActivityLegend(BuildContext context) {
    final palette = ActivityLegendColors.fromTheme(
      Theme.of(context).colorScheme,
    );
    return _buildLegend(context, [
      _LegendEntry(color: palette.newColor, label: 'New'),
      _LegendEntry(color: palette.reviewColor, label: 'Review'),
    ]);
  }

  Widget _buildLegend(BuildContext context, List<_LegendEntry> entries) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.label, style: textStyle),
            ],
          ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    final palette = ActivityLegendColors.fromTheme(
      Theme.of(context).colorScheme,
    );
    final series = _timeseries?.series ?? const <DailyStat>[];

    Widget buildBody() {
      if (_loadingTimeseries) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_timeseriesError != null) {
        return _ErrorBanner(message: _timeseriesError!);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ActivityChart(series: series, palette: palette),
          ),
        ],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 260, child: buildBody()),
      ),
    );
  }

  Widget _buildAccuracyCard(BuildContext context) {
    final series = _timeseries?.series ?? const <DailyStat>[];

    Widget buildBody() {
      if (_loadingTimeseries) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_timeseriesError != null) {
        return _ErrorBanner(message: _timeseriesError!);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: AccuracyChart(series: series))],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 220, child: buildBody()),
      ),
    );
  }

  Widget _buildXpCard(BuildContext context) {
    final series = _timeseries?.series ?? const <DailyStat>[];

    Widget buildBody() {
      if (_loadingTimeseries) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_timeseriesError != null) {
        return _ErrorBanner(message: _timeseriesError!);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: XpChart(series: series))],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 220, child: buildBody()),
      ),
    );
  }

  Widget _buildMasteryCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingMastery
            ? const Center(child: CircularProgressIndicator())
            : _masteryError != null
            ? _ErrorBanner(message: _masteryError!)
            : _masteryDistribution == null || _masteryDistribution!.isEmpty
            ? const Center(child: Text('No data yet'))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MasteryDistributionBar(
                    distribution: _masteryDistribution!,
                    selectedStar: _selectedStar,
                    onStarSelected: (star) {
                      setState(() {
                        _selectedStar = _selectedStar == star ? null : star;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  MasteryLearnedGrid(
                    star: _selectedStar,
                    service: widget._service,
                  ),
                ],
              ),
      ),
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
