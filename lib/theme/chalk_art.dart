import 'package:flutter/material.dart';
import 'chalk_themes.dart';

/// Shared classroom art helpers: wood-framed chalkboard cards, chunky
/// physical buttons, and chalk text styles with realistic depth.
class Chalk {
  static TextStyle display(double size, {required ChalkThemeDef theme}) =>
      TextStyle(
        color: theme.chalk,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(2, 3),
            blurRadius: 3,
          ),
        ],
      );

  static TextStyle body(double size,
          {required ChalkThemeDef theme, Color? color}) =>
      TextStyle(
        color: color ?? theme.chalk,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle label(double size,
          {required ChalkThemeDef theme, Color? color}) =>
      TextStyle(
        color: color ?? theme.accentLight,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      );
}

/// Warm wooden backdrop behind everything (subtle vignette, no gradients
/// overload — a soft radial light over the deep wood tone).
class ChalkBackdrop extends StatelessWidget {
  final ChalkThemeDef theme;
  final Widget child;
  const ChalkBackdrop({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.woodDeep,
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.4,
          colors: [
            theme.wood.withValues(alpha: 0.55),
            theme.woodDeep,
          ],
        ),
      ),
      child: child,
    );
  }
}

/// A chalkboard panel with a wooden frame — the core "physical" card.
class BoardCard extends StatelessWidget {
  final ChalkThemeDef theme;
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  const BoardCard({
    required this.theme,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.wood, theme.woodDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.board, theme.boardDeep],
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (title != null) ...[
              Text(title!, style: Chalk.display(20, theme: theme)),
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                height: 3,
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: theme.accent.withValues(alpha: 0.8),
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Chunky physical button with press feedback.
class ChalkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final ChalkThemeDef theme;
  final double width;
  final double fontSize;
  const ChalkButton({
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 260,
    this.fontSize = 19,
  });

  @override
  State<ChalkButton> createState() => _ChalkButtonState();
}

class _ChalkButtonState extends State<ChalkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _pressed
                ? [t.accent.withValues(alpha: 0.75), t.accent]
                : [t.accentLight, t.accent],
          ),
          border: Border.all(color: t.woodDeep, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: Offset(0, _pressed ? 1 : 5),
              blurRadius: _pressed ? 3 : 9,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Chalk.label(widget.fontSize,
              theme: t, color: t.woodDeep),
        ),
      ),
    );
  }
}

/// Selectable chip (modes, difficulties, styles).
class ChalkChip extends StatelessWidget {
  final ChalkThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChalkChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? theme.accent.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.45),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Chalk.label(13,
              theme: theme,
              color: selected ? theme.woodDeep : theme.chalk),
        ),
      ),
    );
  }
}
