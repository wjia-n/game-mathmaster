import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/chalk_art.dart';
import '../theme/chalk_themes.dart';

/// Custom classroom creator (PRO): pick board, chalk, wood and accent
/// colors from warm classroom swatches. Live preview board.
class CustomThemeScreen extends StatelessWidget {
  final MathAudio audio;
  final MathSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const _swatches = [
    0xFF2B3A33, 0xFF33413A, 0xFF3C4048, 0xFF413B33, 0xFF2E4038, 0xFF232B3D,
    0xFF38302A, 0xFF27402F, 0xFF453A34, 0xFF2C2F4A, 0xFFEFE6D2, 0xFF3A3230,
    0xFF7A4E2D, 0xFF9A6B3A, 0xFF6B4A2E, 0xFF8A4E2A, 0xFFB98A4E, 0xFF4E3B2E,
    0xFFF6F1E3, 0xFFFBF6EA, 0xFFF2EFE6, 0xFFFFF3DC, 0xFFFDF8EE, 0xFFEDEFF7,
    0xFFD9A441, 0xFFC98F2E, 0xFFB08D57, 0xFFE07840, 0xFFD4AF37, 0xFFC0C6D4,
    0xFF3B2417, 0xFF1D1F24, 0xFF221D18, 0xFF1B231E, 0xFF11151F, 0xFF1D1712,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = settings.customTheme;
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
                  audio.click();
                  settings.setTheme('custom');
                  Navigator.of(context).pop();
                },
              ),
              title: Text('My Classroom', style: Chalk.display(22, theme: t)),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: () {
                    audio.click();
                    settings.resetCustomColors();
                  },
                  child: Text('Reset', style: Chalk.label(13, theme: t)),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Column(
                  children: [
                    // Live preview board.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [t.wood, t.woodDeep],
                        ),
                        border:
                            Border.all(color: t.accent, width: 2.5),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [t.board, t.boardDeep],
                          ),
                        ),
                        child: Center(
                          child: Text('12 + 7 = 19',
                              style: DigitStyles.style(0, t, 40)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final row in [
                      ('Chalkboard', 'board'),
                      ('Board shade', 'boardDeep'),
                      ('Chalk', 'chalk'),
                      ('Soft chalk', 'chalkSoft'),
                      ('Wood frame', 'wood'),
                      ('Wood shade', 'woodDeep'),
                      ('Accent', 'accent'),
                      ('Accent light', 'accentLight'),
                      ('Key face', 'keyBg'),
                      ('Key border', 'keyBorder'),
                    ])
                      _ColorRow(
                        theme: t,
                        label: row.$1,
                        keyName: row.$2,
                        current: settings.customColors[row.$2]!,
                        onPick: (v) {
                          audio.click();
                          settings.setCustomColor(row.$2, v);
                        },
                      ),
                    const SizedBox(height: 16),
                    ChalkButton(
                      label: 'Use My Classroom',
                      theme: t,
                      width: 260,
                      onTap: () {
                        audio.click();
                        settings.setTheme('custom');
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorRow extends StatelessWidget {
  final ChalkThemeDef theme;
  final String label;
  final String keyName;
  final int current;
  final ValueChanged<int> onPick;
  const _ColorRow({
    required this.theme,
    required this.label,
    required this.keyName,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Chalk.body(15, theme: theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in CustomThemeScreen._swatches)
                GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(c),
                      border: Border.all(
                        color: c == current
                            ? theme.accentLight
                            : Colors.black.withValues(alpha: 0.4),
                        width: c == current ? 3.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
