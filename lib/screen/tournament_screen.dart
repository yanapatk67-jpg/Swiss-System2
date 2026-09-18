import 'package:flutter/material.dart';
import '../logic/pairing.dart';
import '../logic/storage.dart';
import '../model/player.dart';
import '../model/round_result.dart';
import '../model/tournament_record.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/form_field_style.dart';
import '../widgets/history_view.dart';
import '../widgets/pair_tile.dart';
import '../widgets/standings_table.dart';
import 'history_list_screen.dart';

enum Stage { setup, tournament, done }

enum RoundMode { auto, manual }

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});
  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  Stage stage = Stage.setup;
  RoundMode mode = RoundMode.auto;
  int playerCount = 16;
  int manualRounds = 4;

  // Editable player names for the setup screen.
  List<TextEditingController> nameControllers = [];

  List<Player> players = [];
  int currentRound = 1;
  List<List<Player>> pairings = [];
  Player? byePlayer;
  Map<int, dynamic> results = {}; // idx -> playerId or 'draw'
  List<RoundResult> history = [];

  bool _loading = true;

  int get totalRounds =>
      mode == RoundMode.auto ? calcRounds(playerCount) : manualRounds;

  @override
  void initState() {
    super.initState();
    _syncNameControllers();
    _restore();
  }

  @override
  void dispose() {
    for (final c in nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Persistence ----------
  Future<void> _restore() async {
    final data = await TournamentStorage.load();
    if (data == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final loadedPlayers = (data['players'] as List)
          .map((j) => Player.fromJson(j as Map<String, dynamic>))
          .toList();
      final byId = {for (final p in loadedPlayers) p.id: p};
      final loadedPairings = (data['pairingIds'] as List)
          .map((pair) => (pair as List)
              .map((id) => byId[id as int]!)
              .toList())
          .toList();
      final byeId = data['byePlayerId'] as int?;

      setState(() {
        stage = Stage.values.firstWhere((s) => s.name == data['stage']);
        mode = RoundMode.values.firstWhere((m) => m.name == data['mode']);
        playerCount = data['playerCount'] as int;
        manualRounds = data['manualRounds'] as int;
        players = loadedPlayers;
        currentRound = data['currentRound'] as int;
        pairings = loadedPairings.cast<List<Player>>();
        byePlayer = byeId != null ? byId[byeId] : null;
        results = (data['results'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v));
        history = (data['history'] as List)
            .map((j) => RoundResult.fromJson(j as Map<String, dynamic>))
            .toList();
        _syncNameControllers();
        _loading = false;
      });
    } catch (_) {
      // Corrupt or outdated saved data — start fresh instead of crashing.
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await TournamentStorage.save(
      stage: stage.name,
      mode: mode.name,
      playerCount: playerCount,
      manualRounds: manualRounds,
      players: players,
      currentRound: currentRound,
      pairingIds: pairings.map((pair) => [pair[0].id, pair[1].id]).toList(),
      byePlayerId: byePlayer?.id,
      results: results,
      history: history,
    );
  }

  // ---------- Setup: editable names ----------
  void _syncNameControllers() {
    while (nameControllers.length < playerCount) {
      nameControllers
          .add(TextEditingController(text: 'Player ${nameControllers.length + 1}'));
    }
    while (nameControllers.length > playerCount) {
      nameControllers.removeLast().dispose();
    }
  }

  void _setPlayerCount(int n) {
    setState(() {
      playerCount = n < 2 ? 2 : n;
      _syncNameControllers();
    });
  }

  // ---------- Tournament flow ----------
  void startTournament() {
    final ps = List.generate(playerCount, (i) {
      final typed = nameControllers[i].text.trim();
      return Player(id: i + 1, name: typed.isEmpty ? 'Player ${i + 1}' : typed);
    });
    final pr = pairRound(ps);
    setState(() {
      players = ps;
      currentRound = 1;
      history = [];
      pairings = pr.pairs;
      byePlayer = pr.bye;
      results = {};
      stage = Stage.tournament;
    });
    _save();
  }

  void setResult(int idx, dynamic winner) {
    setState(() => results[idx] = winner);
    _save();
  }

  bool get allResultsIn =>
      pairings.isEmpty || pairings.asMap().keys.every((i) => results.containsKey(i));

  void finishRound() {
    final byId = {for (final p in players) p.id: p};

    final summaries = <String>[];
    for (int idx = 0; idx < pairings.length; idx++) {
      final a = pairings[idx][0];
      final b = pairings[idx][1];
      byId[a.id]!.opponents.add(b.id);
      byId[b.id]!.opponents.add(a.id);
      final res = results[idx];
      String summary;
      if (res == 'draw') {
        byId[a.id]!.points += 1;
        byId[b.id]!.points += 1;
        summary = '${a.name} vs ${b.name} — Draw';
      } else if (res == a.id) {
        byId[a.id]!.points += 3;
        summary = '${a.name} vs ${b.name} — ${a.name} wins';
      } else {
        byId[b.id]!.points += 3;
        summary = '${a.name} vs ${b.name} — ${b.name} wins';
      }
      summaries.add(summary);
    }

    if (byePlayer != null) {
      byId[byePlayer!.id]!.points += 3;
      byId[byePlayer!.id]!.hadBye = true;
    }

    history.add(RoundResult(
      round: currentRound,
      pairSummaries: summaries,
      byeName: byePlayer?.name,
    ));

    final newPlayers = byId.values.toList();

    if (currentRound >= totalRounds) {
      setState(() {
        players = newPlayers;
        stage = Stage.done;
      });
      _save();
      _archiveFinishedTournament(newPlayers, byId);
      return;
    }

    final pr = pairRound(newPlayers);
    setState(() {
      players = newPlayers;
      pairings = pr.pairs;
      byePlayer = pr.bye;
      results = {};
      currentRound += 1;
    });
    _save();
  }

  Future<void> _archiveFinishedTournament(
    List<Player> finalPlayers,
    Map<int, Player> byId,
  ) async {
    final sorted = [...finalPlayers];
    sorted.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byBuchholz = buchholzFor(b, byId).compareTo(buchholzFor(a, byId));
      if (byBuchholz != 0) return byBuchholz;
      return a.name.compareTo(b.name);
    });

    final record = TournamentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      finishedAt: DateTime.now(),
      playerCount: finalPlayers.length,
      totalRounds: totalRounds,
      standings: sorted
          .map((p) => StandingEntry(
                name: p.name,
                points: p.points,
                buchholz: buchholzFor(p, byId),
              ))
          .toList(),
      history: List.of(history),
    );
    await TournamentStorage.addToArchive(record);
  }

  void reset() {
    setState(() {
      stage = Stage.setup;
      players = [];
      pairings = [];
      byePlayer = null;
      results = {};
      history = [];
      currentRound = 1;
      _syncNameControllers();
    });
    TournamentStorage.clear();
  }

  Map<int, Player> get _byId => {for (final p in players) p.id: p};

  /// Ranked by points, then Buchholz (sum of opponents' points), then name.
  List<Player> get standings {
    final byId = _byId;
    final s = [...players];
    s.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byBuchholz = buchholzFor(b, byId).compareTo(buchholzFor(a, byId));
      if (byBuchholz != 0) return byBuchholz;
      return a.name.compareTo(b.name);
    });
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: paper,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Row(
          children: const [
            Icon(Icons.sports_kabaddi, color: felt, size: 20),
            SizedBox(width: 8),
            Text('Swiss Pairings',
                style: TextStyle(
                    color: ink, fontWeight: FontWeight.w600, fontSize: 19)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Past tournaments',
            icon: const Icon(Icons.history, color: felt),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const HistoryListScreen(),
              ));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: lineColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: felt))
            : switch (stage) {
                Stage.setup => _buildSetup(),
                Stage.tournament => _buildTournament(),
                Stage.done => _buildDone(),
              },
      ),
      bottomNavigationBar: stage == Stage.tournament && pairings.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  // ---------- Setup screen ----------
  Widget _buildSetup() {
    final autoR = calcRounds(playerCount);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('NUMBER OF PLAYERS'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: playerCount.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                decoration: fieldDecoration(),
                onChanged: (v) => _setPlayerCount(int.tryParse(v) ?? 2),
              ),
              const SizedBox(height: 20),
              const FieldLabel('ROUND COUNT'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _modeButton('Calculate for me', RoundMode.auto),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton("I'll set it", RoundMode.manual),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (mode == RoundMode.auto)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAD9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('For $playerCount players, Swiss standard is',
                            style: const TextStyle(
                                color: Color(0xFF5B5748), fontSize: 14)),
                      ),
                      Text('$autoR',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: felt)),
                    ],
                  ),
                )
              else
                TextFormField(
                  initialValue: manualRounds.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20),
                  decoration: fieldDecoration(),
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 1;
                    setState(() => manualRounds = n < 1 ? 1 : n);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('PLAYER NAMES (optional)'),
              const SizedBox(height: 10),
              for (int i = 0; i < nameControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: nameControllers[i],
                    style: const TextStyle(fontSize: 14),
                    decoration: fieldDecoration().copyWith(
                      isDense: true,
                      prefixText: '${i + 1}.  ',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: startTournament,
            icon: const Icon(Icons.shuffle, size: 18),
            label: const Text('Start round 1', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: felt,
              foregroundColor: paper,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String text, RoundMode m) {
    final active = mode == m;
    return OutlinedButton(
      onPressed: () => setState(() => mode = m),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? felt : Colors.transparent,
        foregroundColor: active ? paper : ink,
        side: BorderSide(color: active ? felt : lineColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  // ---------- Tournament screen ----------
  Widget _buildTournament() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 19, color: ink),
                children: [
                  TextSpan(
                      text: 'Round $currentRound ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: 'of $totalRounds',
                      style: const TextStyle(color: Color(0xFF9A9583))),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.restart_alt, size: 15, color: Color(0xFF9A9583)),
              label: const Text('restart',
                  style: TextStyle(color: Color(0xFF9A9583), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              for (int idx = 0; idx < pairings.length; idx++)
                PairTile(
                  a: pairings[idx][0],
                  b: pairings[idx][1],
                  result: results[idx],
                  isLast: idx == pairings.length - 1 && byePlayer == null,
                  onSetResult: (winner) => setResult(idx, winner),
                ),
              if (byePlayer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${byePlayer!.name} draws a bye this round (+3 pts)',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF7A7563)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StandingsTable(standings: standings, byId: _byId),
        const SizedBox(height: 20),
        HistoryView(history: history),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: paper,
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: allResultsIn ? finishRound : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: felt,
            disabledBackgroundColor: const Color(0xFFCFC9B8),
            foregroundColor: paper,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            currentRound >= totalRounds
                ? 'Finish tournament'
                : 'Confirm results, pair next round',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ---------- Done screen ----------
  Widget _buildDone() {
    final winner = standings.isNotEmpty ? standings.first : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: gold, size: 30),
              const SizedBox(height: 8),
              Text(winner?.name ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: ink)),
              const SizedBox(height: 4),
              Text(
                'wins the $totalRounds-round Swiss with ${winner?.points ?? 0} points',
                style: const TextStyle(fontSize: 13, color: Color(0xFF7A7563)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: reset,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: felt),
                  foregroundColor: felt,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('New tournament'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StandingsTable(standings: standings, byId: _byId),
        const SizedBox(height: 20),
        HistoryView(history: history),
      ],
    );
  }
}