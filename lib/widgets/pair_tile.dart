import 'package:flutter/material.dart';
import '../model/player.dart';
import '../theme/colors.dart';

class PairTile extends StatelessWidget {
  final Player a;
  final Player b;
  final dynamic result; // playerId, 'draw', or null
  final bool isLast;
  final void Function(dynamic winner) onSetResult;

  const PairTile({
    super.key,
    required this.a,
    required this.b,
    required this.result,
    required this.isLast,
    required this.onSetResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: lineColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PlayerButton(
                  player: a,
                  selected: result == a.id,
                  onPressed: () => onSetResult(a.id),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('vs',
                    style: TextStyle(color: Color(0xFF9A9583), fontSize: 12)),
              ),
              Expanded(
                child: PlayerButton(
                  player: b,
                  selected: result == b.id,
                  onPressed: () => onSetResult(b.id),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => onSetResult('draw'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'call it a draw',
                style: TextStyle(
                  fontSize: 12,
                  color: result == 'draw' ? gold : const Color(0xFF9A9583),
                  decoration:
                      result == 'draw' ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerButton extends StatelessWidget {
  final Player player;
  final bool selected;
  final VoidCallback onPressed;

  const PlayerButton({
    super.key,
    required this.player,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor:
            selected ? const Color(0xFFFBF2DC) : Colors.transparent,
        side: BorderSide(color: selected ? gold : lineColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(player.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: ink)),
          ),
          Text('${player.points}pt',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9A9583))),
        ],
      ),
    );
  }
}
