class SrsPreviewInput {
  final Duration againInterval;
  final Duration minInterval;
  final Duration maxInterval;
  final double easeFactor;
  final List<int> learningStepsMinutes;

  const SrsPreviewInput({
    required this.againInterval,
    required this.minInterval,
    required this.maxInterval,
    required this.easeFactor,
    this.learningStepsMinutes = const [],
  });

  SrsPreviewInput copyWith({
    Duration? againInterval,
    Duration? minInterval,
    Duration? maxInterval,
    double? easeFactor,
    List<int>? learningStepsMinutes,
  }) {
    return SrsPreviewInput(
      againInterval: againInterval ?? this.againInterval,
      minInterval: minInterval ?? this.minInterval,
      maxInterval: maxInterval ?? this.maxInterval,
      easeFactor: easeFactor ?? this.easeFactor,
      learningStepsMinutes: learningStepsMinutes ?? this.learningStepsMinutes,
    );
  }
}

class SrsPreviewResult {
  final Duration nextAfterAgain;
  final Duration nextAfterGood;
  final Duration nextAfterEasy;
  final String stageAfterAgain;
  final String stageAfterGood;
  final String stageAfterEasy;

  const SrsPreviewResult({
    required this.nextAfterAgain,
    required this.nextAfterGood,
    required this.nextAfterEasy,
    required this.stageAfterAgain,
    required this.stageAfterGood,
    required this.stageAfterEasy,
  });
}
