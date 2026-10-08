import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _Q {
  final String text;
  final int answer;
  _Q(this.text, this.answer);
}

class MathMasterScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const MathMasterScreen({super.key, required this.players, required this.callbacks});

  @override
  State<MathMasterScreen> createState() => _MathMasterScreenState();
}

class _MathMasterScreenState extends State<MathMasterScreen>
    with SingleTickerProviderStateMixin {
  final rand = Random();
  int timeLeft = 60;
  int score = 0;
  int streak = 0;
  int best = 0;
  int answered = 0;
  int correct = 0;
  String input = '';
  late _Q q;
  bool over = false;
  Timer? timer;
  late AnimationController pop;
  Color flash = Colors.transparent;
  bool flashGood = true;

  int get level => answered < 5 ? 1 : answered < 12 ? 2 : answered < 20 ? 3 : 4;
  int get mult => streak < 3 ? 1 : streak < 6 ? 2 : streak < 10 ? 3 : 5;

  @override
  void initState() {
    super.initState();
    pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _newQ();
    _loadBest();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || over) return;
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) _end();
      });
    });
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('mathmaster_best') ?? 0);
  }

  @override
  void dispose() {
    timer?.cancel();
    pop.dispose();
    super.dispose();
  }

  void _newQ() {
    final r = rand;
    if (level == 1) {
      final a = r.nextInt(10) + 1, b = r.nextInt(10) + 1;
      q = r.nextBool() ? _Q('$a + $b', a + b) : _Q('${a + b} − $a', b);
    } else if (level == 2) {
      final a = r.nextInt(41) + 10, b = r.nextInt(41) + 10;
      q = r.nextBool() ? _Q('$a + $b', a + b) : _Q('${a + b} − $a', b);
    } else if (level == 3) {
      final a = r.nextInt(8) + 2, b = r.nextInt(8) + 2;
      q = _Q('$a × $b', a * b);
    } else {
      final pick = r.nextInt(4);
      if (pick == 0) {
        final a = r.nextInt(60) + 21, b = r.nextInt(60) + 21;
        q = _Q('$a + $b', a + b);
      } else if (pick == 1) {
        final a = r.nextInt(11) + 2, b = r.nextInt(11) + 2;
        q = _Q('$a × $b', a * b);
      } else if (pick == 2) {
        final b = r.nextInt(9) + 2, ans = r.nextInt(11) + 2;
        q = _Q('${b * ans} ÷ $b', ans);
      } else {
        final a = r.nextInt(41) + 10, b = r.nextInt(41) + 10;
        q = _Q('${a + b} − $a', b);
      }
    }
    input = '';
  }

  void _press(String k) {
    if (over) return;
    if (k == '⌫') {
      if (input.isNotEmpty) setState(() => input = input.substring(0, input.length - 1));
      return;
    }
    if (k == 'C') {
      setState(() => input = '');
      return;
    }
    if (input.length >= 5) return;
    setState(() => input += k);
    Sfx.tap();
    final target = q.answer.toString();
    if (input.length >= target.length) {
      if (input == target) {
        _right();
      } else {
        _penalize();
      }
    }
  }

  void _right() {
    answered++;
    correct++;
    streak++;
    final gained = 10 * mult;
    score += gained;
    flash = const Color(0xFF4CAF50);
    flashGood = true;
    Sfx.move();
    pop.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || over) return;
      setState(() {
        _newQ();
        flash = Colors.transparent;
      });
    });
  }

  void _penalize() {
    // Wrong full-length answer: −2 seconds, streak gone.
    answered++;
    streak = 0;
    timeLeft = max(1, timeLeft - 2);
    flash = const Color(0xFFE53935);
    flashGood = false;
    Sfx.lose();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || over) return;
      setState(() {
        _newQ();
        flash = Colors.transparent;
      });
    });
  }

  void _giveUp() {
    // Long-press the question to skip at a cost.
    if (over || input.isNotEmpty) return;
    _penalize();
  }

  Future<void> _end() async {
    if (over) return;
    over = true;
    timer?.cancel();
    final p = await SharedPreferences.getInstance();
    final isBest = score > (p.getInt('mathmaster_best') ?? 0);
    if (isBest) await p.setInt('mathmaster_best', score);
    widget.players.first.score = score;
    Sfx.win();
    widget.callbacks.finish(
        headline: 'You scored $score!',
        subline: '$correct/$answered correct · best streak ${streak}x'
            '${isBest ? ' · NEW BEST! 🏆' : ' · best $best'}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // HUD
            Row(
              children: [
                _chip(theme, '⏱️', '$timeLeft', timeLeft <= 10),
                const SizedBox(width: 8),
                _chip(theme, '⭐', '$score', false),
                const SizedBox(width: 8),
                _chip(theme, '🔥', '${streak}x', streak >= 3),
                const Spacer(),
                _chip(theme, '🏆', '$best', false),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: timeLeft / 60,
                minHeight: 10,
                backgroundColor: theme.surface,
                color: timeLeft <= 10 ? Colors.red : theme.primary,
              ),
            ),
            const SizedBox(height: 10),
            // question card
            Expanded(
              flex: 3,
              child: AnimatedBuilder(
                animation: pop,
                builder: (_, _) => Transform.scale(
                  scale: 1 + 0.12 * (1 - pop.value) * (pop.value > 0 ? 1 : 0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: flash == Colors.transparent
                              ? theme.primary.withValues(alpha: 0.3)
                              : flash,
                          width: 3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onLongPress: _giveUp,
                          child: Text(q.text,
                              style: TextStyle(
                                  color: theme.text,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 4),
                        Text(input.isEmpty ? '?' : input,
                            style: TextStyle(
                                color: flashGood ? theme.accent : Colors.red,
                                fontSize: 40,
                                fontWeight: FontWeight.bold)),
                        if (mult > 1)
                          Text('×$mult streak bonus!',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // number pad
            Expanded(
              flex: 4,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: ['1','2','3','4','5','6','7','8','9','C','0','⌫']
                    .map((k) => _padKey(theme, k))
                    .toList(),
              ),
            ),
            Text('long-press the sum to skip (−2s)',
                style: TextStyle(color: theme.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _chip(GameTheme theme, String e, String t, bool hot) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: hot ? Colors.red.withValues(alpha: 0.15) : theme.surface,
            borderRadius: BorderRadius.circular(12)),
        child: Text('$e $t',
            style: TextStyle(
                color: hot ? Colors.red : theme.text,
                fontWeight: FontWeight.bold)),
      );

  Widget _padKey(GameTheme theme, String k) => GestureDetector(
        onTap: () => _press(k),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(k,
                style: TextStyle(
                    color: theme.text,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      );
}
