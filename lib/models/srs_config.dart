// lib/models/srs_config.dart

enum SrsStrategy { balanced, front, shuffle }

class SrsConfig {
  final int maxNew;
  final int maxLearn;
  final int dailyCap;
  final bool prioritizeWrong;
  final SrsStrategy strategy;

  const SrsConfig({
    required this.maxNew,
    required this.maxLearn,
    required this.dailyCap,
    required this.prioritizeWrong,
    required this.strategy,
  });

  static const defaults = SrsConfig(
    maxNew: 20,
    maxLearn: 40,
    dailyCap: 200,
    prioritizeWrong: true,
    strategy: SrsStrategy.balanced,
  );

  SrsConfig copyWith({
    int? maxNew,
    int? maxLearn,
    int? dailyCap,
    bool? prioritizeWrong,
    SrsStrategy? strategy,
  }) {
    return SrsConfig(
      maxNew: maxNew ?? this.maxNew,
      maxLearn: maxLearn ?? this.maxLearn,
      dailyCap: dailyCap ?? this.dailyCap,
      prioritizeWrong: prioritizeWrong ?? this.prioritizeWrong,
      strategy: strategy ?? this.strategy,
    );
  }
}
