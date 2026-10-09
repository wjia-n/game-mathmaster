import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/chalk_art.dart';
import '../theme/chalk_themes.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company moment, then the game splash
/// (logo + name + animated loading line + "Credits: WAJIHA").
/// Audio prewarms during the company moment; menu music starts right away.
class SplashScreen extends StatefulWidget {
  final MathAudio audio;
  final MathSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Company moment: audio prewarms and menu music starts behind the
    // WAJIHA logo so it is already playing when the game splash lands.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _companyDone = true);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChalkThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return ChalkBackdrop(
      theme: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: _companyDone ? _gameSplash(theme) : _companyMoment(theme),
        ),
      ),
    );
  }

  /// The WAJIHA company moment: official logo, untouched.
  Widget _companyMoment(ChalkThemeDef theme) {
    return Center(
      key: const ValueKey('company'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 170,
            height: 170,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          Text(
            'W A J I H A',
            style: Chalk.label(26, theme: theme),
          ),
        ],
      ),
    );
  }

  /// The game splash: logo + name + animated loading line + Credits: WAJIHA.
  Widget _gameSplash(ChalkThemeDef theme) {
    return Center(
      key: const ValueKey('game'),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.wood, theme.woodDeep],
                  ),
                  border: Border.all(color: theme.accent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/mathmaster_logo.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 22),
              Text('Math Master', style: Chalk.display(46, theme: theme)),
              const SizedBox(height: 6),
              Text(
                'THE CLASSROOM QUIZ CHALLENGE',
                style: Chalk.label(13, theme: theme),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  theme.accentLight,
                                  theme.accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Sharpening pencils…'
                            : 'Ready!',
                        style: Chalk.body(13,
                            theme: theme,
                            color: theme.chalkSoft),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Chalk.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
