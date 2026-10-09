import 'package:flutter/material.dart';

/// Theme, digit-style and board-accent catalog for Math Master.
///
/// The art direction is a warm classroom: wooden frames, chalkboards, chalk
/// dust, brass and copper accents, paper and pencil tones. No neon, no
/// cyberpunk, no generic dashboard looks — every theme stays inside the
/// physical classroom material world.
class ChalkThemeDef {
  final String id;
  final String name;
  final Color wood; // frame
  final Color woodDeep;
  final Color board; // chalkboard surface
  final Color boardDeep;
  final Color chalk; // main text
  final Color chalkSoft; // dim text
  final Color accent; // brass / copper
  final Color accentLight;
  final Color keyBg; // number key face
  final Color keyBorder;

  const ChalkThemeDef({
    required this.id,
    required this.name,
    required this.wood,
    required this.woodDeep,
    required this.board,
    required this.boardDeep,
    required this.chalk,
    required this.chalkSoft,
    required this.accent,
    required this.accentLight,
    required this.keyBg,
    required this.keyBorder,
  });
}

class ChalkThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'oak',
    'slate',
    'sunset',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<ChalkThemeDef> all = [
    ChalkThemeDef(
      id: 'classic',
      name: 'Classic Chalkboard',
      wood: Color(0xFF7A4E2D),
      woodDeep: Color(0xFF3B2417),
      board: Color(0xFF2B3A33),
      boardDeep: Color(0xFF161F1B),
      chalk: Color(0xFFF6F1E3),
      chalkSoft: Color(0xFFB9B2A0),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF2D38A),
      keyBg: Color(0xFF3A4A41),
      keyBorder: Color(0xFFD9A441),
    ),
    ChalkThemeDef(
      id: 'oak',
      name: 'Oak Classroom',
      wood: Color(0xFF9A6B3A),
      woodDeep: Color(0xFF4E3018),
      board: Color(0xFF33413A),
      boardDeep: Color(0xFF1B231E),
      chalk: Color(0xFFFBF6EA),
      chalkSoft: Color(0xFFC4BBA6),
      accent: Color(0xFFC98F2E),
      accentLight: Color(0xFFEECB7E),
      keyBg: Color(0xFF43544B),
      keyBorder: Color(0xFFC98F2E),
    ),
    ChalkThemeDef(
      id: 'slate',
      name: 'Vintage Slate',
      wood: Color(0xFF6B4A2E),
      woodDeep: Color(0xFF33200F),
      board: Color(0xFF3C4048),
      boardDeep: Color(0xFF1D1F24),
      chalk: Color(0xFFF2EFE6),
      chalkSoft: Color(0xFFAEB2B8),
      accent: Color(0xFFB08D57),
      accentLight: Color(0xFFDCC08A),
      keyBg: Color(0xFF4B505A),
      keyBorder: Color(0xFFB08D57),
    ),
    ChalkThemeDef(
      id: 'sunset',
      name: 'Sunset Study',
      wood: Color(0xFF8A4E2A),
      woodDeep: Color(0xFF42220F),
      board: Color(0xFF413B33),
      boardDeep: Color(0xFF221D18),
      chalk: Color(0xFFFFF3DC),
      chalkSoft: Color(0xFFCBBCA0),
      accent: Color(0xFFE07840),
      accentLight: Color(0xFFF5B183),
      keyBg: Color(0xFF50463C),
      keyBorder: Color(0xFFE07840),
    ),
    ChalkThemeDef(
      id: 'maple',
      name: 'Maple Library',
      wood: Color(0xFFB98A4E),
      woodDeep: Color(0xFF5E3E1C),
      board: Color(0xFF2E4038),
      boardDeep: Color(0xFF17211C),
      chalk: Color(0xFFFDF8EE),
      chalkSoft: Color(0xFFC9C0AB),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      keyBg: Color(0xFF3D5248),
      keyBorder: Color(0xFFD4AF37),
    ),
    ChalkThemeDef(
      id: 'midnight',
      name: 'Midnight Study',
      wood: Color(0xFF4E3B2E),
      woodDeep: Color(0xFF241A12),
      board: Color(0xFF232B3D),
      boardDeep: Color(0xFF11151F),
      chalk: Color(0xFFEDEFF7),
      chalkSoft: Color(0xFFA8AEC2),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      keyBg: Color(0xFF303A50),
      keyBorder: Color(0xFFC0C6D4),
    ),
    ChalkThemeDef(
      id: 'candle',
      name: 'Candlelit Hall',
      wood: Color(0xFF6E4526),
      woodDeep: Color(0xFF331D0D),
      board: Color(0xFF38302A),
      boardDeep: Color(0xFF1D1712),
      chalk: Color(0xFFFFF0D6),
      chalkSoft: Color(0xFFC4B295),
      accent: Color(0xFFE8B04B),
      accentLight: Color(0xFFF8D999),
      keyBg: Color(0xFF483E34),
      keyBorder: Color(0xFFE8B04B),
    ),
    ChalkThemeDef(
      id: 'forest',
      name: 'Forest Academy',
      wood: Color(0xFF5F4A2C),
      woodDeep: Color(0xFF2C2110),
      board: Color(0xFF27402F),
      boardDeep: Color(0xFF131F16),
      chalk: Color(0xFFF4F7EC),
      chalkSoft: Color(0xFFAEBBA4),
      accent: Color(0xFF9DBE5A),
      accentLight: Color(0xFFCDE39B),
      keyBg: Color(0xFF354F3C),
      keyBorder: Color(0xFF9DBE5A),
    ),
    ChalkThemeDef(
      id: 'terracotta',
      name: 'Terracotta Atelier',
      wood: Color(0xFF7C4A30),
      woodDeep: Color(0xFF3A2012),
      board: Color(0xFF453A34),
      boardDeep: Color(0xFF241C18),
      chalk: Color(0xFFFBF2E4),
      chalkSoft: Color(0xFFC6B6A2),
      accent: Color(0xFFD1704A),
      accentLight: Color(0xFFF0A983),
      keyBg: Color(0xFF544842),
      keyBorder: Color(0xFFD1704A),
    ),
    ChalkThemeDef(
      id: 'inkwell',
      name: 'Indigo Inkwell',
      wood: Color(0xFF54422E),
      woodDeep: Color(0xFF281E12),
      board: Color(0xFF2C2F4A),
      boardDeep: Color(0xFF151624),
      chalk: Color(0xFFF0F0FA),
      chalkSoft: Color(0xFFB0B2CC),
      accent: Color(0xFF8E9BD8),
      accentLight: Color(0xFFBEC6F0),
      keyBg: Color(0xFF3A3D5C),
      keyBorder: Color(0xFF8E9BD8),
    ),
    ChalkThemeDef(
      id: 'paper',
      name: 'Paper & Pencil',
      wood: Color(0xFF8A6A42),
      woodDeep: Color(0xFF42301A),
      board: Color(0xFFEFE6D2),
      boardDeep: Color(0xFFD8CBB0),
      chalk: Color(0xFF2E2620),
      chalkSoft: Color(0xFF7A6F5E),
      accent: Color(0xFFB3762A),
      accentLight: Color(0xFFD9A75C),
      keyBg: Color(0xFFF6EEDC),
      keyBorder: Color(0xFFB3762A),
    ),
    ChalkThemeDef(
      id: 'brick',
      name: 'Brick Schoolhouse',
      wood: Color(0xFF6E3B26),
      woodDeep: Color(0xFF341A0E),
      board: Color(0xFF3A3230),
      boardDeep: Color(0xFF1E1917),
      chalk: Color(0xFFF7F1E6),
      chalkSoft: Color(0xFFBDB2A4),
      accent: Color(0xFFC96F4A),
      accentLight: Color(0xFFF0A37F),
      keyBg: Color(0xFF4A413D),
      keyBorder: Color(0xFFC96F4A),
    ),
    ChalkThemeDef(
      id: 'walnut',
      name: 'Walnut Office',
      wood: Color(0xFF4E3524),
      woodDeep: Color(0xFF251710),
      board: Color(0xFF2F3B2E),
      boardDeep: Color(0xFF171E16),
      chalk: Color(0xFFF5F2E8),
      chalkSoft: Color(0xFFB3AE9E),
      accent: Color(0xFFB08D57),
      accentLight: Color(0xFFDCC08A),
      keyBg: Color(0xFF3D4A3B),
      keyBorder: Color(0xFFB08D57),
    ),
    ChalkThemeDef(
      id: 'seaglass',
      name: 'Sea Glass Desk',
      wood: Color(0xFF6A563E),
      woodDeep: Color(0xFF322818),
      board: Color(0xFF2B4140),
      boardDeep: Color(0xFF152021),
      chalk: Color(0xFFF2F7F2),
      chalkSoft: Color(0xFFA9BFB9),
      accent: Color(0xFF7FB8A4),
      accentLight: Color(0xFFB5DCCB),
      keyBg: Color(0xFF3A5150),
      keyBorder: Color(0xFF7FB8A4),
    ),
  ];

  static ChalkThemeDef byId(String id, {ChalkThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Number / tile styles for the question digits and the number pad.
/// 0-2 free; 3-8 PRO. All styles are classroom-appropriate.
class DigitStyles {
  static const names = [
    'Chalk Hand',
    'Slate Print',
    'Pencil Print',
    'Typewriter',
    'Marker Bold',
    'Wood Carve',
    'Brass Plaque',
    'Inkwell Serif',
    'Rounded Playful',
  ];

  static bool isPro(int i) => i >= 3;

  static TextStyle style(int i, ChalkThemeDef t, double size,
      {Color? color}) {
    final c = color ?? t.chalk;
    final base = TextStyle(
      color: c,
      fontSize: size,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.45),
          offset: const Offset(1.5, 2.5),
          blurRadius: 2,
        ),
      ],
    );
    switch (i) {
      case 0: // Chalk Hand
        return base.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        );
      case 1: // Slate Print
        return base.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 4,
        );
      case 2: // Pencil Print
        return base.copyWith(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          letterSpacing: 1,
        );
      case 3: // Typewriter
        return base.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['monospace'],
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        );
      case 4: // Marker Bold
        return base.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        );
      case 5: // Wood Carve
        return base.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 5,
          shadows: [
            Shadow(
              color: t.woodDeep.withValues(alpha: 0.9),
              offset: const Offset(2, 3),
              blurRadius: 0,
            ),
          ],
        );
      case 6: // Brass Plaque
        return base.copyWith(
          color: t.accentLight,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
        );
      case 7: // Inkwell Serif
        return base.copyWith(
          fontFamily: 'serif',
          fontFamilyFallback: const ['serif'],
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          letterSpacing: 2,
        );
      default: // Rounded Playful
        return base.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          height: 1.05,
        );
    }
  }
}
