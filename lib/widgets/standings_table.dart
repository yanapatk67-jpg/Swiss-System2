import 'package:flutter/material.dart';
import '../model/player.dart';
import '../theme/colors.dart';
import 'app_card.dart';

class StandingsTable extends StatelessWidget {
  final List<Player> standings; // already sorted (points, then buchholz, then name)
  final Map<int, Player> byId;

  const StandingsTable({super.key, required this.standings, required this.byId});

  @override
  Widget build(BuildContext context) {
    final s = standings;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Text('STANDINGS',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A7563),
                    fontFamily: 'Courier')),
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
                          style: const TextStyle(
                              color: Color(0xFF9A9583), fontSize: 14)),
                      const SizedBox(width: 10),
                      Text(s[i].name, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('bh ${buchholzFor(s[i], byId)}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9A9583))),
                      const SizedBox(width: 10),
                      Text('${s[i].points} pts',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
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
