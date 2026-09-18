import '../model/player.dart';

int calcRounds(int n) {
  if (n < 2) return 0;
  if (n <= 8) return 3;
  if (n <= 16) return 4;
  if (n <= 32) return 5;
  if (n <= 64) return 6;
  if (n <= 128) return 7;
  if (n <= 226) return 8;
  return 9;
}

class PairingResult {
  final List<List<Player>> pairs;
  final Player? bye;
  PairingResult(this.pairs, this.bye);
}

PairingResult pairRound(List<Player> players) {
  final sorted = [...players]
    ..sort((a, b) {
      final c = b.points.compareTo(a.points);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final pool = [...sorted];
  Player? byePlayer;

  if (pool.length % 2 == 1) {
    int idx = pool.lastIndexWhere((p) => !p.hadBye);
    if (idx == -1) idx = pool.length - 1;
    byePlayer = pool.removeAt(idx);
  }

  final used = <int>{};
  final pairs = <List<Player>>[];
  for (int i = 0; i < pool.length; i++) {
    final p1 = pool[i];
    if (used.contains(p1.id)) continue;
    int matched = -1;
    for (int j = i + 1; j < pool.length; j++) {
      final p2 = pool[j];
      if (used.contains(p2.id)) continue;
      if (!p1.opponents.contains(p2.id)) {
        matched = j;
        break;
      }
    }
    if (matched == -1) {
      for (int j = i + 1; j < pool.length; j++) {
        if (!used.contains(pool[j].id)) {
          matched = j;
          break;
        }
      }
    }
    if (matched != -1) {
      used.add(p1.id);
      used.add(pool[matched].id);
      pairs.add([p1, pool[matched]]);
    }
  }
  return PairingResult(pairs, byePlayer);
}
