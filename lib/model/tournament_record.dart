import 'round_result.dart';

/// One standings row frozen at the moment a tournament finished.
class StandingEntry {
  final String name;
  final int points;
  final int buchholz;

  StandingEntry({required this.name, required this.points, required this.buchholz});

  Map<String, dynamic> toJson() => {
        'name': name,
        'points': points,
        'buchholz': buchholz,
      };

  factory StandingEntry.fromJson(Map<String, dynamic> json) => StandingEntry(
        name: json['name'] as String,
        points: json['points'] as int,
        buchholz: json['buchholz'] as int,
      );
}

/// A completed tournament, saved so it can be browsed later.
class TournamentRecord {
  final String id; // timestamp-based, also used as sort key
  final DateTime finishedAt;
  final int playerCount;
  final int totalRounds;
  final List<StandingEntry> standings; // already sorted, winner first
  final List<RoundResult> history;

  TournamentRecord({
    required this.id,
    required this.finishedAt,
    required this.playerCount,
    required this.totalRounds,
    required this.standings,
    required this.history,
  });

  String get winnerName => standings.isNotEmpty ? standings.first.name : '—';
  int get winnerPoints => standings.isNotEmpty ? standings.first.points : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'finishedAt': finishedAt.toIso8601String(),
        'playerCount': playerCount,
        'totalRounds': totalRounds,
        'standings': standings.map((s) => s.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory TournamentRecord.fromJson(Map<String, dynamic> json) => TournamentRecord(
        id: json['id'] as String,
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        playerCount: json['playerCount'] as int,
        totalRounds: json['totalRounds'] as int,
        standings: (json['standings'] as List)
            .map((s) => StandingEntry.fromJson(s as Map<String, dynamic>))
            .toList(),
        history: (json['history'] as List)
            .map((h) => RoundResult.fromJson(h as Map<String, dynamic>))
            .toList(),
      );
}
