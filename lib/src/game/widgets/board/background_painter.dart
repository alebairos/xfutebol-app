import 'package:flutter/material.dart';
import 'board_settings.dart';

/// CustomPainter for the soccer field background.
/// Draws the 8x8 grid with alternating colors, goal areas, and field lines.
/// Inspired by Lichess SolidColorChessboardPainter.
class FieldBackgroundPainter extends CustomPainter {
  const FieldBackgroundPainter({
    required this.colorScheme,
    this.showCoordinates = false,
  });

  final BoardColorScheme colorScheme;
  final bool showCoordinates;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;

    // Draw alternating grass squares
    _drawSquares(canvas, size, squareSize);

    // Draw goal areas
    _drawGoalAreas(canvas, size, squareSize);

    // Draw field markings
    _drawFieldLines(canvas, size, squareSize);

    // Draw coordinates if enabled
    if (showCoordinates) {
      _drawCoordinates(canvas, size, squareSize);
    }
  }

  void _drawSquares(Canvas canvas, Size size, double squareSize) {
    final lightPaint = Paint()..color = colorScheme.lightSquare;
    final darkPaint = Paint()..color = colorScheme.darkSquare;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );
        canvas.drawRect(rect, isLight ? lightPaint : darkPaint);
      }
    }
  }

  void _drawGoalAreas(Canvas canvas, Size size, double squareSize) {
    final goalPaint = Paint()..color = colorScheme.goalArea;

    // Top goal area (row 0, cols 2-5)
    for (int col = 2; col <= 5; col++) {
      final rect = Rect.fromLTWH(
        col * squareSize,
        0,
        squareSize,
        squareSize,
      );
      canvas.drawRect(rect, goalPaint);
    }

    // Bottom goal area (row 7, cols 2-5)
    for (int col = 2; col <= 5; col++) {
      final rect = Rect.fromLTWH(
        col * squareSize,
        7 * squareSize,
        squareSize,
        squareSize,
      );
      canvas.drawRect(rect, goalPaint);
    }
  }

  void _drawFieldLines(Canvas canvas, Size size, double squareSize) {
    final linePaint = Paint()
      ..color = colorScheme.fieldLines
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Center line (horizontal at row 4)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Center circle
    final centerRadius = squareSize * 1.2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      centerRadius,
      linePaint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = colorScheme.fieldLines
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      squareSize * 0.1,
      dotPaint,
    );

    // Goal area outlines (penalty boxes)
    _drawGoalAreaOutline(canvas, squareSize, linePaint, isTop: true);
    _drawGoalAreaOutline(canvas, squareSize, linePaint, isTop: false);
  }

  void _drawGoalAreaOutline(
    Canvas canvas,
    double squareSize,
    Paint paint, {
    required bool isTop,
  }) {
    final y = isTop ? 0.0 : 7 * squareSize;
    final height = squareSize;

    // Goal box outline
    final rect = Rect.fromLTWH(
      2 * squareSize,
      y,
      4 * squareSize,
      height,
    );

    final path = Path();
    if (isTop) {
      // Draw U shape opening downward
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.left, rect.bottom);
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.right, rect.top);
    } else {
      // Draw U shape opening upward
      path.moveTo(rect.left, rect.bottom);
      path.lineTo(rect.left, rect.top);
      path.lineTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.bottom);
    }
    canvas.drawPath(path, paint);
  }

  void _drawCoordinates(Canvas canvas, Size size, double squareSize) {
    final textStyle = TextStyle(
      color: colorScheme.fieldLines,
      fontSize: squareSize * 0.2,
      fontWeight: FontWeight.bold,
    );

    // Row numbers (1-8 from bottom to top)
    for (int row = 0; row < 8; row++) {
      final textPainter = TextPainter(
        text: TextSpan(text: '${8 - row}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          squareSize * 0.05,
          row * squareSize + squareSize * 0.05,
        ),
      );
    }

    // Column letters (a-h from left to right)
    for (int col = 0; col < 8; col++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode('a'.codeUnitAt(0) + col),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          col * squareSize + squareSize - textPainter.width - squareSize * 0.05,
          size.height - textPainter.height - squareSize * 0.05,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FieldBackgroundPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.showCoordinates != showCoordinates;
  }
}

