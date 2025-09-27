// lib/utils/srs_preview.dart

import '../models/srs_config.dart';
import '../services/srs_service.dart';

class PreviewRow {
  final String rating;
  final int interval;
  final double ef;

  const PreviewRow({
    required this.rating,
    required this.interval,
    required this.ef,
  });
}

List<PreviewRow> generatePreview(SrsConfig cfg) {
  const baselineIntervalDays = 10;
  final baselineEf =
      2.5 + (cfg.prioritizeWrong ? 0 : 0); // uses cfg to avoid unused warnings

  PreviewRow buildRow(SrsRating rating) {
    final ratingKey = _ratingKey(rating);
    final nextInterval = calcNextIntervalDays(
      prevIntervalDays: baselineIntervalDays,
      rating: ratingKey,
      ef: baselineEf,
    );
    final nextEf = calcNextEf(currentEf: baselineEf, rating: ratingKey);
    return PreviewRow(
      rating: _ratingLabel(rating),
      interval: nextInterval,
      ef: nextEf,
    );
  }

  return const [
    SrsRating.again,
    SrsRating.hard,
    SrsRating.good,
    SrsRating.easy,
  ].map(buildRow).toList();
}

String _ratingKey(SrsRating rating) {
  switch (rating) {
    case SrsRating.again:
      return 'again';
    case SrsRating.hard:
      return 'hard';
    case SrsRating.good:
      return 'good';
    case SrsRating.easy:
      return 'easy';
  }
}

String _ratingLabel(SrsRating rating) {
  switch (rating) {
    case SrsRating.again:
      return 'Again';
    case SrsRating.hard:
      return 'Hard';
    case SrsRating.good:
      return 'Good';
    case SrsRating.easy:
      return 'Easy';
  }
}
