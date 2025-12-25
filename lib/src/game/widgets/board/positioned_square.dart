import 'package:flutter/widgets.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Positions a child widget at a board position.
/// Inspired by Lichess PositionedSquare pattern.
class PositionedSquare extends StatelessWidget {
  const PositionedSquare({
    super.key,
    required this.boardSize,
    required this.position,
    required this.child,
  });

  /// Total board size (width = height)
  final double boardSize;

  /// Board position (row, col)
  final Position position;

  /// Widget to position
  final Widget child;

  double get squareSize => boardSize / 8;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.col * squareSize,
      // Flip Y-axis: engine row 0 at bottom, row 7 at top (chess convention)
      top: (7 - position.row) * squareSize,
      width: squareSize,
      height: squareSize,
      child: child,
    );
  }
}

