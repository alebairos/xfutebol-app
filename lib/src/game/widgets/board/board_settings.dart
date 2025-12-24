import 'package:flutter/widgets.dart';
import '../piece/piece_set.dart';

/// Immutable settings for the game board.
/// Inspired by Lichess ChessboardSettings.
@immutable
class BoardSettings {
  const BoardSettings({
    this.colorScheme = const BoardColorScheme.soccerGreen(),
    this.pieceSet = PieceSet.simple,
    this.animationDuration = const Duration(milliseconds: 200),
    this.showValidMoves = true,
    this.showLastMove = true,
    this.showCoordinates = false,
  });

  /// Color scheme for the board
  final BoardColorScheme colorScheme;

  /// Piece set to use for rendering
  final PieceSet pieceSet;

  /// Duration for piece movement animations
  final Duration animationDuration;

  /// Whether to show valid move indicators
  final bool showValidMoves;

  /// Whether to highlight the last move
  final bool showLastMove;

  /// Whether to show row/col coordinates
  final bool showCoordinates;

  BoardSettings copyWith({
    BoardColorScheme? colorScheme,
    PieceSet? pieceSet,
    Duration? animationDuration,
    bool? showValidMoves,
    bool? showLastMove,
    bool? showCoordinates,
  }) {
    return BoardSettings(
      colorScheme: colorScheme ?? this.colorScheme,
      pieceSet: pieceSet ?? this.pieceSet,
      animationDuration: animationDuration ?? this.animationDuration,
      showValidMoves: showValidMoves ?? this.showValidMoves,
      showLastMove: showLastMove ?? this.showLastMove,
      showCoordinates: showCoordinates ?? this.showCoordinates,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardSettings &&
        other.colorScheme == colorScheme &&
        other.pieceSet == pieceSet &&
        other.animationDuration == animationDuration &&
        other.showValidMoves == showValidMoves &&
        other.showLastMove == showLastMove &&
        other.showCoordinates == showCoordinates;
  }

  @override
  int get hashCode => Object.hash(
        colorScheme,
        pieceSet,
        animationDuration,
        showValidMoves,
        showLastMove,
        showCoordinates,
      );
}

/// Color scheme for the soccer board.
/// Inspired by Lichess ChessboardColorScheme.
@immutable
class BoardColorScheme {
  const BoardColorScheme({
    required this.lightSquare,
    required this.darkSquare,
    required this.goalArea,
    required this.fieldLines,
    required this.lastMove,
    required this.selected,
    required this.validMoves,
    required this.validMovesOccupied,
  });

  /// Light square color (lighter grass)
  final Color lightSquare;

  /// Dark square color (darker grass)
  final Color darkSquare;

  /// Goal area overlay color
  final Color goalArea;

  /// Field lines color (center line, center circle)
  final Color fieldLines;

  /// Last move highlight color
  final Color lastMove;

  /// Selected piece highlight color
  final Color selected;

  /// Valid move indicator color (empty squares)
  final Color validMoves;

  /// Valid move indicator color (occupied squares - captures)
  final Color validMovesOccupied;

  /// Default soccer field green theme
  const BoardColorScheme.soccerGreen()
      : lightSquare = const Color(0xFF7CB342), // Light grass green
        darkSquare = const Color(0xFF558B2F), // Dark grass green
        goalArea = const Color(0x30FFFFFF), // White overlay
        fieldLines = const Color(0x50FFFFFF), // White lines
        lastMove = const Color(0x809CC700), // Yellow-green
        selected = const Color(0x80FFD54F), // Gold
        validMoves = const Color(0x40000000), // Dark dots
        validMovesOccupied = const Color(0x40E53935); // Red ring for captures

  /// Alternative blue theme (for variety)
  const BoardColorScheme.iceBlue()
      : lightSquare = const Color(0xFFB3E5FC),
        darkSquare = const Color(0xFF4FC3F7),
        goalArea = const Color(0x30FFFFFF),
        fieldLines = const Color(0x50FFFFFF),
        lastMove = const Color(0x8064B5F6),
        selected = const Color(0x80FFF176),
        validMoves = const Color(0x40000000),
        validMovesOccupied = const Color(0x40E53935);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardColorScheme &&
        other.lightSquare == lightSquare &&
        other.darkSquare == darkSquare &&
        other.goalArea == goalArea &&
        other.fieldLines == fieldLines &&
        other.lastMove == lastMove &&
        other.selected == selected &&
        other.validMoves == validMoves &&
        other.validMovesOccupied == validMovesOccupied;
  }

  @override
  int get hashCode => Object.hash(
        lightSquare,
        darkSquare,
        goalArea,
        fieldLines,
        lastMove,
        selected,
        validMoves,
        validMovesOccupied,
      );
}

