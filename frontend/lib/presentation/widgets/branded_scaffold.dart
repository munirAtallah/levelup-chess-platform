import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Platform-wide ambient background.
///
/// Paints the base app colour plus a set of large, very faint chess pieces
/// that drift slowly behind ALL content. Injected once at the
/// `MaterialApp.builder` level so every route inherits it. For the pieces to
/// show, page [Scaffold]s are kept transparent (see AppTheme +
/// per-screen `backgroundColor: Colors.transparent`).
class BrandedBackground extends StatelessWidget {
  final Widget child;

  /// Master opacity of the whole chess layer. Design default ~0.07.
  static const double pieceOpacity = 0.07;

  /// Set false for a completely static (cheaper) background.
  static const bool animate = true;

  const BrandedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.background)),
        const Positioned.fill(
          child: IgnorePointer(child: _ChessField()),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Piece {
  final String glyph;
  final double topFrac;
  final double leftFrac;
  final double size;
  final Color color;
  final double phase;
  final double ampX;
  final double ampY;
  const _Piece(this.glyph, this.topFrac, this.leftFrac, this.size, this.color,
      this.phase, this.ampX, this.ampY);
}

class _ChessField extends StatefulWidget {
  const _ChessField();

  @override
  State<_ChessField> createState() => _ChessFieldState();
}

class _ChessFieldState extends State<_ChessField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _p = AppColors.primary;
  static const _g = AppColors.primary;

  static const List<_Piece> _pieces = [
    _Piece('♞', 0.07, 0.05, 150, _p, 0.00, 16, 30),
    _Piece('♛', 0.15, 0.78, 185, _g, 0.55, 14, 26),
    _Piece('♟', 0.60, 0.11, 120, _p, 0.20, 16, 20),
    _Piece('♜', 0.68, 0.83, 160, _p, 0.80, 18, 28),
    _Piece('♕', 0.40, 0.46, 115, _g, 0.35, 16, 22),
    _Piece('♚', 0.86, 0.38, 135, _p, 0.10, 16, 24),
    _Piece('♘', 0.28, 0.23, 95, _g, 0.65, 12, 20),
    _Piece('♕', 0.48, 0.90, 120, _p, 0.90, 16, 22),
    _Piece('♙', 0.82, 0.65, 90, _g, 0.45, 14, 18),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    if (BrandedBackground.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final p in _pieces)
                  Positioned(
                    left: p.leftFrac * w +
                        (BrandedBackground.animate
                            ? p.ampX * math.sin(2 * math.pi * (t + p.phase))
                            : 0.0),
                    top: p.topFrac * h +
                        (BrandedBackground.animate
                            ? p.ampY *
                                math.sin(2 * math.pi * (t + p.phase) + p.phase)
                            : 0.0),
                    child: Transform.rotate(
                      angle: BrandedBackground.animate
                          ? 0.12 * math.sin(2 * math.pi * (t + p.phase))
                          : 0.0,
                      child: Text(
                        p.glyph,
                        style: TextStyle(
                          fontSize: p.size,
                          height: 1,
                          color: p.color
                              .withValues(alpha: BrandedBackground.pieceOpacity),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
