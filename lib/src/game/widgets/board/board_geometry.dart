import 'package:flutter/widgets.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Mixin providing board geometry calculations.
/// Inspired by Lichess chessground's geometry.dart
mixin BoardGeometry {
  /// Visual size of the board (width = height)
  double get size;

  /// Size of a single square
  double get squareSize => size / 8;

  /// Convert a board position to screen offset
  Offset positionToOffset(Position pos) {
    return Offset(pos.col * squareSize, pos.row * squareSize);
  }

  /// Convert a screen offset to board position
  /// Returns null if outside the board
  Position? offsetToPosition(Offset offset) {
    final col = (offset.dx / squareSize).floor();
    final row = (offset.dy / squareSize).floor();
    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      return Position(row: row, col: col);
    }
    return null;
  }
}

