import 'package:flutter/material.dart';
import '../logic/storage.dart';
import '../model/tournament_record.dart';
import '../theme/colors.dart';
import '../widgets/app_card.dart';
import 'tournament_detail_screen.dart';

/// Lists every finished tournament, newest first. Tap one to see its
/// final standings and round-by-round history.
class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  List<TournamentRecord> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await TournamentStorage.loadArchive();
    setState(() {
      records = r;
      loading = false;
    });
  }

  Future<void> _delete(TournamentRecord r) async {
    await TournamentStorage.deleteFromArchive(r.id);
    _load();
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: paper,
        elevation: 0,
        title: const Text('Past tournaments',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: lineColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: felt))
            : records.isEmpty
                ? const Center(
                    child: Text('No finished tournaments yet',
                        style: TextStyle(color: Color(0xFF9A9583), fontSize: 14)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final r in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(r.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDA7A0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (_) => _delete(r),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => TournamentDetailScreen(record: r),
                                ));
                              },
                              child: AppCard(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.winnerName,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: ink)),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${r.playerCount} players · ${r.totalRounds} rounds',
                                          style: const TextStyle(
                                              fontSize: 12, color: Color(0xFF9A9583)),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(_formatDate(r.finishedAt),
                                            style: const TextStyle(
                                                fontSize: 11, color: Color(0xFF9A9583))),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text('${r.winnerPoints} pts',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: felt)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.chevron_right,
                                            color: Color(0xFF9A9583), size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text('swipe left to delete',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF9A9583).withOpacity(0.8))),
                      ),
                    ],
                  ),
      ),
    );
  }
}
