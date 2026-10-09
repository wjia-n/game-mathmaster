import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/math_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/chalk_art.dart';
import '../theme/chalk_themes.dart';

/// Game screen — the MathEngine owns every phase; this widget only renders.
///
/// Animations are never instant: questions type in digit-by-digit, answers
/// reveal with a visible walk-through, scores count up, and the final tally
/// animates before the results card slides in.
class GameScreen extends StatefulWidget {
  final MathEngine engine;
  final MathAudio audio;
  final MathSettings settings;
  const GameScreen(
      {super.key,
      required this.engine,
      required this.audio,
      required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _recorded = false;
  bool _reviewOffered = false;
  late final AnimationController _shake;

  MathEngine get _e => widget.engine;
  MathSettings get _s => widget.settings;
  ChalkThemeDef get _t =>
      ChalkThemes.byId(_s.themeId, custom: _s.customTheme);

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.mathmaster';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _e.onSfx = _onSfx;
    _e.addListener(_onEngine);
    widget.audio.startGameMusic();
    _e.start();
  }

  void _onSfx(SfxKind k) {
    switch (k) {
      case SfxKind.key:
        widget.audio.key();
      case SfxKind.correct:
        widget.audio.correct();
      case SfxKind.wrong:
        widget.audio.wrong();
      case SfxKind.start:
        widget.audio.gameStart();
      case SfxKind.win:
        widget.audio.win();
      case SfxKind.lose:
        widget.audio.lose();
      case SfxKind.tick:
        widget.audio.tick();
      case SfxKind.skip:
        widget.audio.skipSfx();
    }
  }

  void _onEngine() {
    if (!mounted) return;
    if (_e.phase == Phase.revealing && !_e.lastCorrect) {
      _shake.forward(from: 0);
    }
    if (_e.over && !_recorded) {
      _recorded = true;
      _finishGame();
    }
    setState(() {});
  }

  Future<void> _finishGame() async {
    final modeIdx = switch (_e.mode) {
      GameMode.blitz => 0,
      GameMode.zen => 1,
      GameMode.daily => 2,
    };
    final newBest = await _s.recordGame(
      mode: modeIdx,
      score: _e.score,
      bestStreak: _e.bestStreak,
      correctCount: _e.correct,
    );
    if (_e.mode == GameMode.daily) {
      await _s.recordDaily(DateTime.now(), _e.score);
    }
    _e.newBest = newBest;
    if (mounted) setState(() {});
    // Offer a real in-app review on a new best (max once a day, graceful
    // when not from Play — never a fake dialog).
    if (newBest && !_reviewOffered) {
      _reviewOffered = true;
      final last = _s.lastReviewPromptRaw;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (!last.startsWith(today)) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;
        try {
          final review = InAppReview.instance;
          if (await review.isAvailable()) {
            await _s.markReviewPrompted();
            await review.requestReview();
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngine);
    _e.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_e.over) {
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
      // Backgrounding pauses the engine with no visible dialog — surface
      // the pause dialog so the game can never sit paused with no way back.
      if (_e.paused && !_e.over && mounted) _pauseDialog(silent: true);
    }
  }

  void _pauseDialog({bool silent = false}) {
    if (_e.over) return;
    if (!silent) widget.audio.click();
    _e.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [_t.board, _t.boardDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: _t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Chalk.display(28, theme: _t)),
              const SizedBox(height: 8),
              Text(
                '${_s.playerName} · score ${_e.score}',
                style: Chalk.body(14, theme: _t),
              ),
              const SizedBox(height: 20),
              ChalkButton(
                label: '▶  Resume',
                theme: _t,
                width: 220,
                fontSize: 17,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              ChalkButton(
                label: '↻  Restart',
                theme: _t,
                width: 220,
                fontSize: 17,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _recorded = false;
                  _reviewOffered = false;
                  _e.setPaused(false);
                  _e.start();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('Quit to menu',
                    style: Chalk.label(14, theme: _t)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Dialog dismissed any other way: unpause the engine.
      if (!_e.over && _e.paused && mounted) _e.setPaused(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = _e;
    return ChalkBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              children: [
                Column(
                  children: [
                    // HUD
                    Row(
                      children: [
                        _hudChip(
                            t,
                            _e.timed ? '⏱️' : '❓',
                            _e.timed
                                ? '${(e.timeLeftMs / 1000).ceil()}s'
                                : '${e.answered}/${e.mode == GameMode.daily ? MathEngine.dailyCount : MathEngine.zenCount}',
                            _e.timed && e.timeLeftMs <= 10000),
                        const SizedBox(width: 8),
                        _hudChip(t, '⭐', '${e.score}', false),
                        const SizedBox(width: 8),
                        _hudChip(t, '🔥', '${e.streak}x', e.streak >= 3),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.pause,
                              color: t.accentLight, size: 30),
                          onPressed: _pauseDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (e.timed)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: e.timeLeftMs / MathEngine.blitzTotalMs,
                          minHeight: 10,
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.4),
                          color: e.timeLeftMs <= 10000
                              ? const Color(0xFFE05252)
                              : t.accent,
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: e.answered /
                              (e.mode == GameMode.daily
                                  ? MathEngine.dailyCount
                                  : MathEngine.zenCount),
                          minHeight: 10,
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.4),
                          color: t.accent,
                        ),
                      ),
                    const SizedBox(height: 10),
                    // Question board
                    Expanded(
                      flex: 3,
                      child: _QuestionBoard(
                        theme: t,
                        engine: e,
                        shake: _shake,
                        digitStyle: _s.digitStyle,
                        onSkip: e.skip,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Number pad
                    Expanded(
                      flex: 4,
                      child: _NumberPad(
                        theme: t,
                        digitStyle: _s.digitStyle,
                        enabled: e.acceptingInput,
                        onKey: (k) {
                          if (k == '⌫') {
                            e.backspace();
                          } else if (k == 'C') {
                            e.clear();
                          } else if (k == '✓') {
                            e.submit();
                          } else {
                            e.pressDigit(k);
                          }
                        },
                      ),
                    ),
                    Text(
                      'long-press the sum to skip${e.timed ? ' (−2s)' : ''}',
                      style: Chalk.body(12,
                          theme: t, color: t.chalkSoft),
                    ),
                  ],
                ),
                if (e.over) _ResultsOverlay(theme: t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hudChip(ChalkThemeDef t, String e, String text, bool hot) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hot
              ? const Color(0xFFE05252).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hot
                  ? const Color(0xFFE05252)
                  : t.accent.withValues(alpha: 0.5)),
        ),
        child: Text('$e $text',
            style: Chalk.body(15,
                theme: t,
                color: hot ? const Color(0xFFFF9D9D) : t.chalk)),
      );

  /// Animated final tally + results card. The score counts up first; the
  /// card slides in after — results never pop instantly.
  Widget _ResultsOverlay({required ChalkThemeDef theme}) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - v)),
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.wood, theme.woodDeep],
                      ),
                      border:
                          Border.all(color: theme.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 10),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [theme.board, theme.boardDeep],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              _e.newBest
                                  ? '🏆 New Best!'
                                  : 'Time\u2019s Up!',
                              style: Chalk.display(30, theme: theme)),
                          const SizedBox(height: 8),
                          // Animated score count-up.
                          TweenAnimationBuilder<int>(
                            tween: IntTween(
                                begin: 0, end: _e.score),
                            duration:
                                const Duration(milliseconds: 1200),
                            builder: (_, val, __) => Text(
                              '$val',
                              style: DigitStyles.style(
                                  _s.digitStyle, theme, 64,
                                  color: theme.accentLight),
                            ),
                          ),
                          Text('points',
                              style: Chalk.label(14, theme: theme)),
                          const SizedBox(height: 12),
                          _statRow(theme, 'Correct',
                              '${_e.correct}/${_e.answered}'),
                          _statRow(
                              theme, 'Accuracy', _e.accuracyLabel),
                          _statRow(theme, 'Best streak',
                              '${_e.bestStreak}x'),
                          const SizedBox(height: 6),
                          Text(_e.banner,
                              style: Chalk.body(14, theme: theme),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ChalkButton(
                            label: '↻  Play Again',
                            theme: theme,
                            width: 230,
                            fontSize: 17,
                            onTap: () {
                              widget.audio.click();
                              _recorded = false;
                              _reviewOffered = false;
                              _e.start();
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              _smallBtn(theme, Icons.share, 'Share',
                                  () async {
                                widget.audio.click();
                                await Share.share(
                                    'I scored ${_e.score} in Math Master! Can you beat me? $_storeUrl');
                              }),
                              const SizedBox(width: 14),
                              _smallBtn(theme, Icons.home, 'Menu', () {
                                widget.audio.click();
                                Navigator.of(context).pop();
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(ChalkThemeDef t, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: Chalk.body(15, theme: t)),
            Text(v,
                style: Chalk.label(15, theme: t, color: t.chalk)),
          ],
        ),
      );

  Widget _smallBtn(
      ChalkThemeDef t, IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(
                color: t.accent.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: t.accentLight, size: 20),
              const SizedBox(width: 6),
              Text(label, style: Chalk.label(14, theme: t)),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
/// The chalkboard: question types in, input appears, reveal walks through.
class _QuestionBoard extends StatelessWidget {
  final ChalkThemeDef theme;
  final MathEngine engine;
  final AnimationController shake;
  final int digitStyle;
  final VoidCallback onSkip;
  const _QuestionBoard({
    required this.theme,
    required this.engine,
    required this.shake,
    required this.digitStyle,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final t = theme;
    final q = e.question;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.wood, t.woodDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.board, t.boardDeep],
          ),
        ),
        child: q == null
            ? const SizedBox.shrink()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Banner line (narration of the last result).
                  SizedBox(
                    height: 24,
                    child: Text(
                      e.banner,
                      style: Chalk.body(13,
                          theme: t, color: t.accentLight),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Question: types in digit-by-digit while presenting.
                  GestureDetector(
                    onLongPress: onSkip,
                    child: _TypedText(
                      // Key on question identity + phase so the type-in
                      // restarts for every new question.
                      key: ValueKey(
                          '${q.text}_${e.answered}_${e.phase == Phase.presenting}'),
                      text: q.text,
                      active: e.phase == Phase.presenting,
                      durationMs: MathEngine.presentMs,
                      style: DigitStyles.style(digitStyle, t, 50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 3,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: t.accent.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Answer zone: input while answering, animated reveal
                  // walk-through while revealing.
                  AnimatedBuilder(
                    animation: shake,
                    builder: (_, __) {
                      final dx = e.phase == Phase.revealing &&
                              !e.lastCorrect
                          ? 10 *
                              (1 - shake.value) *
                              (shake.value * 12).remainder(2).clamp(-1, 1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(dx.toDouble(), 0),
                        child: _answerZone(t, e),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _answerZone(ChalkThemeDef t, MathEngine e) {
    if (e.phase == Phase.revealing) {
      if (e.lastCorrect) {
        // Correct: the typed answer turns chalk-green with a check.
        return _TypedText(
          key: ValueKey('ok_${e.answered}'),
          text: '${e.input} ✓',
          active: true,
          durationMs: MathEngine.revealCorrectMs,
          style: DigitStyles.style(digitStyle, t, 40,
              color: const Color(0xFF9BE29B)),
        );
      }
      // Wrong: input in red, then the correct answer walks in below.
      return Column(
        children: [
          Text(
            e.input.isEmpty ? '—' : e.input,
            style: DigitStyles.style(digitStyle, t, 34,
                color: const Color(0xFFFF9D9D)),
          ),
          _TypedText(
            key: ValueKey('fix_${e.answered}'),
            text: '= ${e.question!.answer}',
            active: true,
            durationMs: MathEngine.revealWrongMs,
            style: DigitStyles.style(digitStyle, t, 36,
                color: const Color(0xFF9BE29B)),
          ),
        ],
      );
    }
    return Text(
      e.input.isEmpty ? '?' : e.input,
      style: DigitStyles.style(
        digitStyle,
        t,
        44,
        color: e.input.isEmpty ? t.chalkSoft : t.chalk,
      ),
    );
  }
}

/// Types [text] in character-by-character while [active]; shows the full
/// text immediately when [active] is false.
class _TypedText extends StatelessWidget {
  final String text;
  final bool active;
  final int durationMs;
  final TextStyle style;
  const _TypedText({
    super.key,
    required this.text,
    required this.active,
    required this.durationMs,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Text(text, style: style, textAlign: TextAlign.center);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: durationMs),
      builder: (_, v, __) {
        final n = (text.length * v).ceil().clamp(0, text.length);
        return Text(
          text.substring(0, n),
          style: style,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
/// Number pad with press feedback and digit styles.
class _NumberPad extends StatelessWidget {
  final ChalkThemeDef theme;
  final int digitStyle;
  final bool enabled;
  final ValueChanged<String> onKey;
  const _NumberPad({
    required this.theme,
    required this.digitStyle,
    required this.enabled,
    required this.onKey,
  });

  static const keys = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final k in keys)
          _PadKey(
            theme: theme,
            digitStyle: digitStyle,
            label: k,
            enabled: enabled,
            onTap: () => onKey(k),
          ),
      ],
    );
  }
}

class _PadKey extends StatefulWidget {
  final ChalkThemeDef theme;
  final int digitStyle;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PadKey({
    required this.theme,
    required this.digitStyle,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PadKey> createState() => _PadKeyState();
}

class _PadKeyState extends State<_PadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final isAction = widget.label == 'C' || widget.label == '⌫';
    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (!widget.enabled) return;
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _pressed ? 2.5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _pressed
                ? [t.keyBg.withValues(alpha: 0.6), t.keyBg]
                : [t.keyBg, t.boardDeep],
          ),
          border: Border.all(
              color: isAction ? t.accent : t.keyBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: Offset(0, _pressed ? 1 : 4),
              blurRadius: _pressed ? 2 : 7,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: DigitStyles.style(
              widget.digitStyle,
              t,
              30,
              color: isAction ? t.accentLight : t.chalk,
            ),
          ),
        ),
      ),
    );
  }
}
