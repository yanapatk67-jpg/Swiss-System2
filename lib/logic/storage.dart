import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/player.dart';
import '../model/round_result.dart';
import '../model/tournament_record.dart';

/// Handles saving/restoring the whole tournament state to local storage,
/// so progress survives closing and reopening the app. Also keeps an
/// archive of finished tournaments so past results can be browsed later.
class TournamentStorage {
  static const _key = 'swiss_tournament_state';
  static const _archiveKey = 'swiss_tournament_archive';

  // ---------- In-progress tournament (single slot) ----------

  static Future<void> save({
    required String stage,
    required String mode,
    required int playerCount,
    required int manualRounds,
    required List<Player> players,
    required int currentRound,
    required List<List<int>> pairingIds, // [ [aId, bId], ... ]
    required int? byePlayerId,
    required Map<int, dynamic> results, // idx -> playerId or 'draw'
    required List<RoundResult> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'stage': stage,
      'mode': mode,
      'playerCount': playerCount,
      'manualRounds': manualRounds,
      'players': players.map((p) => p.toJson()).toList(),
      'currentRound': currentRound,
      'pairingIds': pairingIds,
      'byePlayerId': byePlayerId,
      'results': results.map((k, v) => MapEntry(k.toString(), v)),
      'history': history.map((h) => h.toJson()).toList(),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ---------- Archive of finished tournaments ----------

  static Future<List<TournamentRecord>> loadArchive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_archiveKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final records = list
          .map((j) => TournamentRecord.fromJson(j as Map<String, dynamic>))
          .toList();
      // Newest first.
      records.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToArchive(TournamentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadArchive();
    existing.add(record);
    final encoded = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_archiveKey, encoded);
  }

  static Future<void> deleteFromArchive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadArchive();
    existing.removeWhere((r) => r.id == id);
    final encoded = jsonEncode(existing.map((r) => r.toJson()).toList());
    await prefs.setString(_archiveKey, encoded);
  }

  static Future<void> clearArchive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_archiveKey);
  }
}