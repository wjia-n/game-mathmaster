# RULES.md — Math Master (authoritative source of truth)

## 1. Objective
Solve arithmetic questions as fast and as accurately as you can. Blitz mode
is about speed; Zen and Daily modes are about accuracy plus speed.

## 2. Setup
- The player picks a mode (Blitz, Zen, Daily) and a difficulty tier
  (Easy, Medium, Hard; Daily always plays a medium mix).
- Blitz runs a 60-second clock. Zen deals 20 questions with no clock.
  Daily deals 10 questions seeded by the calendar day.

## 3. Turn order
Single-player, sequential questions: present → answer → reveal → next.
There are no turns or opponents.

## 4. Legal moves
- Type digits on the number pad (max 6 digits).
- Backspace / clear while answering.
- The answer auto-checks the moment the typed input reaches the length of
  the correct answer.
- Long-press the question to skip (counts as a wrong answer).

## 5. Illegal moves
- Input is ignored while the question is presenting, revealing, settling,
  paused, or after the game is over.
- No input longer than 6 digits.

## 6. Captures
N/A (no pieces).

## 7. Special rules
- Blitz: a wrong answer costs 2 seconds and resets the streak.
- Blitz: correct streaks multiply points: streak <3 → ×1, <6 → ×2,
  <10 → ×3, ≥10 → ×5.
- Zen/Daily: a correct answer scores 10 + speed bonus (up to +10, faster
  answers earn more). Wrong answers score 0 and break the streak.
- Skips count as wrong answers.
- Daily questions are seeded by calendar day (seed = YYYYMMDD) so every
  player gets the same 10 questions that day.

## 8. Scoring
- Blitz: 10 × streak multiplier per correct answer.
- Zen/Daily: 10 + speed bonus per correct answer.
- Lifetime bests persist per mode (blitz, zen, daily-per-date).

## 9. Winning conditions
There is no win/lose against an opponent. A "win" tone plays when accuracy
≥ 60%; otherwise a "good effort" tone plays. Beating a personal best is the
victory condition.

## 10. Draw conditions
N/A.

## 11. AI strategy
N/A (single-player). Question difficulty follows the tier parameters in §13.

## 12. Edge cases
- Time runs out mid-reveal: the game ends immediately; the pending reveal
  is discarded.
- Pause freezes the phase timer and the blitz clock; resume re-arms the
  current phase via the watchdog.
- App backgrounding pauses the engine; music pauses (not stops) and
  resumes where it left off.
- Answers are never negative and division is always exact.
- If a phase timer ever dies without progress, the 2-second watchdog
  re-drives the phase: stuck states are impossible by construction.

## 13. Test cases
1. Easy questions: only + and −, operands 1..15, no negative results.
2. Medium questions: +/− with operands 10..89, or × with 2..9 tables.
3. Hard questions: × 12..19 by 2..9, exact ÷, or two-step a+b−c (≥ 0).
4. Correct answer auto-checks when input length matches answer length.
5. Wrong answer in Blitz subtracts exactly 2 seconds and resets streak.
6. Streak multiplier boundaries: 2→×1, 5→×2, 9→×3, 10→×5.
7. Zen scores 10 + speed bonus; wrong scores 0.
8. Daily: two engines seeded with the same day produce identical questions.
9. Game over at 60.0s in Blitz; at 20 questions in Zen; at 10 in Daily.
10. Pause during any phase, resume — the game continues from the same phase.
11. Player profile survives restart as one JSON string (order preserved).
12. Legacy `mathmaster_best` key migrates to the new best-blitz key once.
