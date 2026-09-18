import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'screen/tournament_screen.dart';

void main() => runApp(const SwissApp());

class SwissApp extends StatelessWidget {
  const SwissApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swiss Pairings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: paper,
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(seedColor: felt, background: paper),
        useMaterial3: true,
      ),
      home: const TournamentScreen(),
    );
  }
}
