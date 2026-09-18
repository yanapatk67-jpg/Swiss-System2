import 'package:flutter/material.dart';
import '../model/tournament_record.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import '../widgets/history_view.dart';

/// Read-only view of one archived tournament: final standings + round history.
class TournamentDetailScreen extends StatelessWidget {
  final TournamentRecord record;

  const TournamentDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: paper,
        elevation: 0,
        title: const Text('Tournament result',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: lineColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: gold, size: 28),
                  const SizedBox(height: 8),
                  Text(record.winnerName,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600, color: ink)),
                  const SizedBox(height: 4),
                  Text(
                    '${record.playerCount} players · ${record.totalRounds} rounds · ${record.winnerPoints} pts',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7A7563)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _standingsCard(),
            const SizedBox(height: 20),
            HistoryView(history: record.history),
          ],
        ),
      ),
    );
  }

  Widget _standingsCard() {
    final s = record.standings;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Text('FINAL STANDINGS',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF7A7563), fontFamily: 'Courier')),
          ),
          const Divider(height: 1, color: lineColor),
          for (int i = 0; i < s.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                border: i < s.length - 1
                    ? const Border(bottom: BorderSide(color: lineColor))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('${i + 1}',
                          style: const TextStyle(color: Color(0xFF9A9583), fontSize: 14)),
                      const SizedBox(width: 10),
                      Text(s[i].name, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('bh ${s[i].buchholz}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9A9583))),
                      const SizedBox(width: 10),
                      Text('${s[i].points} pts',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
