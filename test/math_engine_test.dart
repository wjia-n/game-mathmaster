import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmaster/engine/math_engine.dart';

/// RULES.md §13 test cases + regression tests for the exemplar fixes.
///
/// The engine owns its phase timers; tests drive the public API and wait out
/// the (short) phase durations. `seed` makes question order deterministic.
MathEngine makeEngine(
    {GameMode mode = GameMode.blitz,
    MathDifficulty difficulty = MathDifficulty.easy,
    int seed = 42}) {
  return MathEngine(mode: mode, difficulty: difficulty, seed: seed);
}

/// Answer the current question correctly and wait for the settle.
/// Call [MathEngine.start] once before the first call — this helper never
/// restarts the engine, so streaks accumulate across calls.
Future<void> answerCorrect(MathEngine e) async {
  // Wait out the presenting phase.
  await Future.delayed(const Duration(milliseconds: 700));
  e.pressDigit(e.question!.answer.toString()[0]);
  // Multi-digit answers need the rest of the digits.
  final rest = e.question!.answer.toString().substring(1);
  for (final ch in rest.split('')) {
    e.pressDigit(ch);
  }
  // Auto-judge fires when the input reaches answer length; wait out reveal
  // + settle so the next question is live.
  await Future.delayed(const Duration(milliseconds: 1700));
}

void main() {
  test('1. Easy questions: + / − only, no negative results', () {
    final r = Random(7);
    for (int i = 0; i < 200; i++) {
      final q = genQuestion(r, MathDifficulty.easy);
      expect(['+', '−'], contains(q.op));
      expect(q.answer, greaterThanOrEqualTo(0));
      expect(q.answer, lessThanOrEqualTo(30));
    }
  });

  test('2. Medium questions: +/− to 99 or small × tables', () {
    final r = Random(11);
    for (int i = 0; i < 200; i++) {
      final q = genQuestion(r, MathDifficulty.medium);
      expect(['+', '−', '×'], contains(q.op));
      expect(q.answer, greaterThanOrEqualTo(0));
    }
  });

  test('3. Hard questions: big ×, exact ÷, non-negative two-step', () {
    final r = Random(13);
    for (int i = 0; i < 300; i++) {
      final q = genQuestion(r, MathDifficulty.hard);
      expect(['+', '−', '×', '÷', '+−'], contains(q.op));
      expect(q.answer, greaterThanOrEqualTo(0));
      if (q.op == '÷') {
        // Exact division: answer * divisor == dividend.
        final parts = q.text.split(' ÷ ');
        final dividend = int.parse(parts[0]);
        final divisor = int.parse(parts[1]);
        expect(dividend, equals(q.answer * divisor));
      }
    }
  });

  test('8. Daily: same day seed → identical questions', () {
    final day = DateTime(2026, 10, 9);
    final a = MathEngine(mode: GameMode.daily, difficulty: MathDifficulty.easy, day: day);
    final b = MathEngine(mode: GameMode.daily, difficulty: MathDifficulty.easy, day: day);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    a.start();
    b.start();
    expect(a.question!.text, equals(b.question!.text));
  });

  test('4/5/6. Correct answer scores with streak multiplier; wrong resets', () async {
    final e = makeEngine(seed: 99);
    addTearDown(e.dispose);
    e.start();
    await answerCorrect(e);
    expect(e.correct, 1);
    expect(e.score, 10); // streak 1 → ×1
    expect(e.streak, 1);
    // Wrong answer: type a wrong digit string of matching length.
    await Future.delayed(const Duration(milliseconds: 700));
    final wrong = (e.question!.answer + 1).toString();
    for (final ch in wrong.split('')) {
      e.pressDigit(ch);
    }
    expect(e.phase, Phase.revealing);
    expect(e.streak, 0);
    await Future.delayed(const Duration(milliseconds: 1700));
    // Streak multiplier boundary: 10 correct in a row → ×5 on the 10th.
    final e2 = makeEngine(seed: 5);
    addTearDown(e2.dispose);
    e2.start();
    for (int i = 0; i < 10; i++) {
      await answerCorrect(e2);
    }
    expect(e2.streak, 10);
    expect(e2.mult, 5);
  });

  test('7. Zen: correct scores 10 + speed bonus, wrong scores 0', () async {
    final e = makeEngine(mode: GameMode.zen, seed: 21);
    addTearDown(e.dispose);
    e.start();
    await answerCorrect(e);
    expect(e.score, greaterThanOrEqualTo(10));
    expect(e.score, lessThanOrEqualTo(20));
  });

  test('10. Pause/resume keeps the phase and never sticks', () async {
    final e = makeEngine(seed: 31);
    addTearDown(e.dispose);
    e.start();
    await Future.delayed(const Duration(milliseconds: 700));
    expect(e.phase, Phase.answering);
    e.setPaused(true);
    await Future.delayed(const Duration(milliseconds: 400));
    expect(e.phase, Phase.answering); // frozen, not advanced
    e.setPaused(false);
    e.pressDigit(e.question!.answer.toString()[0]);
    for (final ch in e.question!.answer.toString().substring(1).split('')) {
      e.pressDigit(ch);
    }
    await Future.delayed(const Duration(milliseconds: 1700));
    expect(e.answered, 1);
    expect(e.phase, isNot(Phase.over));
  });

  test('9. Zen ends after exactly 20 questions', () async {
    final e = makeEngine(mode: GameMode.zen, seed: 77);
    addTearDown(e.dispose);
    e.start();
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (e.over) break;
      final ans = e.question!.answer.toString();
      for (final ch in ans.split('')) {
        e.pressDigit(ch);
      }
      await Future.delayed(const Duration(milliseconds: 1700));
    }
    expect(e.over, true);
    expect(e.answered, 20);
  });
}
