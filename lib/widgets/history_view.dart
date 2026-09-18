import 'package:flutter/material.dart';
import '../model/round_result.dart';
import '../theme/colors.dart';
import 'app_card.dart';

/// Collapsible list of past rounds, each showing its match results and bye.
class HistoryView extends StatelessWidget {
  final List<RoundResult> history;

  const HistoryView({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Text('ROUND HISTORY',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A7563),
                    fontFamily: 'Courier')),
          ),
          const Divider(height: 1, color: lineColor),
          for (final r in history.reversed)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('Round ${r.round}',
                    style: const TextStyle(fontSize: 14, color: ink)),
                childrenPadding:
                    const EdgeInsets.fromLTRB(18, 0, 18, 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in r.pairSummaries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF5B5748))),
                    ),
                  if (r.byeName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('${r.byeName} had a bye (+3 pts)',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF9A9583))),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
