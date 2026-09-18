class RoundResult {
  final int round;
  final List<String> pairSummaries;
  final String? byeName;
  RoundResult({required this.round, required this.pairSummaries, this.byeName});

  Map<String, dynamic> toJson() => {
        'round': round,
        'pairSummaries': pairSummaries,
        'byeName': byeName,
      };

  factory RoundResult.fromJson(Map<String, dynamic> json) => RoundResult(
        round: json['round'] as int,
        pairSummaries: (json['pairSummaries'] as List).cast<String>(),
        byeName: json['byeName'] as String?,
      );
}
