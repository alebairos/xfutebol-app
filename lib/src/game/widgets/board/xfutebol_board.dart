import 'package:flutter/material.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'background_painter.dart';
import 'board_geometry.dart';
import 'board_settings.dart';
import 'positioned_square.dart';
import '../highlight/highlights.dart';
import '../piece/piece_widget.dart';

/// The main game board widget.
/// 
/// Displays an 8x8 soccer field with pieces, highlights, and ball.
/// Inspired by Lichess Chessboard pattern - uses Stack-based composition.
/// 
/// Game elements:
/// - 14 pieces (7 white + 7 black): GK, DF×2, MF×2, FW×2 per team
/// - 1 ball (either held by a piece or loose on the field)
class XfutebolBoard extends StatelessWidget with BoardGeometry {
  const XfutebolBoard({
    super.key,
    required this.size,
    required this.board,
    this.settings = const BoardSettings(),
    this.selectedPieceId,
    this.validMoves = const [],
    this.lastMoveFrom,
    this.lastMoveTo,
    this.onSquareTap,
    this.onPieceTap,
  });

  /// Visual size of the board (width = height)
  @override
  final double size;

  /// Current board state from the engine
  final BoardView board;

  /// Board appearance settings
  final BoardSettings settings;

  /// ID of currently selected piece (null if none)
  final String? selectedPieceId;

  /// Valid move destinations for selected piece
  final List<Position> validMoves;

  /// Last move start position (for highlight)
  final Position? lastMoveFrom;

  /// Last move end position (for highlight)
  final Position? lastMoveTo;

  /// Called when a square is tapped
  final void Function(Position)? onSquareTap;

  /// Called when a piece is tapped
  final void Function(PieceView)? onPieceTap;

  @override
  Widget build(BuildContext context) {
    final colors = settings.colorScheme;

    return Listener(
      onPointerDown: (event) {
        final pos = offsetToPosition(event.localPosition);
        if (pos != null && onSquareTap != null) {
          onSquareTap!(pos);
        }
      },
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            // Layer 1: Background (isolated - rarely changes)
            RepaintBoundary(
              child: CustomPaint(
                size: Size.square(size),
                painter: FieldBackgroundPainter(
                  colorScheme: colors,
                  showCoordinates: settings.showCoordinates,
                ),
              ),
            ),

            // Layer 2: Highlights (isolated - changes on selection)
            RepaintBoundary(
              child: Stack(
                children: _buildHighlights(colors),
              ),
            ),

            // Layer 3: Pieces
            ..._buildPieces(),

            // Layer 4: Loose ball (if not held by any piece)
            if (_looseBallPosition != null)
              PositionedSquare(
                key: const ValueKey('loose-ball'),
                boardSize: size,
                position: _looseBallPosition!,
                child: Center(
                  child: _LooseBall(size: squareSize * 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build highlight widgets for selection, last move, and valid moves
  List<Widget> _buildHighlights(BoardColorScheme colors) {
    final highlights = <Widget>[];

    // Last move highlights
    if (settings.showLastMove) {
      if (lastMoveFrom != null) {
        highlights.add(
          PositionedSquare(
            key: ValueKey('last-from-${lastMoveFrom!.row}-${lastMoveFrom!.col}'),
            boardSize: size,
            position: lastMoveFrom!,
            child: SquareHighlight(color: colors.lastMove),
          ),
        );
      }
      if (lastMoveTo != null) {
        highlights.add(
          PositionedSquare(
            key: ValueKey('last-to-${lastMoveTo!.row}-${lastMoveTo!.col}'),
            boardSize: size,
            position: lastMoveTo!,
            child: SquareHighlight(color: colors.lastMove),
          ),
        );
      }
    }

    // Selected piece highlight
    if (selectedPieceId != null) {
      final selectedPiece = board.pieces.where((p) => p.id == selectedPieceId).firstOrNull;
      if (selectedPiece != null) {
        highlights.add(
          PositionedSquare(
            key: ValueKey('selected-${selectedPiece.position.row}-${selectedPiece.position.col}'),
            boardSize: size,
            position: selectedPiece.position,
            child: SquareHighlight(color: colors.selected),
          ),
        );
      }
    }

    // Valid move highlights (deduplicate positions to avoid duplicate keys)
    if (settings.showValidMoves && validMoves.isNotEmpty) {
      final seenPositions = <String>{};
      for (final move in validMoves) {
        final posKey = '${move.row}-${move.col}';
        if (seenPositions.contains(posKey)) continue;
        seenPositions.add(posKey);

        final isOccupied = board.pieces.any(
          (p) => p.position.row == move.row && p.position.col == move.col,
        );

        highlights.add(
          PositionedSquare(
            key: ValueKey('valid-$posKey'),
            boardSize: size,
            position: move,
            child: isOccupied
                ? OccupiedMoveHighlight(size: squareSize, color: colors.validMovesOccupied)
                : ValidMoveHighlight(size: squareSize, color: colors.validMoves),
          ),
        );
      }
    }

    return highlights;
  }

  /// Build piece widgets for all pieces on the board
  List<Widget> _buildPieces() {
    return board.pieces.map((piece) {
      return PositionedSquare(
        key: ValueKey('piece-${piece.id}'),
        boardSize: size,
        position: piece.position,
        child: GestureDetector(
          onTap: onPieceTap != null ? () => onPieceTap!(piece) : null,
          child: PieceWidget(
            piece: piece,
            size: squareSize,
            pieceAssets: settings.pieceSet.assets,
          ),
        ),
      );
    }).toList();
  }

  /// Returns ball position if ball is loose (not held by any piece)
  Position? get _looseBallPosition {
    // If any piece has the ball, it's not loose
    if (board.pieces.any((p) => p.hasBall)) return null;
    // Otherwise return the board's ball position
    return board.ballPosition;
  }
}

/// Loose ball widget (when ball is not held by any piece)
class _LooseBall extends StatelessWidget {
  const _LooseBall({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black87,
          width: size * 0.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102), // 0.4 * 255 ≈ 102
            blurRadius: size * 0.3,
            offset: Offset(size * 0.1, size * 0.15),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SoccerBallPatternPainter(),
      ),
    );
  }
}

/// Simple soccer ball pentagon pattern
class _SoccerBallPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // Simple center pentagon
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

