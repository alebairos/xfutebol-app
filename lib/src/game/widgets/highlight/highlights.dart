import 'package:flutter/material.dart';

/// Simple square highlight for selection and last move.
/// Inspired by Lichess SquareHighlight.
class SquareHighlight extends StatelessWidget {
  const SquareHighlight({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(color: color);
  }
}

/// Valid move highlight - shows a dot for empty squares.
/// Inspired by Lichess ValidMoveHighlight.
class ValidMoveHighlight extends StatelessWidget {
  const ValidMoveHighlight({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Container(
          width: size * 0.35,
          height: size * 0.35,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Valid move highlight for occupied squares (captures).
/// Shows a ring around the target piece.
class OccupiedMoveHighlight extends StatelessWidget {
  const OccupiedMoveHighlight({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(color: color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.42,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => color != oldDelegate.color;
}

/// Path highlight for showing pass/shoot trajectories.
/// Draws a line through multiple positions.
class PathHighlight extends StatelessWidget {
  const PathHighlight({
    super.key,
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(color: color.withAlpha(77)); // 0.3 * 255 ≈ 77
  }
}

