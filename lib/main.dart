import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const MathMasterApp());

class MathMasterApp extends StatelessWidget {
  const MathMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.comicBurst,
      title: 'Math Master',
      tagline: 'Speed arithmetic battles that sharpen your brain',
      emoji: '➗',
      slug: 'mathmaster',
      howToPlay:
          '• Solve as many sums as you can in 60 seconds!\n• Type answers on the number pad — correct answers build your streak.\n• Streaks multiply your points: keep the fire burning! 🔥\n• Wrong answers cost 2 seconds. The sums get harder as you shine.',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          MathMasterScreen(players: players, callbacks: cb),
    );
  }
}
