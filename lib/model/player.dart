class Player {
  final int id;
  String name;
  int points;
  Set<int> opponents;
  bool hadBye;

  Player({
    required this.id,
    required this.name,
    this.points = 0,
    Set<int>? opponents,
    this.hadBye = false,
  }) : opponents = opponents ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points,
        'opponents': opponents.toList(),
        'hadBye': hadBye,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as int,
        name: json['name'] as String,
        points: json['points'] as int,
        opponents: (json['opponents'] as List).cast<int>().toSet(),
        hadBye: json['hadBye'] as bool,
      );
}

/// Buchholz score: sum of the current points of every opponent a player
/// has faced so far. Used as a tiebreaker when points are equal.
int buchholzFor(Player p, Map<int, Player> byId) {
  int total = 0;
  for (final oppId in p.opponents) {
    total += byId[oppId]?.points ?? 0;
  }
  return total;
}
