import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Math Master rules (RULES.md is authoritative).
//
// Modes:
// - blitz: 60 seconds, answer as many as possible. Correct = 10 x streak
//   multiplier (1x/2x/3x/5x). Wrong = -2s and streak reset. Long-press the
//   question to skip at the cost of a wrong answer.
// - zen: 20 questions, no clock. Correct = 10 + speed bonus (up to +10).
// - daily: 10 questions, seeded by calendar day (identical for every player
//   that day), zen-style scoring, one best score per day.
// ---------------------------------------------------------------------------

enum MathDifficulty { easy, medium, hard }

enum GameMode { blitz, zen, daily }

/// Phases owned entirely by the engine. The UI only renders.
enum Phase {
  presenting, // question types in (animated)
  answering, // input live
  revealing, // result walk-through (animated, never instant)
  settling, // brief pause before the next question
  over, // final tally
}

enum SfxKind { key, correct, wrong, start, win, lose, tick, skip }

class MathQuestion {
  final String text;
  final int answer;
  final String op;
  const MathQuestion(this.text, this.answer, this.op);
}

/// Deterministic question generator. Easy: +/- to 20. Medium: +/- to 99 and
/// x tables 2..9. Hard: x up to 19x9, exact division, two-step sums.
/// Subtraction never goes negative; division is always exact.
MathQuestion genQuestion(Random r, MathDifficulty d) {
  int pick(int n) => r.nextInt(n);
  switch (d) {
    case MathDifficulty.easy:
      final a = pick(15) + 1, b = pick(15) + 1;
      if (r.nextBool()) return MathQuestion('$a + $b', a + b, '+');
      return MathQuestion('${a + b} − $a', b, '−');
    case MathDifficulty.medium:
      final k = pick(3);
      if (k == 0) {
        final a = pick(80) + 10, b = pick(80) + 10;
        if (r.nextBool()) return MathQuestion('$a + $b', a + b, '+');
        return MathQuestion('${a + b} − $a', b, '−');
      }
      if (k == 1) {
        final a = pick(8) + 2, b = pick(8) + 2;
        return MathQuestion('$a × $b', a * b, '×');
      }
      final a = pick(41) + 10, b = pick(41) + 10;
      if (r.nextBool()) return MathQuestion('$a + $b', a + b, '+');
      return MathQuestion('${a + b} − $a', b, '−');
    case MathDifficulty.hard:
      final k = pick(4);
      if (k == 0) {
        final a = pick(8) + 12, b = pick(8) + 2;
        return MathQuestion('$a × $b', a * b, '×');
      }
      if (k == 1) {
        final b = pick(9) + 2, ans = pick(11) + 2;
        return MathQuestion('${b * ans} ÷ $b', ans, '÷');
      }
      if (k == 2) {
        // Two-step: a + b − c, always non-negative.
        final a = pick(40) + 10, b = pick(40) + 10, c = pick(20) + 1;
        return MathQuestion('$a + $b − $c', a + b - c, '+−');
      }
      final a = pick(60) + 21, b = pick(60) + 21;
      if (r.nextBool()) return MathQuestion('$a + $b', a + b, '+');
      return MathQuestion('${a + b} − $a', b, '−');
  }
}

class MathEngine extends ChangeNotifier {
  final GameMode mode;
  final MathDifficulty difficulty;
  final Random _rand;

  // Phase durations — every reveal is animated, nothing pops instantly.
  static const int presentMs = 550;
  static const int revealCorrectMs = 750;
  static const int revealWrongMs = 1200;
  static const int settleMs = 300;
  static const int blitzTotalMs = 60000;
  static const int zenCount = 20;
  static const int dailyCount = 10;

  Phase phase = Phase.presenting;
  MathQuestion? question;
  String input = '';
  bool lastCorrect = false;
  bool lastSkipped = false;

  int score = 0;
  int scoreFrom = 0; // count-up animation window
  int scoreTo = 0;
  int streak = 0;
  int bestStreak = 0;
  int correct = 0;
  int answered = 0;
  int skipped = 0;
  int timeLeftMs = blitzTotalMs;
  String banner = '';
  bool over = false;
  bool newBest = false;
  int prevBest = 0;
  int gained = 0; // points awarded on the last correct answer
  int answerTimeMs = 0;

  /// UI wires this to the audio service.
  void Function(SfxKind)? onSfx;

  Timer? _phaseTimer; // the single phase-transition timer
  Timer? _clock; // blitz countdown (100ms ticks)
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;
  DateTime _questionAt = DateTime.now();
  int _questionTarget = 0; // zen/daily question budget

  int get mult => streak < 3 ? 1 : streak < 6 ? 2 : streak < 10 ? 3 : 5;
  bool get acceptingInput => phase == Phase.answering && !over && !paused;
  bool get timed => mode == GameMode.blitz;

  MathEngine({
    required this.mode,
    required this.difficulty,
    int? seed,
    DateTime? day, // daily mode: the calendar day
  }) : _rand = Random(seed ??
            (day != null ? day.year * 10000 + day.month * 100 + day.day : null) ??
            DateTime.now().microsecondsSinceEpoch) {
    _questionTarget = switch (mode) {
      GameMode.blitz => 1 << 30,
      GameMode.zen => zenCount,
      GameMode.daily => dailyCount,
    };
    // Daily challenge always plays a medium/hard mix for fairness.
    banner = switch (mode) {
      GameMode.blitz => 'Solve as many as you can!',
      GameMode.zen => '$zenCount questions, no rush.',
      GameMode.daily => 'Today\u2019s challenge — same sums for everyone!',
    };
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  MathDifficulty get effectiveDifficulty =>
      mode == GameMode.daily ? MathDifficulty.medium : difficulty;

  void start() {
    score = 0;
    scoreFrom = 0;
    scoreTo = 0;
    streak = 0;
    bestStreak = 0;
    correct = 0;
    answered = 0;
    skipped = 0;
    timeLeftMs = blitzTotalMs;
    over = false;
    newBest = false;
    gained = 0;
    onSfx?.call(SfxKind.start);
    _deal();
    _startClock();
    notifyListeners();
  }

  void _deal() {
    question = genQuestion(_rand, effectiveDifficulty);
    input = '';
    lastSkipped = false;
    _questionAt = DateTime.now();
    phase = Phase.presenting;
    _arm(Duration(milliseconds: presentMs), () {
      phase = Phase.answering;
      notifyListeners();
    });
    notifyListeners();
  }

  // ------------------------------------------------------------- input
  void pressDigit(String d) {
    if (!acceptingInput || question == null) return;
    if (input.length >= 6) return;
    input += d;
    onSfx?.call(SfxKind.key);
    notifyListeners();
    if (input.length >= question!.answer.abs().toString().length) {
      _judge();
    }
  }

  void backspace() {
    if (!acceptingInput || input.isEmpty) return;
    input = input.substring(0, input.length - 1);
    onSfx?.call(SfxKind.key);
    notifyListeners();
  }

  void clear() {
    if (!acceptingInput || input.isEmpty) return;
    input = '';
    onSfx?.call(SfxKind.key);
    notifyListeners();
  }

  void submit() {
    if (!acceptingInput || input.isEmpty || question == null) return;
    _judge();
  }

  /// Long-press the question to skip at the cost of a wrong answer.
  void skip() {
    if (!acceptingInput) return;
    onSfx?.call(SfxKind.skip);
    _judge(skipped: true);
  }

  // ------------------------------------------------------------- judging
  void _judge({bool skipped = false}) {
    if (phase != Phase.answering || over) return;
    answerTimeMs = DateTime.now().difference(_questionAt).inMilliseconds;
    answered++;
    lastSkipped = skipped;
    lastCorrect = !skipped && input == question!.answer.toString();
    if (lastCorrect) {
      correct++;
      streak++;
      bestStreak = max(bestStreak, streak);
      gained = switch (mode) {
        GameMode.blitz => 10 * mult,
        GameMode.zen || GameMode.daily =>
          10 + max(0, 10 - (answerTimeMs ~/ 600)),
      };
      scoreFrom = score;
      score += gained;
      scoreTo = score;
      banner = switch (mode) {
        GameMode.blitz when mult > 1 => 'Correct! +$gained (×$mult streak)',
        GameMode.blitz => 'Correct! +$gained',
        _ => 'Correct! +$gained',
      };
      onSfx?.call(SfxKind.correct);
    } else {
      streak = 0;
      gained = 0;
      if (mode == GameMode.blitz) {
        timeLeftMs = max(0, timeLeftMs - 2000);
      }
      banner = skipped
          ? 'Skipped — the answer was ${question!.answer}'
          : 'Not quite — the answer was ${question!.answer}';
      onSfx?.call(SfxKind.wrong);
    }
    phase = Phase.revealing;
    notifyListeners();
    _arm(
      Duration(
          milliseconds: lastCorrect ? revealCorrectMs : revealWrongMs),
      _afterReveal,
    );
  }

  void _afterReveal() {
    if (_disposed || over) return;
    if (paused) return;
    phase = Phase.settling;
    notifyListeners();
    _arm(Duration(milliseconds: settleMs), _next);
  }

  void _next() {
    if (_disposed || over || paused) return;
    if (timed && timeLeftMs <= 0) {
      _gameOver();
      return;
    }
    if (!timed && answered >= _questionTarget) {
      _gameOver();
      return;
    }
    _deal();
  }

  void _gameOver() {
    if (over) return;
    over = true;
    phase = Phase.over;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _clock?.cancel();
    _clock = null;
    final accuracy = answered == 0 ? 0 : (correct * 100 / answered).round();
    banner = accuracy >= 60 || correct >= 10
        ? 'Brilliant work, scholar!'
        : 'Good effort — practice makes perfect!';
    onSfx?.call(accuracy >= 60 ? SfxKind.win : SfxKind.lose);
    notifyListeners();
  }

  // ------------------------------------------------------------- clock
  void _startClock() {
    _clock?.cancel();
    if (!timed) return;
    var lastSec = (timeLeftMs / 1000).ceil();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_disposed || paused || over) return;
      timeLeftMs = max(0, timeLeftMs - 100);
      final sec = (timeLeftMs / 1000).ceil();
      if (sec != lastSec) {
        lastSec = sec;
        if (sec <= 5 && sec > 0) onSfx?.call(SfxKind.tick);
      }
      if (timeLeftMs <= 0) {
        _gameOver();
      } else {
        notifyListeners();
      }
    });
  }

  // ------------------------------------------------------------- timers
  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _phaseTimer?.cancel();
    _phaseTimer = Timer(d, () {
      _phaseTimer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze phase + clock timers. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _phaseTimer?.cancel();
      _phaseTimer = null;
      _clock?.cancel();
      _clock = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the phase timer ever dies without progress, recover.
  /// This makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused || _phaseTimer != null) return;
    switch (phase) {
      case Phase.presenting:
        _arm(const Duration(milliseconds: 200), () {
          phase = Phase.answering;
          notifyListeners();
        });
      case Phase.revealing:
        _afterReveal();
      case Phase.settling:
        _next();
      case Phase.answering:
        if (timed && _clock == null) _startClock();
      case Phase.over:
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _phaseTimer?.cancel();
    _clock?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  String get accuracyLabel =>
      answered == 0 ? '—' : '${(correct * 100 / answered).round()}%';
}
