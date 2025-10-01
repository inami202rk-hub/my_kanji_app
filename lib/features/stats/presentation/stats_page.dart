import 'dart:async';

import 'package:flutter/material.dart';

import '../data/stats_models.dart';
import '../data/stats_service.dart';
import 'widgets/accuracy_chart.dart';
import 'widgets/xp_chart.dart';
import 'widgets/mastery_distribution.dart';
import 'widgets/mastery_learned_grid.dart';
import 'widgets/activity_chart.dart';
import 'widgets/range_switcher.dart';
import 'widgets/summary_cards.dart';

class StatsPage extends StatefulWidget {
  StatsPage({super.key, StatsService? service})
    : _service = service ?? MockStatsService();

  final StatsService _service;

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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
    });
    try {
      final summary = await widget._service.loadSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
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
    return Scaffold(
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
                if (_loadingSummary)
                  const _SummaryPlaceholder()
                else if (_summary != null)
                  SummaryCardsRow(summary: _summary!)
                else
                  const _ErrorBanner(message: 'Failed to load summary'),
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
                const SizedBox(height: 12),
                _buildActivityCard(context),
                const SizedBox(height: 24),
                Text(
                  'Accuracy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildAccuracyCard(context),
                const SizedBox(height: 24),
                Text('XP', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildXpCard(context),
                const SizedBox(height: 24),
                Text('Mastery', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildMasteryCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 260,
          child: _loadingTimeseries
              ? const Center(child: CircularProgressIndicator())
              : _timeseriesError != null
              ? _ErrorBanner(message: _timeseriesError!)
              : _timeseries == null
              ? const _ErrorBanner(message: 'No data yet')
              : ActivityChart(series: _timeseries!.series),
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: _loadingTimeseries
              ? const Center(child: CircularProgressIndicator())
              : _timeseriesError != null
              ? _ErrorBanner(message: _timeseriesError!)
              : _timeseries == null || _timeseries!.series.isEmpty
              ? const Center(child: Text('No data yet'))
              : AccuracyChart(series: _timeseries!.series),
        ),
      ),
    );
  }

  Widget _buildXpCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: _loadingTimeseries
              ? const Center(child: CircularProgressIndicator())
              : _timeseriesError != null
              ? _ErrorBanner(message: _timeseriesError!)
              : _timeseries == null || _timeseries!.series.isEmpty
              ? const Center(child: Text('No data yet'))
              : XpChart(series: _timeseries!.series),
        ),
      ),
    );
  }

  Widget _buildMasteryCard(BuildContext context) {
    const starGlyph = '\u2605';
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

class _SummaryPlaceholder extends StatelessWidget {
  const _SummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholderColor = scheme.surfaceContainerHighest;
    return Row(
      children: [
        Expanded(child: _ShimmerCard(color: placeholderColor)),
        const SizedBox(width: 16),
        Expanded(child: _ShimmerCard(color: placeholderColor)),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator.adaptive(),
      ),
    );
  }
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
