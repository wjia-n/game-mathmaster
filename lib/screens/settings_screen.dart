import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/chalk_art.dart';
import '../theme/chalk_themes.dart';
import 'pro_screen.dart';

/// Settings — music/SFX toggles, volume, lifetime stats.
class SettingsScreen extends StatefulWidget {
  final MathAudio audio;
  final MathSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StoreService _store = StoreService();

  ChalkThemeDef get _t => ChalkThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.proPurchased.addListener(_onPro);
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
    }
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.dispose();
    super.dispose();
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return ChalkBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Chalk.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  BoardCard(
                    theme: t,
                    title: 'Sound',
                    child: Column(
                      children: [
                        _Toggle(
                          theme: t,
                          label: '🎵  Music',
                          value: s.musicOn,
                          onChanged: (v) async {
                            widget.audio.click();
                            await s.setMusic(v);
                            _applyAudio();
                          },
                        ),
                        _Toggle(
                          theme: t,
                          label: '🔔  Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) async {
                            await s.setSfx(v);
                            _applyAudio();
                            widget.audio.click();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('🔊  Volume',
                                style: Chalk.body(15, theme: t)),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                activeColor: t.accent,
                                inactiveColor: Colors.black
                                    .withValues(alpha: 0.4),
                                onChanged: (v) {
                                  s.setVolume(v);
                                  _applyAudio();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  BoardCard(
                    theme: t,
                    title: 'Lifetime Stats',
                    child: Column(
                      children: [
                        _stat(t, 'Games played', '${s.gamesPlayed}'),
                        _stat(t, 'Best blitz score', '${s.bestBlitz}'),
                        _stat(t, 'Best zen score', '${s.bestZen}'),
                        _stat(t, 'Best streak', '${s.bestStreakAll}x'),
                        _stat(t, 'Correct answers', '${s.totalCorrect}'),
                        _stat(t, 'Today\u2019s daily best',
                            '${s.dailyBest(DateTime.now())}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!s.isPro)
                    ChalkButton(
                      label: '✦  Get PRO',
                      theme: t,
                      width: 260,
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProScreen(
                            audio: widget.audio,
                            settings: s,
                            store: _store,
                          ),
                        ));
                      },
                    ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Chalk.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(ChalkThemeDef t, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: Chalk.body(15, theme: t)),
            Text(v, style: Chalk.label(15, theme: t, color: t.chalk)),
          ],
        ),
      );
}

class _Toggle extends StatelessWidget {
  final ChalkThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Chalk.body(16, theme: theme)),
          Switch(
            value: value,
            activeThumbColor: theme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
